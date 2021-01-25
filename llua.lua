local BinaryChunk = require("runtime/binarychunk/binarychunk")
local LuaState = require("runtime/state/state")
local Instruction = require("runtime/vm/instruction")
local OPCODE = require("runtime/vm/opcode")
local Util = require("common/util")


LLUA = {}


function LLUA:main()
    if #arg < 1 then
        Util:panic("[LLUA ERROR] Running LLUA require a bytecode file")
    end
    local fd = io.open(arg[1], "rb")
    local data = fd:read("*all")
    fd:close()
    local proto = BinaryChunk:Undump(data)
    self:luaMain(proto)
end

function LLUA:luaMain(proto)
    local nRegs = proto.MaxStackSize
    local ls = LuaState:new(nRegs + 8, proto)
    ls:SetTop(nRegs)
    while true do
        local pc = ls:PC()
        local inst = Instruction:new(ls:Fetch())
        if inst:Opcode() + 1 ~= OPCODE.OP_RETURN then
            inst:Execute(ls)
            Util:printf("[%02d] %s", pc, inst:OpName())
            ls:printStack()
        else
            break
        end
    end
    
end


LLUA:main()
