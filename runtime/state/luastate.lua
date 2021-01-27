local LuaStack = require("runtime/state/luastack")
local LuaClosure = require("runtime/state/luaclosure")
local Operation = require("runtime/constrant/operation")
local BinaryChunk = require("runtime/binarychunk/binarychunk")
local Type = require("runtime/constrant/type")
local Convert = require("runtime/type/convert")
local Logical = require("runtime/operation/logical")
local Instruction = require("runtime/vm/instruction")
local OPCODE = require("runtime/vm/opcode")
local Util = require("common/util")

local LuaState = {
    stack = nil,
}


function LuaState:new()
    LuaState.__index = LuaState
    self = setmetatable({}, LuaState)
    self.stack = LuaStack:new(20)
    return self
end


function LuaState:GetTop()
    return self.stack:gettop()
end


function LuaState:AbsIndex(idx)
    return self.stack:absIndex(idx)
end


function LuaState:CheckStack(freenum)
    self.stack:ensure(freenum)
    return true
end


function LuaState:Pop(n)
    for _ = 1, n do
        self.stack:pop()
    end
end


function LuaState:Copy(fromIdx, toIdx)
    local val = self.stack:get(fromIdx)
    self.stack:set(toIdx, val)
end


function LuaState:PushValue(idx)
    local val = self.stack:get(idx)
    self.stack:push(val)
end


function LuaState:Replace(idx)
    local val = self.stack:pop()
    self.stack:set(idx, val)
end


function LuaState:Insert(idx)
    self:Rotate(idx, 1)
end


function LuaState:Remove(idx)
    self:Rotate(idx, -1)
    self:Pop(1)
end

-- What does lua_rotate do?
-- https://stackoverflow.com/a/52241763
function LuaState:Rotate(idx, n)
    local t3 = self:GetTop()
    local t1 = self:AbsIndex(idx)
    local t2
    if n >= 0 then
        t2 = t3 - n
    else
        t2 = t1 - n - 1
    end
    self.stack:reverse(t1, t2)
    self.stack:reverse(t2 + 1, t3)
    self.stack:reverse(t1, t3)
end


function LuaState:SetTop(idx)
    local newTop = self:AbsIndex(idx)
    if newTop < 0 then
        Util:panic("[LuaState:SetTop ERROR] Stack underflow!")
    end
    local operateSlotNum = newTop - self:GetTop()
    if operateSlotNum < 0 then
        for _ = 1, -operateSlotNum do
            self.stack:pop()
        end
    elseif operateSlotNum > 0 then
        for _ = 1, operateSlotNum do
            self.stack:push(nil)
        end
    end
end


local Fn = {
    iadd  = function (a, b) return a + b end,
    fadd  = function (a, b) return a + b end,
    isub  = function (a, b) return a - b end,
    fsub  = function (a, b) return a - b end,
    imul  = function (a, b) return a * b end,
    fmul  = function (a, b) return a * b end,
    imod  = function (a, b) return a % b end,
    fmod  = function (a, b) return a % b end,
    pow   = function (a, b) return a ^ b end,
    div   = function (a, b) return a / b end,
    iidiv = function (a, b) return a // b end,
    fidiv = function (a, b) return a // b end,
    band  = function (a, b) return a & b end,
    bor   = function (a, b) return a | b end,
    bxor  = function (a, b) return a ~ b end,
    shl   = function (a, b) return Logical:shiftleft(a, b) end,
    shr   = function (a, b) return Logical:shiftright(a, b) end,
    iunm  = function (a, _) return -a end,
    funm  = function (a, _) return -a end,
    bnot  = function (a, _) return ~a end,
}


local Operators = {
    {Fn.iadd,  Fn.fadd },
    {Fn.isub,  Fn.fsub },
    {Fn.imul,  Fn.fmul },
    {Fn.imod,  Fn.fmod },
    {nil,      Fn.pow  },
    {nil,      Fn.div  },
    {Fn.iidiv, Fn.fidiv},
    {Fn.band,  nil     },
    {Fn.bor,   nil     },
    {Fn.bxor,  nil     },
    {Fn.shl,   nil     },
    {Fn.shr,   nil     },
    {Fn.iunm,  Fn.funm },
    {Fn.bnot,  nil     },
}


