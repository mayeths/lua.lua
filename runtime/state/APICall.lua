local LuaState = require("runtime/state/luastate")
local LuaStack = require("runtime/state/luastack")
local BinaryChunk = require("runtime/binarychunk/binarychunk")
local LuaClosure = require("runtime/state/luaclosure")
local Instruction = require("runtime/vm/instruction")
local OPCODE = require("runtime/vm/opcode")
local Util = require("common/util")

function LuaState:Load(chunk, name, mode)
    local proto = BinaryChunk:Undump(chunk)
    local closure = LuaClosure:new(proto)
    self.stack:push(closure)
end

function LuaState:Call(nRealParams, nRealResults)
    local closure = self.stack:get(-(nRealParams + 1))
    if not LuaClosure:isClosure(closure) then
        Util:panic("[LuaState:Call ERROR] not a function")
    end
    local proto = closure.proto
    Util:printf("calling %s<%d,%d>\n", proto.Source,
        proto.LineDefined, proto.LastLineDefined)
    local nreg = proto.MaxStackSize
    local nDefinedparams = proto.NumParams
    local isVararg = proto.IsVararg == 1
    local newStack = LuaStack:new(nreg + 20)
    newStack.closure = closure
    local realParams = self.stack:popN(nRealParams)
    local func = self.stack:pop()
    newStack:pushN(realParams, nDefinedparams)
    newStack:settop(nreg)
    if nRealParams >= nDefinedparams and isVararg then
        local varargParams = {}
        for i = nDefinedparams + 1, #realParams do
            varargParams[#varargParams + 1] = realParams[i]
        end
        newStack.varargs = varargParams
    end

    self:pushLuaStack(newStack)
    self:runClosure()
    self:popLuaStack()

    if nRealResults ~= 0 then
        local result = newStack:popN(newStack:gettop() - nreg)
        self.stack:ensure(#result)
        self.stack:pushN(result, nRealResults)
    end
end


function LuaState:runClosure()
    while true do
        local inst = Instruction:new(self:Fetch())
        inst:Execute(self)
        if inst:Opcode() + 1 == OPCODE.OP_RETURN then
            break
        end
    end
end

