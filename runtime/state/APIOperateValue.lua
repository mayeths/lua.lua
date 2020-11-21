require("runtime/state/luaoperation")
require("runtime/operation/arithmetic")
require("runtime/operation/compare")
require("runtime/operation/convert")
require("runtime/operation/logical")
require("util/util")


local Operator = {
    intFn = nil,
    floatFn = nil,
}


function Operator:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.intFn = o.intFn or nil
    self.floatFn = o.floatFn or nil
    return o
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
    Operator:new({ intFn = Fn.iadd,  floatFn = Fn.fadd  }),
    Operator:new({ intFn = Fn.isub,  floatFn = Fn.fsub  }),
    Operator:new({ intFn = Fn.imul,  floatFn = Fn.fmul  }),
    Operator:new({ intFn = Fn.imod,  floatFn = Fn.fmod  }),
    Operator:new({ intFn = nil,      floatFn = Fn.pow   }),
    Operator:new({ intFn = nil,      floatFn = Fn.div   }),
    Operator:new({ intFn = Fn.iidiv, floatFn = Fn.fidiv }),
    Operator:new({ intFn = Fn.band,  floatFn = nil      }),
    Operator:new({ intFn = Fn.bor,   floatFn = nil      }),
    Operator:new({ intFn = Fn.bxor,  floatFn = nil      }),
    Operator:new({ intFn = Fn.shl,   floatFn = nil      }),
    Operator:new({ intFn = Fn.shr,   floatFn = nil      }),
    Operator:new({ intFn = Fn.iunm,  floatFn = Fn.funm  }),
    Operator:new({ intFn = Fn.bnot,  floatFn = nil      }),
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

    -- LuaOperation start from 0, but Operators start from 1
    local op = Operators[opid + 1]
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

