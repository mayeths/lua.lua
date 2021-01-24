require("runtime/state/luaoperation")
local Arith = require("runtime/operation/arithmetic")
require("runtime/operation/compare")
require("runtime/operation/convert")
require("runtime/operation/logical")
local Util = require("common/util")


local Operator = {
    intFn = nil,
    floatFn = nil,
}


function Operator:new(intFn, floatFn)
    Operator.__index = Operator
    self = setmetatable({}, Operator)
    self.intFn = intFn or nil
    self.floatFn = floatFn or nil
    return self
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
    Operator:new(Fn.iadd,  Fn.fadd  ),
    Operator:new(Fn.isub,  Fn.fsub  ),
    Operator:new(Fn.imul,  Fn.fmul  ),
    Operator:new(Fn.imod,  Fn.fmod  ),
    Operator:new(nil,      Fn.pow   ),
    Operator:new(nil,      Fn.div   ),
    Operator:new(Fn.iidiv, Fn.fidiv ),
    Operator:new(Fn.band,  nil      ),
    Operator:new(Fn.bor,   nil      ),
    Operator:new(Fn.bxor,  nil      ),
    Operator:new(Fn.shl,   nil      ),
    Operator:new(Fn.shr,   nil      ),
    Operator:new(Fn.iunm,  Fn.funm  ),
    Operator:new(Fn.bnot,  nil      ),
}
local OPERATORS_OFFSET = 1


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

    local op = Operators[opid + OPERATORS_OFFSET]
    local isBitwise = op.floatFn == nil
    local tryIntFnFirst = op.intFn ~= nil
    if isBitwise then
        local x, ok1 = Convert:any2int(a)
        local y, ok2 = Convert:any2int(b)
        if ok1 and ok2 then
            local result = op.intFn(x, y)
            self.stack:push(result)
            return
        end
        Util:panic("[LuaState:Arith ERROR] Can not perform bitwise op!")
    else
        if tryIntFnFirst then
            local x, ok1 = Convert:any2int(a)
            local y, ok2 = Convert:any2int(b)
            if ok1 and ok2 then
                local result = op.intFn(x, y)
                self.stack:push(result)
                return
            end
        end
        local x, ok1 = Convert:any2float(a)
        local y, ok2 = Convert:any2float(b)
        if ok1 and ok2 then
            local result = op.floatFn(x, y)
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
    self.stack:push(#val)
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

