local Stack = require("runtime/stack/stack")
local Closure = require("runtime/value/closure")
local Table = require("runtime/value/table")
local Chunk = require("runtime/chunk/chunk")
local Value = require("runtime/value/value")
local Instruction = require("runtime/vm/instruction")
local VM = require("runtime/vm/vm")
local OPCODE = require("const/opcode")
local OPERATION = require("const/operation")
local STACK = require("const/stack")
local TYPE = require("const/type")
local Fmt = require("util/fmt")
local Throw = require("util/throw")


local State = {
    stack = nil,
    registry = nil,
}


function State:new()
    State.__index = State
    self = setmetatable({}, State)
    self.registry = Table:new()
    self.registry.table[STACK.LUA_RIDX_GLOBALS] = Table:new()
    self.stack = Stack:new(STACK.LUA_MINSTACK, self)
    return self
end


function State:printStack(prefix)
    if prefix ~= nil then
        Fmt:printf(tostring(prefix))
    end
    local top = self:GetTop()
    for i = 1, top do
        local tid = self:Type(i)
        if tid == TYPE.LUA_TBOOLEAN then
            Fmt:printf("[%s]", tostring(self:ToBoolean(i)))
        elseif tid == TYPE.LUA_TNUMBER then
            if self:IsInteger(i) then
                Fmt:printf("[%s]", tostring(self:ToInteger(i)))
            else
                Fmt:printf("[%s]", tostring(self:ToNumber(i)))
            end
        elseif tid == TYPE.LUA_TNIL then
            Fmt:printf("[%s]", "nil")
        elseif tid == TYPE.LUA_TSTRING then
            Fmt:printf('["%s"]', self:ToString(i))
        else
            Fmt:printf("[%s]", Value.TypeID2Name(tid))
        end
    end
    Fmt:println("")
end


--[[
    Lua state standard API
--]]


function State:AbsIndex(idx)
    return self.stack:absIndex(idx)
end


function State:AddPC(n)
    self.stack.pc = self.stack.pc + n
end


local Fn = {
    add  = function (a, b) return a + b  end,
    sub  = function (a, b) return a - b  end,
    mul  = function (a, b) return a * b  end,
    mod  = function (a, b) return a % b  end,
    pow  = function (a, b) return a ^ b  end,
    div  = function (a, b) return a / b  end,
    idiv = function (a, b) return a // b end,
    band = function (a, b) return a & b  end,
    bor  = function (a, b) return a | b  end,
    bxor = function (a, b) return a ~ b  end,
    shl  = function (a, b) return a << b end,
    shr  = function (a, b) return a >> b end,
    unm  = function (a, _) return -a     end,
    bnot = function (a, _) return ~a     end,
}

local Operators = {
    { Fn.add , Fn.add ,},
    { Fn.sub , Fn.sub ,},
    { Fn.mul , Fn.mul ,},
    { Fn.mod , Fn.mod ,},
    { nil    , Fn.pow ,},
    { nil    , Fn.div ,},
    { Fn.idiv, Fn.idiv,},
    { Fn.band, nil    ,},
    { Fn.bor , nil    ,},
    { Fn.bxor, nil    ,},
    { Fn.shl , nil    ,},
    { Fn.shr , nil    ,},
    { Fn.unm , Fn.unm ,},
    { Fn.bnot, nil    ,},
}


function State:Arith(opid)
    local op = Operators[opid + 1]
    local a, b
    b = self.stack:pop()
    local isOPUNM = opid == OPERATION.LUA_OPUNM
    local isOPBNOT = opid == OPERATION.LUA_OPBNOT
    if isOPUNM or isOPBNOT then
        a = b
    else
        a = self.stack:pop()
    end

    local errmsg, convertFn, opFn
    if op[2] == nil then
        errmsg = "attemp to perform bitwise operation on a non-integer value"
        convertFn = Value.Any2Int
        opFn = op[1]
    else
        errmsg = "attemp to perform arithmetic on a non-floating point value"
        convertFn = Value.Any2Float
        opFn = op[2]
    end

    local x, ok1 = convertFn(a)
    local y, ok2 = convertFn(b)
    local result, ok3
    if ok1 and ok2 then
        result, ok3 = opFn(x, y), true
    else
        y, ok2 = b, true
    end
    if not ok3 then
        Throw:error(errmsg)
    end
    self.stack:push(result)
end


function State:Call(nProvidedParams, nRequestedResults)
    local providedParams = self.stack:popN(nProvidedParams)
    local closure = self.stack:pop()
    if type(closure) ~= "table" or closure.t ~= TYPE.LUA_TFUNCTION then
        Throw:error("[State:Call ERROR] not a function")
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


