local Stack = require("runtime/stack/stack")
local Closure = require("runtime/state/closure")
local Table = require("runtime/state/table")
local Chunk = require("runtime/chunk/chunk")
local Convert = require("runtime/state/convert")
local Instruction = require("runtime/vm/instruction")
local VM = require("runtime/vm/vm")
local OPCODE = require("lua/opcode")
local OPERATION = require("lua/operation")
local STACK = require("lua/stack")
local TYPE = require("lua/type")
local Util = require("common/util")

local State = {
    stack = nil,
    registry = nil,
}


function State:new()
    State.__index = State
    self = setmetatable({}, State)
    self.registry = Table:new()
    self.registry[STACK.LUA_RIDX_GLOBALS] = Table:new()
    self.stack = Stack:new(STACK.LUA_MINSTACK, self)
    return self
end


function State:GetTop()
    return self.stack:gettop()
end


function State:AbsIndex(idx)
    return self.stack:absIndex(idx)
end


function State:CheckStack(freenum)
    self.stack:ensure(freenum)
    return true
end


function State:Pop(n)
    for _ = 1, n do
        self.stack:pop()
    end
end


function State:Copy(fromIdx, toIdx)
    local val = self.stack:get(fromIdx)
    self.stack:set(toIdx, val)
end


function State:PushValue(idx)
    local val = self.stack:get(idx)
    self.stack:push(val)
end


function State:Replace(idx)
    local val = self.stack:pop()
    self.stack:set(idx, val)
end


function State:Insert(idx)
    self:Rotate(idx, 1)
end


function State:Remove(idx)
    self:Rotate(idx, -1)
    self:Pop(1)
end

-- What does lua_rotate do?
-- https://stackoverflow.com/a/52241763
function State:Rotate(idx, n)
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


function State:SetTop(idx)
    local newTop = self:AbsIndex(idx)
    if newTop < 0 then
        Util:panic("[State:SetTop ERROR] Stack underflow!")
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
    shl   = function (a, b) return a << b end,
    shr   = function (a, b) return a >> b end,
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
function State:Arith(opid)
    local a, b
    b = self.stack:pop()
    local isOPUNM = opid == OPERATION.LUA_OPUNM
    local isOPBNOT = opid == OPERATION.LUA_OPBNOT
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
        Util:panic("[State:Arith ERROR] Can not perform bitwise op!")
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
        Util:panic("[State:Arith ERROR] Can not perform any op!")
    end
end


function State:Compare(idx1, idx2, opid)
    local idx1valid = self.stack:isValid(idx1)
    local idx2valid = self.stack:isValid(idx2)
    if not idx1valid or not idx2valid then
        return false
    end

    local a = self.stack:get(idx1)
    local b = self.stack:get(idx2)
    if opid == OPERATION.LUA_OPEQ then
        return a == b
    elseif opid == OPERATION.LUA_OPLT then
        return a < b
    elseif opid == OPERATION.LUA_OPLE then
        return a <= b
    else
        Util:panic("[State:Compare ERROR] Invalid compare op!")
    end
end


