local LuaStack = require("runtime/state/luastack")
local LuaType = require("runtime/state/luatype")
local LuaOperation = require("runtime/state/luaoperation")
local Arith = require("runtime/operation/arithmetic")
local Compare = require("runtime/operation/compare")
local Convert = require("runtime/operation/convert")
local Logical = require("runtime/operation/logical")
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
    imod  = function (a, b) return Arith:imod(a, b) end,
    fmod  = function (a, b) return Arith:fmod(a, b) end,
    pow   = function (a, b) return a ^ b end,
    div   = function (a, b) return a / b end,
    iidiv = function (a, b) return Arith:ifloordiv(a, b) end,
    fidiv = function (a, b) return Arith:ffloordiv(a, b) end,
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
    local isOPUNM = opid == LuaOperation.LUA_OPUNM
    local isOPBNOT = opid == LuaOperation.LUA_OPBNOT
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
    if opid == LuaOperation.LUA_OPEQ then
        return Compare:eq(a, b)
    elseif opid == LuaOperation.LUA_OPLT then
        return Compare:lt(a, b)
    elseif opid == LuaOperation.LUA_OPLE then
        return Compare:le(a, b)
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
        if t == LuaType.LUA_TBOOLEAN then
            Util:printf("[%s]", tostring(self:ToBoolean(i)))
        elseif t == LuaType.LUA_TNUMBER then
            if self:IsInteger(i) then
                Util:printf("[%s]", tostring(self:ToInteger(i)))
            else
                Util:printf("[%s]", tostring(self:ToNumber(i)))
            end
        elseif t == LuaType.LUA_TNIL then
            Util:printf("[%s]", "nil")
        elseif t == LuaType.LUA_TSTRING then
            Util:printf('["%s"]', self:ToString(i))
        else
            Util:printf("[%s]", self:TypeName(t))
        end
    end
    Util:println("")
end

return LuaState