function State:CheckStack(freenum)
    self.stack:ensure(freenum)
    return true
end


function State:CloseUpvalues(a)
    for i = 1, #self.stack.openuvs do
        local uv = self.stack.openuvs[i]
        if uv.idx >= a and uv.stack then
            uv.val = uv.stk:get(uv.idx + 1)
            uv.stk = nil
            table.remove(self.stack.openuvs, i)
        end
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
    end

    local ta = type(a)
    local tb = type(b)
    local bothnum = ta == "number" and tb == "number"
    if not bothnum then
        local bothstr = ta == "string" and tb == "string"
        if not bothstr then
            if ta == tb then
                Throw:error("attempt to compare two %s values", ta)
            else
                Throw:error("attempt to compare %s with %s", ta, tb)
            end
        end
    end

    if opid == OPERATION.LUA_OPLT then
        return a < b
    elseif opid == OPERATION.LUA_OPLE then
        return a <= b
    else
        return false
    end
end


function State:Concat(n)
    if n >= 2 then
        for _ = 1, n - 1 do
            local tid2 = self:Type(-1)
            if tid2 ~= TYPE.LUA_TSTRING and tid2 ~= TYPE.LUA_TNUMBER then
                Throw:error("attemp to concatenate a %s value", Value.TypeID2Name(tid2))
            end
            local tid1 = self:Type(-2)
            if tid1 ~= TYPE.LUA_TSTRING and tid1 ~= TYPE.LUA_TNUMBER then
                Throw:error("attemp to concatenate a %s value", Value.TypeID2Name(tid1))
            end
            local s2 = self:ToString(-1)
            local s1 = self:ToString(-2)
            self.stack:pop()
            self.stack:pop()
            self.stack:push(s1..s2)
        end
    elseif n == 0 then
        self.stack:push("")
    end
    -- n == 1; nothing to do
end



function State:Copy(fromIdx, toIdx)
    local val = self.stack:get(fromIdx)
    self.stack:set(toIdx, val)
end


function State:CreateTable(nArr, nRec)
    local t = Table:new()
    self.stack:push(t)
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


function State:GetFeild(idx, k)
    local t = self.stack:get(idx)
    local val = t.table[k]
    self.stack:push(val)
    return type(val)
end


function State:GetGlobal(name)
    local t = self.registry.table[STACK.LUA_RIDX_GLOBALS]
    local val = t.table[name]
    self.stack:push(val)
    return type(val)
end


function State:GetI(idx, i)
    local t = self.stack:get(idx)
    local val = t.table[i]
    self.stack:push(val)
    return type(val)
end


function State:GetRK(rk)
    if rk > 0xFF then
        self:GetConst(rk & 0xFF)
    else
        self:PushValue(rk + 1)
    end
end


function State:GetTable(idx)
    local t = self.stack:get(idx)
    local k = self.stack:pop()
    local val = t.table[k]
    self.stack:push(val)
    return type(val)
end


function State:GetTop()
    return self.stack:gettop()
end


function State:Insert(idx)
    self:Rotate(idx, 1)
end


function State:IsBoolean(idx)
    return self:Type(idx) == TYPE.LUA_TBOOLEAN
end


function State:IsFunction(idx)
    return self:Type(idx) == TYPE.LUA_TFUNCTION
end


function State:IsInteger(idx)
    local val = self.stack:get(idx)
    return math.type(val) == "integer"
end


function State:IsNil(idx)
    return self:Type(idx) == TYPE.LUA_TNIL
end


function State:IsNone(idx)
    return self:Type(idx) == TYPE.LUA_TNONE
end


function State:IsNoneOrNil(idx)
    return self:Type(idx) <= TYPE.LUA_TNIL
end


function State:IsNumber(idx)
    local val = self.stack:get(idx)
    return math.type(val) ~= nil
end


function State:IsOuterFunction(idx)
    local val = self.stack:get(idx)
    if type(val) == "table" and val.outerfn then
        return true
    end
    return false
end


function State:IsString(idx)
    local t = self:Type(idx)
    return t == TYPE.LUA_TSTRING or t == TYPE.LUA_TNUMBER
end


function State:IsTable(idx)
    return self:Type(idx) == TYPE.LUA_TTABLE
end


function State:IsThread(idx)
    return self:Type(idx) == TYPE.LUA_TTHREAD
end