-- http://www.lua.org/manual/5.3/manual.html#lua_arith
function LuaState:Arith(opid)
    local a, b
    b = self.stack:pop()
    local isOPUNM = opid == Operation.LUA_OPUNM
    local isOPBNOT = opid == Operation.LUA_OPBNOT
    if isOPUNM or isOPBNOT then
        a = b
    else
        a = self.stack:pop()
    end

    local op = Operators[opid + 1]
    local isBitwise = op[2] == nil
    local tryIntFnFirst = op[1] ~= nil
    if isBitwise then
        local x, ok1 = Convert:any2int(a)
        local y, ok2 = Convert:any2int(b)
        if ok1 and ok2 then
            local result = op[1](x, y)
            self.stack:push(result)
            return
        end
        Util:panic("[LuaState:Arith ERROR] Can not perform bitwise op!")
    else
        if tryIntFnFirst then
            local x, ok1 = Convert:any2int(a)
            local y, ok2 = Convert:any2int(b)
            if ok1 and ok2 then
                local result = op[1](x, y)
                self.stack:push(result)
                return
            end
        end
        local x, ok1 = Convert:any2float(a)
        local y, ok2 = Convert:any2float(b)
        if ok1 and ok2 then
            local result = op[2](x, y)
            self.stack:push(result)
            return
        end
        Util:panic("[LuaState:Arith ERROR] Can not perform any op!")
    end
end


function LuaState:Compare(idx1, idx2, opid)
    local idx1valid = self.stack:isValid(idx1)
    local idx2valid = self.stack:isValid(idx2)
    if not idx1valid or not idx2valid then
        return false
    end

    local a = self.stack:get(idx1)
    local b = self.stack:get(idx2)
    if opid == Operation.LUA_OPEQ then
        return a == b
    elseif opid == Operation.LUA_OPLT then
        return a < b
    elseif opid == Operation.LUA_OPLE then
        return a <= b
    else
        Util:panic("[LuaState:Compare ERROR] Invalid compare op!")
    end
end