function State:Len(idx)
    local val = self.stack:get(idx)
    if type(val) == "table" then
        self.stack:push(#val.table)
    else
        self.stack:push(#val)
    end
end


function State:Concat(n)
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
            Util:panic("[State:Concat ERROR] Concatenation error!")
        end
    end
end


function State:PushNil()
    self.stack:push(nil)
end


function State:PushBoolean(b)
    Util:assert(type(b), "boolean",
        "Pushing a non-boolean value by PushBoolean method"
    )
    self.stack:push(b)
end


function State:PushInteger(n)
    Util:assert(math.type(n), "integer",
        "Pushing a non-integer value by PushInteger method"
    )
    self.stack:push(n)
end


function State:PushNumber(n)
    self.stack:push(n)
end


function State:PushString(s)
    self.stack:push(s)
end


function State:TypeName(tid)
    if tid == TYPE.LUA_TNONE then
        return "no value"
    elseif tid == TYPE.LUA_TNIL then
        return "nil"
    elseif tid == TYPE.LUA_TBOOLEAN then
        return "boolean"
    elseif tid == TYPE.LUA_TNUMBER then
        return "number"
    elseif tid == TYPE.LUA_TSTRING then
        return "string"
    elseif tid == TYPE.LUA_TTABLE then
        return "table"
    elseif tid == TYPE.LUA_TFUNCTION then
        return "function"
    elseif tid == TYPE.LUA_TTHREAD then
        return "thread"
    else
        return "userdata"
    end
end


function State:Type(idx)
    if not self.stack:isValid(idx) then
        return TYPE.LUA_TNONE
    end
    local val = self.stack:get(idx)
    local valtype = type(val)
    if valtype == "nil" then
        return TYPE.LUA_TNIL
    elseif valtype == "boolean" then
        return TYPE.LUA_TBOOLEAN
    elseif valtype == "number" then
        return TYPE.LUA_TNUMBER
    elseif valtype == "string" then
        return TYPE.LUA_TSTRING
    elseif valtype == "table" then
        if val.t == "table" then
            return TYPE.LUA_TTABLE
        elseif val.t == "function" then
            return TYPE.LUA_TFUNCTION
        else
            Util:panic("[State:Type ERROR] Unknown type wrapper!")
        end
    else
        Util:panic("[State:Type ERROR] Unknown type!")
    end
end


function State:IsNone(idx)
    return self:Type(idx) == TYPE.LUA_TNONE
end


function State:IsNil(idx)
    return self:Type(idx) == TYPE.LUA_TNIL
end


function State:IsNoneOrNil(idx)
    return self:Type(idx) <= TYPE.LUA_TNIL
end


function State:IsBoolean(idx)
    return self:Type(idx) == TYPE.LUA_TBOOLEAN
end


function State:IsTable(idx)
    return self:Type(idx) == TYPE.LUA_TTABLE
end


function State:IsFunction(idx)
    return self:Type(idx) == TYPE.LUA_TFUNCTION
end


function State:IsThread(idx)
    return self:Type(idx) == TYPE.LUA_TTHREAD
end


function State:IsString(idx)
    local t = self:Type(idx)
    return t == TYPE.LUA_TSTRING or t == TYPE.LUA_TNUMBER
end


function State:IsNumber(idx)
    local val = self.stack:get(idx)
    return math.type(val) ~= nil
end


function State:IsInteger(idx)
    local val = self.stack:get(idx)
    return math.type(val) == "integer"
end


function State:ToBoolean(idx)
    local t = self:Type(idx)
    if t == TYPE.LUA_TNIL then
        return false
    elseif t == TYPE.LUA_TBOOLEAN then
        return self.stack:get(idx)
    else
        return true
    end
end


function State:ToInteger(idx)
    local i, _ = self:ToIntegerX(idx)
    return i
end


function State:ToIntegerX(idx)
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


function State:ToNumber(idx)
    local n, _ = self:ToNumberX(idx)
    return n
end


function State:ToNumberX(idx)
    local val = self.stack:get(idx)
    local mtype = math.type(val)
    if mtype ~= nil then
        return val+0.0, true
    else
        return 0, false
    end
end


function State:ToString(idx)
    local s, _ = self:ToStringX(idx)
    return s
end


function State:ToStringX(idx)
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


function State:PC()
    return self.stack.pc
end


function State:AddPC(n)
    self.stack.pc = self.stack.pc + n
end


function State:Fetch()
    self.stack.pc = self.stack.pc + 1
    local i = self.stack.closure.proto.Code[self.stack.pc]
    return i
end


function State:GetConst(idx)
    local c = self.stack.closure.proto.Constants[idx + 1]
    self.stack:push(c)
end


function State:GetRK(rk)
    if rk > 0xFF then
        self:GetConst(rk & 0xFF)
    else
        self:PushValue(rk + 1)
    end
end


function State:RegisterCount()
    return self.stack.closure.proto.MaxStackSize
end


function State:LoadVararg(n)
    if n < 0 then
        n = #self.stack.varargs
    end
    self.stack:ensure(n)
    self.stack:pushN(self.stack.varargs, n)
end


function State:LoadProto(idx)
    local proto = self.stack.closure.proto.Protos[idx]
    local closure = Closure:new(proto, nil)
    self.stack:push(closure)
end


function State:NewTable()
    self:CreateTable(0, 0)
end


function State:CreateTable(nArr, nRec)
    local t = Table:new()
    self.stack:push(t)
end

function State:GetTable(idx)
    local t = self.stack:get(idx)
    local k = self.stack:pop()
    local val = t.table[k]
    self.stack:push(val)
    return type(val)
end


function State:GetFeild(idx, k)
    local t = self.stack:get(idx)
    local val = t.table[k]
    self.stack:push(val)
    return type(val)
end


function State:GetI(idx, i)
    local t = self.stack:get(idx)
    local val = t.table[i]
    self.stack:push(val)
    return type(val)
end


function State:SetTable(idx)
    local t = self.stack:get(idx)
    local v = self.stack:pop()
    local k = self.stack:pop()
    t.table[k] = v
end


function State:SetField(idx, k)
    local t = self.stack:get(idx)
    local v = self.stack:pop()
    t.table[k] = v
end


function State:SetI(idx, i)
    local t = self.stack:get(idx)
    local v = self.stack:pop()
    t.table[i] = v
end


function State:Load(chunk, name, mode)
    local proto = Chunk:Undump(chunk)
    local closure = Closure:new(proto, nil)
    self.stack:push(closure)
end


function State:Call(nProvidedParams, nRequestedResults)
    local providedParams = self.stack:popN(nProvidedParams)
    local closure = self.stack:pop()
    if type(closure) ~= "table" or closure.t ~= "function" then
        Util:panic("[State:Call ERROR] not a function")
    end

    local nReg = STACK.LUA_MINSTACK
    local nActualParams = 0

    if closure.proto then
        nReg = closure.proto.MaxStackSize
        nActualParams = closure.proto.NumParams
    else
        nReg = nProvidedParams
        nActualParams = nProvidedParams
    end

    local newStack = Stack:new(nReg + STACK.LUA_MINSTACK)
    newStack.closure = closure
    newStack:pushN(providedParams, nActualParams)

    newStack.prev = self.stack
    self.stack = newStack

    local nActualResults
    if closure.proto then
        newStack:settop(nReg)
        if closure.proto.IsVararg == 1 and nProvidedParams >= nActualParams then
            newStack.varargs = {}
            for i = nActualParams + 1, nProvidedParams do
                newStack.varargs[#newStack.varargs + 1] = providedParams[i]
            end
        end
        while true do
            local inst = Instruction:new(self:Fetch())
            VM.Execute(inst, self)
            if inst:Opcode() + 1 == OPCODE.OP_RETURN then
                break
            end
        end
        nActualResults = newStack:gettop() - nReg
    else
        nActualResults = closure.outerfn(self)
    end

    local usedStack = self.stack
    self.stack = usedStack.prev
    usedStack.prev = nil

    if nRequestedResults ~= 0 then
        local actualResults = newStack:popN(nActualResults)
        self.stack:ensure(#actualResults)
        self.stack:pushN(actualResults, nRequestedResults)
    end

end


function State:IsOuterFunction(idx)
    local val = self.stack:get(idx)
    if type(val) == "table" and val.outerfn then
        return true
    end
    return false
end


function State:ToOuterFunction(idx)
    local val = self.stack:get(idx)
    if type(val) == "table" and val.outerfn then
        return val.outerfn
    end
    return nil
end


function State:GetGlobal(name)
    local t = self.registry:get(STACK.LUA_RIDX_GLOBALS)
    local val = t.table[name]
    self.stack:push(val)
    return type(val)
end


function State:PushOuterFunction(outerfn)
    local closure = Closure:new(nil, outerfn)
    self.stack:push(closure)
end


function State:PushGlobalTable()
    local glb = self.registry[STACK.LUA_RIDX_GLOBALS]
    self.stack:push(glb)
end


function State:SetGlobal(name)
    local t = self.registry[STACK.LUA_RIDX_GLOBALS]
    local v = self.stack:pop()
    t.table[name] = v
end


function State:Register(name, outerfn)
    self:PushOuterFunction(outerfn)
    self:SetGlobal(name)
end


function State:_printStack(name)
    Util:printf(tostring(name))
    local top = self:GetTop()
    for i = 1, top do
        local t = self:Type(i)
        if t == TYPE.LUA_TBOOLEAN then
            Util:printf("[%s]", tostring(self:ToBoolean(i)))
        elseif t == TYPE.LUA_TNUMBER then
            if self:IsInteger(i) then
                Util:printf("[%s]", tostring(self:ToInteger(i)))
            else
                Util:printf("[%s]", tostring(self:ToNumber(i)))
            end
        elseif t == TYPE.LUA_TNIL then
            Util:printf("[%s]", "nil")
        elseif t == TYPE.LUA_TSTRING then
            Util:printf('["%s"]', self:ToString(i))
        else
            Util:printf("[%s]", self:TypeName(t))
        end
    end
    Util:println("")
end

return State