function State:Len(idx)
    local val = self.stack:get(idx)
    local tid = self:Type(idx)
    if tid == TYPE.LUA_TSTRING then
        self.stack:push(#val)
    elseif tid == TYPE.LUA_TTABLE then
        self.stack:push(#val.table)
    else
        Throw:error("attempt to get length of a %s value", Value.TypeID2Name(tid))
    end
end


function State:Load(chunk, name, mode)
    local proto = Chunk:Undump(chunk)
    local closure = Closure:new(proto, nil, #proto.Upvalues)
    self.stack:push(closure)
    if #proto.Upvalues > 0 then
        local env = self.registry.table[STACK.LUA_RIDX_GLOBALS]
        closure:holdUpvalue(1, env)
    end
end


function State:LoadProto(idx)
    local proto = self.stack.closure.proto.Protos[idx]
    local closure = Closure:new(proto, nil, #proto.Upvalues)
    self.stack:push(closure)

    for i, uvinfo in ipairs(proto.Upvalues) do
        local uvidx = uvinfo.Idx
        if uvinfo.Instack == 1 then
            local value = self.stack.openuvs[uvidx + 1]
            if value then
                closure:holdUpvalue(i, value)
            else
                closure:createUpvalue(i, self.stack, uvidx)
                self.stack.openuvs[uvidx + 1] = closure.upvalues[i]
            end
        else
            local value = self.stack.closure.upvalues[uvidx + 1]
            closure.upvalues[i] = value
        end
    end
end


function State:LoadVararg(n)
    if n < 0 then
        n = #self.stack.varargs
    end
    self.stack:ensure(n)
    self.stack:pushN(self.stack.varargs, n)
end


function State:NewTable()
    self:CreateTable(0, 0)
end


function State:PC()
    return self.stack.pc
end


function State:Pop(n)
    for _ = 1, n do
        self.stack:pop()
    end
end


function State:PushBoolean(b)
    if type(b) ~= "boolean" then
        Throw:error("Pushing a non-boolean value by PushBoolean method")
    end
    self.stack:push(b)
end


function State:PushGlobalTable()
    local t = self.registry.table[STACK.LUA_RIDX_GLOBALS]
    self.stack:push(t)
end


function State:PushInteger(n)
    if math.type(n) ~= "integer" then
        Throw:error("Pushing a non-integer value by PushInteger method")
    end
    self.stack:push(n)
end


function State:PushNil()
    self.stack:push(nil)
end


function State:PushNumber(n)
    self.stack:push(n)
end


function State:PushOuterClosure(outerfn, n)
    local closure = Closure:new(nil, outerfn, n)
    for i = n, 1, -1 do
        local val = self.stack:pop()
        closure:holdUpvalue(i, val)
    end
    self.stack:push(closure)
end


function State:PushOuterFunction(outerfn)
    local closure = Closure:new(nil, outerfn, 0)
    self.stack:push(closure)
end


function State:PushString(s)
    self.stack:push(s)
end


function State:PushValue(idx)
    local val = self.stack:get(idx)
    self.stack:push(val)
end


function State:Register(name, outerfn)
    self:PushOuterFunction(outerfn)
    self:SetGlobal(name)
end


function State:RegisterCount()
    return self.stack.closure.proto.MaxStackSize
end


function State:Remove(idx)
    self:Rotate(idx, -1)
    self:Pop(1)
end


function State:Replace(idx)
    local val = self.stack:pop()
    self.stack:set(idx, val)
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


function State:SetField(idx, k)
    local t = self.stack:get(idx)
    local v = self.stack:pop()
    t.table[k] = v
end


function State:SetGlobal(name)
    local t = self.registry.table[STACK.LUA_RIDX_GLOBALS]
    local v = self.stack:pop()
    t.table[name] = v
end


function State:SetI(idx, i)
    local t = self.stack:get(idx)
    local v = self.stack:pop()
    t.table[i] = v
end


function State:SetTable(idx)
    local t = self.stack:get(idx)
    local v = self.stack:pop()
    local k = self.stack:pop()
    t.table[k] = v
end


function State:SetTop(idx)
    local newTop = self:AbsIndex(idx)
    if newTop < 0 then
        Throw:error("[State:SetTop ERROR] Stack underflow!")
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


function State:ToOuterFunction(idx)
    local val = self.stack:get(idx)
    if type(val) == "table" and val.outerfn then
        return val.outerfn
    end
    return nil
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


function State:Type(idx)
    if not self.stack:isValid(idx) then
        return TYPE.LUA_TNONE
    end
    local val = self.stack:get(idx)
    return Value.TypeID(val)
end


return State
