local LuaOperation = require("runtime/state/luaoperation")
local Type = require("runtime/constrant/type")
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
    if vm:Type(a) == Type.LUA_TSTRING then
        vm:PushNumber(vm:ToNumber(a))
        vm:Replace(a)
    end
    if vm:Type(a + 1) == Type.LUA_TSTRING then
        vm:PushNumber(vm:ToNumber(a + 1))
        vm:Replace(a + 1)
    end
    if vm:Type(a + 2) == Type.LUA_TSTRING then
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

function Action.newTable(inst, vm)
    local a, b, c = inst:ABC()
    a = a + 1
    vm:CreateTable(Action._fb2int(b), Action._fb2int(c))
    vm:Replace(a)
end

function Action.getTable(inst, vm)
    local a, b, c = inst:ABC()
    a = a + 1
    b = b + 1
    vm:GetRK(c)
    vm:GetTable(b)
    vm:Replace(a)
end

function Action.setTable(inst, vm)
    local a, b, c = inst:ABC()
    a = a + 1
    vm:GetRK(b)
    vm:GetRK(c)
    vm:SetTable(a)
end

function Action.setList(inst, vm)
    local a, b, c = inst:ABC()
    a = a + 1
    if c > 0 then
        c = c - 1
    else
        c = (vm:Fetch() >> 6)
    end
    local b0 = b == 0
    if b0 then
        b = vm:ToInteger(-1) - a - 1
        vm:Pop(1)
    end
    vm:CheckStack(1)
    local idx = c * 50
    for i = 1, b do
        idx = idx + 1
        vm:PushValue(a + i)
        vm:SetI(a, idx)
    end
    if b0 then
        for i = vm:RegisterCount() + 1, vm:GetTop() do
            idx = idx + 1
            vm:PushValue(i)
            vm:SetI(a, idx)
        end
        vm:SetTop(vm:RegisterCount())
    end
end

function Action.self(inst, vm)
    local a, b, c = inst:ABC()
    a = a + 1
    b = b + 1
    vm:Copy(b, a + 1)
    vm:GetRK(c)
    vm:GetTable(b)
    vm:Replace(a)
end

function Action.closure(inst, vm)
    local a, bx = inst:ABx()
    a = a + 1
    vm:LoadProto(bx + 1)
    vm:Replace(a)
end

function Action.vararg(inst, vm)
    local a, b, _ = inst:ABC()
    a = a + 1
    if b ~= 1 then
        vm:LoadVararg(b - 1)
        Action._popResults(a, b, vm)
    end
end

function Action.tailCall(inst, vm)
    local a, b, _ = inst:ABC()
    a = a + 1
    local c = 0
    local nargs = Action._pushFuncAndArgs(a, b, vm)
    vm:Call(nargs, c - 1)
    Action._popResults(a, c, vm)
end

function Action.call(inst, vm)
    local a, b, c = inst:ABC()
    a = a + 1
    local nargs = Action._pushFuncAndArgs(a, b, vm)
    vm:Call(nargs, c - 1)
    Action._popResults(a, c, vm)
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

function Action._fb2int(x)
    if x < 8 then
        return x
    else
        return ((x & 7) + 8) << ((x >> 3) - 1)
    end
end

function Action._pushFuncAndArgs(a, b, vm)
    if b > 1 then
        vm:CheckStack(b)
        for i = a, a + b - 1 do
            vm:PushValue(i)
        end
        return b - 1
    else
        Action._fixStack(a, vm)
        return vm:GetTop() - vm:RegisterCount() - 1
    end
end

function Action._fixStack(a, vm)
    local x = vm:ToInteger(-1)
    vm:Pop(1)
    vm:CheckStack(x - a)
    for i = a, x - 1 do
        vm:PushValue(i)
    end
    vm:Rotate(vm:RegisterCount() + 1, x - a)
end

function Action._popResults(a, c, vm)
    if c == 1 then
        --
    elseif c > 1 then
        for i = a + c - 2, a, -1 do
            vm:Replace(i)
        end
    else
        vm:CheckStack(1)
        vm:PushInteger(a)
    end
end

function Action._return(inst, vm)
    local a, b, _ = inst:ABC()
    a = a + 1
    if b == 1 then
        --
    elseif b > 1 then
        vm:CheckStack(b - 1)
        for i = a, a + b - 2 do
            vm:PushValue(i)
        end
    else
        Action._fixStack(a, vm)
    end
end

return Action
