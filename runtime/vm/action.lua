local LuaOperation = require("runtime/state/luaoperation")
local LuaType = require("runtime/state/luatype")
local Util = require("common/util")

local Action = {}


function Action.loadNil(inst, vm)
    local a, b, _ = inst:ABC()
    a = a + 1
    vm:PushNil()
    for i = a, a + b do
        vm:Copy(-1, i)
    end
    vm:Pop(1)
end

function Action.loadBool(inst, vm)
    local a, b, c = inst:ABC()
    a = a + 1
    vm:PushBoolean(b ~= 0)
    vm:Replace(a)
    if c ~= 0 then
        vm:AddPC(1)
    end
end

function Action.loadK(inst, vm)
    local a, bx = inst:ABx()
    a = a + 1
    vm:GetConst(bx)
    vm:Replace(a)
end

function Action.loadKx(inst, vm)
    local a, _ = inst:ABx()
    a = a + 1
    local ax = vm:Fetch() >> 6
    vm:GetConst(ax)
    vm:Replace(a)
end

function Action.forPrep(inst, vm)
    local a, sBx = inst:AsBx()
    a = a + 1
    if vm:Type(a) == LuaType.LUA_TSTRING then
        vm:PushNumber(vm:ToNumber(a))
        vm:Replace(a)
    end
    if vm:Type(a + 1) == LuaType.LUA_TSTRING then
        vm:PushNumber(vm:ToNumber(a + 1))
        vm:Replace(a + 1)
    end
    if vm:Type(a + 2) == LuaType.LUA_TSTRING then
        vm:PushNumber(vm:ToNumber(a + 2))
        vm:Replace(a + 2)
    end
    vm:PushValue(a)
    vm:PushValue(a + 2)
    vm:Arith(LuaOperation.LUA_OPSUB)
    vm:Replace(a)
    vm:AddPC(sBx)
end

function Action.forLoop(inst, vm)
    local a, sBx = inst:AsBx()
    a = a + 1
    vm:PushValue(a + 2)
    vm:PushValue(a)
    vm:Arith(LuaOperation.LUA_OPADD)
    vm:Replace(a)
    local isPositiveStep = vm:ToNumber(a + 2) >= 0
    if isPositiveStep and vm:Compare(a, a + 1, LuaOperation.LUA_OPLE) or not isPositiveStep and vm:Compare(a + 1, a, LuaOperation.LUA_OPLE) then
        vm:AddPC(sBx)
        vm:Copy(a, a + 3)
    end
end

function Action.move(inst, vm)
    local a, b, _ = inst:ABC()
    vm:Copy(b + 1, a + 1)
end

function Action.jmp(inst, vm)
    local a, sBx = inst:AsBx()
    vm:AddPC(sBx)
    if a ~= 0 then
        Util:panic("todo: jmp!")
    end
end

function Action.no(inst, vm)
    local a, b, _ = inst:ABC()
    a = a + 1
    b = b + 1
    vm:PushBoolean(not vm:ToBoolean(b))
    vm:Replace(a)
end

function Action.test(inst, vm)
    local a, _, c = inst:ABC()
    a = a + 1
    if vm:ToBoolean(a) ~= (c ~= 0) then
        vm:AddPC(1)
    end
end

function Action.testSet(inst, vm)
    local a, b, c = inst:ABC()
    a = a + 1
    b = b + 1
    if vm:ToBoolean(b) == (c ~= 0) then
        vm:Copy(b, a)
    else
        vm:AddPC(1)
    end
end

function Action.length(inst, vm)
    local a, b, _ = inst:ABC()
    a = a + 1
    b = b + 1
    vm:Len(b)
    vm:Replace(a)
end

function Action.concat(inst, vm)
    local a, b, c = inst:ABC()
    a = a + 1
    b = b + 1
    c = c + 1
    local n = c - b + 1
    vm:CheckStack(n)
    for i = b, c do
        vm:PushValue(i)
    end
    vm:Concat(n)
    vm:Replace(a)
end

function Action.add(inst, vm)
    Action._binaryArith(inst, vm, LuaOperation.LUA_OPADD)
end

function Action.sub(inst, vm)
    Action._binaryArith(inst, vm, LuaOperation.LUA_OPSUB)
end

function Action.mul(inst, vm)
    Action._binaryArith(inst, vm, LuaOperation.LUA_OPMUL)
end

function Action.mod(inst, vm)
    Action._binaryArith(inst, vm, LuaOperation.LUA_OPMOD)
end

function Action.pow(inst, vm)
    Action._binaryArith(inst, vm, LuaOperation.LUA_OPPOW)
end

function Action.div(inst, vm)
    Action._binaryArith(inst, vm, LuaOperation.LUA_OPDIV)
end

function Action.idiv(inst, vm)
    Action._binaryArith(inst, vm, LuaOperation.LUA_OPIDIV)
end

function Action.band(inst, vm)
    Action._binaryArith(inst, vm, LuaOperation.LUA_OPBAND)
end

function Action.bor(inst, vm)
    Action._binaryArith(inst, vm, LuaOperation.LUA_OPBOR)
end

function Action.bxor(inst, vm)
    Action._binaryArith(inst, vm, LuaOperation.LUA_OPBXOR)
end

function Action.shl(inst, vm)
    Action._binaryArith(inst, vm, LuaOperation.LUA_OPSHL)
end

function Action.shr(inst, vm)
    Action._binaryArith(inst, vm, LuaOperation.LUA_OPSHR)
end

function Action.unm(inst, vm)
    Action._unaryArith(inst, vm, LuaOperation.LUA_OPUNM)
end

function Action.bnot(inst, vm)
    Action._unaryArith(inst, vm, LuaOperation.LUA_OPBNOT)
end

function Action.eq(inst, vm)
    Action._compare(inst, vm, LuaOperation.LUA_OPEQ)
end

function Action.lt(inst, vm)
    Action._compare(inst, vm, LuaOperation.LUA_OPLT)
end

function Action.le(inst, vm)
    Action._compare(inst, vm, LuaOperation.LUA_OPLE)
end


function Action._binaryArith(inst, vm, op)
    local a, b, c = inst:ABC()
    a = a + 1
    vm:GetRK(b)
    vm:GetRK(c)
    vm:Arith(op)
    vm:Replace(a)
end

function Action._unaryArith(inst, vm, op)
    local a, b, _ = inst:ABC()
    a = a + 1
    b = b + 1
    vm:PushValue(b)
    vm:Arith(op)
    vm:Replace(a)
end

function Action._compare(inst, vm, op)
    local a, b, c = inst:ABC()
    vm:GetRK(b)
    vm:GetRK(c)
    if vm:Compare(-2, -1, op) ~= (a ~= 0) then
        vm:AddPC(1)
    end
    vm:Pop(2)
end


return Action