function LuaState:Len(idx)
    local val = self.stack:get(idx)
    if type(val) == "table" then
        self.stack:push(#val.table)
    else
        self.stack:push(#val)
    end
end


function LuaState:Concat(n)
    if n == 0 then
        self.stack.push("")
    elseif n == 1 then
        return
    end
    for _ = 1, n - 1 do
        if self:IsString(-1) and self:IsString(-2) then
            local s2 = self:ToString(-1)
            local s1 = self:ToString(-2)
            self.stack:pop()
            self.stack:pop()
            self.stack:push(s1..s2)
        else
            Util:panic("[LuaState:Concat ERROR] Concatenation error!")
        end
    end
end


function LuaState:PushNil()
    self.stack:push(nil)
end


function LuaState:PushBoolean(b)
    Util:assert(type(b), "boolean",
        "Pushing a non-boolean value by PushBoolean method"
    )
    self.stack:push(b)
end


function LuaState:PushInteger(n)
    Util:assert(math.type(n), "integer",
        "Pushing a non-integer value by PushInteger method"
    )
    self.stack:push(n)
end


function LuaState:PushNumber(n)
    self.stack:push(n)
end


function LuaState:PushString(s)
    self.stack:push(s)
end


function LuaState:TypeName(tid)
    if tid == Type.LUA_TNONE then
        return "no value"
    elseif tid == Type.LUA_TNIL then
        return "nil"
    elseif tid == Type.LUA_TBOOLEAN then
        return "boolean"
    elseif tid == Type.LUA_TNUMBER then
        return "number"
    elseif tid == Type.LUA_TSTRING then
        return "string"
    elseif tid == Type.LUA_TTABLE then
        return "table"
    elseif tid == Type.LUA_TFUNCTION then
        return "function"
    elseif tid == Type.LUA_TTHREAD then
        return "thread"
    else
        return "userdata"
    end
end


function LuaState:Type(idx)
    if not self.stack:isValid(idx) then
        return Type.LUA_TNONE
    end
    local val = self.stack:get(idx)
    local valtype = type(val)
    if valtype == "nil" then
        return Type.LUA_TNIL
    elseif valtype == "boolean" then
        return Type.LUA_TBOOLEAN
    elseif valtype == "number" then
        return Type.LUA_TNUMBER
    elseif valtype == "string" then
        return Type.LUA_TSTRING
    elseif valtype == "table" then
        if type(val.table) == "table" then
            return Type.LUA_TTABLE
        elseif type(val.proto) == "table" then
            return Type.LUA_TFUNCTION
        else
            Util:panic("[LuaState:Type ERROR] Unknown table!")
        end
    else
        Util:panic("[LuaState:Type ERROR] Unknown type!")
    end
end


function LuaState:IsNone(idx)
    return self:Type(idx) == Type.LUA_TNONE
end


function LuaState:IsNil(idx)
    return self:Type(idx) == Type.LUA_TNIL
end


function LuaState:IsNoneOrNil(idx)
    return self:Type(idx) <= Type.LUA_TNIL
end


function LuaState:IsBoolean(idx)
    return self:Type(idx) == Type.LUA_TBOOLEAN
end


function LuaState:IsTable(idx)
    return self:Type(idx) == Type.LUA_TTABLE
end


function LuaState:IsFunction(idx)
    return self:Type(idx) == Type.LUA_TFUNCTION
end


function LuaState:IsThread(idx)
    return self:Type(idx) == Type.LUA_TTHREAD
end


function LuaState:IsString(idx)
    local t = self:Type(idx)
    return t == Type.LUA_TSTRING or t == Type.LUA_TNUMBER
end


function LuaState:IsNumber(idx)
    local val = self.stack:get(idx)
    return math.type(val) ~= nil
end


function LuaState:IsInteger(idx)
    local val = self.stack:get(idx)
    return math.type(val) == "integer"
end


function LuaState:ToBoolean(idx)
    local t = self:Type(idx)
    if t == Type.LUA_TNIL then
        return false
    elseif t == Type.LUA_TBOOLEAN then
        return self.stack:get(idx)
    else
        return true
    end
end


function LuaState:ToInteger(idx)
    local i, _ = self:ToIntegerX(idx)
    return i
end


function LuaState:ToIntegerX(idx)
    local val = self.stack:get(idx)
    local mtype = math.type(val)
    if mtype == "integer" then
        return val, true
    elseif mtype == "float" then
        return math.tointeger(val), true
    else
        return 0, false
    end
end


function LuaState:ToNumber(idx)
    local n, _ = self:ToNumberX(idx)
    return n
end


function LuaState:ToNumberX(idx)
    local val = self.stack:get(idx)
    local mtype = math.type(val)
    if mtype ~= nil then
        return val+0.0, true
    else
        return 0, false
    end
end


function LuaState:ToString(idx)
    local s, _ = self:ToStringX(idx)
    return s
end


function LuaState:ToStringX(idx)
    local val = self.stack:get(idx)
    local t = type(val)
    if t == "string" then
        return val, true
    elseif t == "number" then
        return tostring(val), true
    else
        return "", false
    end
end


function LuaState:PC()
    return self.stack.pc
end


function LuaState:AddPC(n)
    self.stack.pc = self.stack.pc + n
end


function LuaState:Fetch()
    self.stack.pc = self.stack.pc + 1
    local i = self.stack.closure.proto.Code[self.stack.pc]
    return i
end


function LuaState:GetConst(idx)
    local c = self.stack.closure.proto.Constants[idx + 1]
    self.stack:push(c)
end


function LuaState:GetRK(rk)
    if rk > 0xFF then
        self:GetConst(rk & 0xFF)
    else
        self:PushValue(rk + 1)
    end
end


function LuaState:RegisterCount()
    return self.stack.closure.proto.MaxStackSize
end


function LuaState:LoadVararg(n)
    if n < 0 then
        n = #self.stack.varargs
    end
    self.stack:ensure(n)
    self.stack:pushN(self.stack.varargs, n)
end


function LuaState:LoadProto(idx)
    local proto = self.stack.closure.proto.Protos[idx]
    local closure = LuaClosure:new(proto)
    self.stack:push(closure)
end


function LuaState:NewTable()
    self:CreateTable(0, 0)
end


function LuaState:CreateTable(nArr, nRec)
    local t = { table = {}}
    self.stack:push(t)
end

function LuaState:GetTable(idx)
    local t = self.stack:get(idx)
    local k = self.stack:pop()
    self.stack:push(t.table[k])
    return type(t.table[k])
end


function LuaState:GetFeild(idx, k)
    local t = self.stack:get(idx)
    self.stack:push(t.table[k])
    return type(t.table[k])
end


function LuaState:GetI(idx, i)
    local t = self.stack:get(idx)
    self.stack:push(t.table[i])
    return type(t.table[i])
end


function LuaState:SetTable(idx)
    local t = self.stack:get(idx)
    local v = self.stack:pop()
    local k = self.stack:pop()
    t.table[k] = v
end


function LuaState:SetField(idx, k)
    local t = self.stack:get(idx)
    local v = self.stack:pop()
    t.table[k] = v
end


function LuaState:SetI(idx, i)
    local t = self.stack:get(idx)
    local v = self.stack:pop()
    t.table[i] = v
end


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
        self:printStack()
        if inst:Opcode() + 1 == OPCODE.OP_RETURN then
            break
        end
    end
end








function LuaState:pushLuaStack(stack)
    stack.prev = self.stack
    self.stack = stack
end


function LuaState:popLuaStack()
    local stack = self.stack
    self.stack = stack.prev
    stack.prev = nil
end


function LuaState:printStack()
    local top = self:GetTop()
    for i = 1, top do
        local t = self:Type(i)
        if t == Type.LUA_TBOOLEAN then
            Util:printf("[%s]", tostring(self:ToBoolean(i)))
        elseif t == Type.LUA_TNUMBER then
            if self:IsInteger(i) then
                Util:printf("[%s]", tostring(self:ToInteger(i)))
            else
                Util:printf("[%s]", tostring(self:ToNumber(i)))
            end
        elseif t == Type.LUA_TNIL then
            Util:printf("[%s]", "nil")
        elseif t == Type.LUA_TSTRING then
            Util:printf('["%s"]', self:ToString(i))
        else
            Util:printf("[%s]", self:TypeName(t))
        end
    end
    Util:println("")
end

return LuaState
