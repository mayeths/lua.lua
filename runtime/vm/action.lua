local OPERATION = require("lua/operation")
local TYPE = require("lua/type")
local Util = require("common/util")

local Action = {}


function Action.LoadNil(inst, vm)
    local a, b, _ = inst:ABC()
    a = a + 1
    vm:PushNil()
    for i = a, a + b do
        vm:Copy(-1, i)
    end
    vm:Pop(1)
end

function Action.LoadBool(inst, vm)
    local a, b, c = inst:ABC()
    a = a + 1
    vm:PushBoolean(b ~= 0)
    vm:Replace(a)
    if c ~= 0 then
        vm:AddPC(1)
    end
end

function Action.LoadK(inst, vm)
    local a, bx = inst:ABx()
    a = a + 1
    vm:GetConst(bx)
    vm:Replace(a)
end

function Action.LoadKx(inst, vm)
    local a, _ = inst:ABx()
    a = a + 1
    local ax = vm:Fetch() >> 6
    vm:GetConst(ax)
    vm:Replace(a)
end

function Action.ForPrep(inst, vm)
    local a, sBx = inst:AsBx()
    a = a + 1
    if vm:Type(a) == TYPE.LUA_TSTRING then
        vm:PushNumber(vm:ToNumber(a))
        vm:Replace(a)
    end
    if vm:Type(a + 1) == TYPE.LUA_TSTRING then
        vm:PushNumber(vm:ToNumber(a + 1))
        vm:Replace(a + 1)
    end
    if vm:Type(a + 2) == TYPE.LUA_TSTRING then
        vm:PushNumber(vm:ToNumber(a + 2))
        vm:Replace(a + 2)
    end
    vm:PushValue(a)
    vm:PushValue(a + 2)
    vm:Arith(OPERATION.LUA_OPSUB)
    vm:Replace(a)
    vm:AddPC(sBx)
end

function Action.ForLoop(inst, vm)
    local a, sBx = inst:AsBx()
    a = a + 1
    vm:PushValue(a + 2)
    vm:PushValue(a)
    vm:Arith(OPERATION.LUA_OPADD)
    vm:Replace(a)
    local isPositiveStep = vm:ToNumber(a + 2) >= 0
    if isPositiveStep and vm:Compare(a, a + 1, OPERATION.LUA_OPLE) or not isPositiveStep and vm:Compare(a + 1, a, OPERATION.LUA_OPLE) then
        vm:AddPC(sBx)
        vm:Copy(a, a + 3)
    end
end

function Action.Move(inst, vm)
    local a, b, _ = inst:ABC()
    vm:Copy(b + 1, a + 1)
end

function Action.Jmp(inst, vm)
    local a, sBx = inst:AsBx()
    vm:AddPC(sBx)
    if a ~= 0 then
        Util:panic("todo: jmp!")
    end
end

function Action.No(inst, vm)
    local a, b, _ = inst:ABC()
    a = a + 1
    b = b + 1
    vm:PushBoolean(not vm:ToBoolean(b))
    vm:Replace(a)
end

function Action.Test(inst, vm)
    local a, _, c = inst:ABC()
    a = a + 1
    if vm:ToBoolean(a) ~= (c ~= 0) then
        vm:AddPC(1)
    end
end

function Action.TestSet(inst, vm)
    local a, b, c = inst:ABC()
    a = a + 1
    b = b + 1
    if vm:ToBoolean(b) == (c ~= 0) then
        vm:Copy(b, a)
    else
        vm:AddPC(1)
    end
end

function Action.Length(inst, vm)
    local a, b, _ = inst:ABC()
    a = a + 1
    b = b + 1
    vm:Len(b)
    vm:Replace(a)
end

function Action.Concat(inst, vm)
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

function Action.NewTable(inst, vm)
    local a, b, c = inst:ABC()
    a = a + 1
    vm:CreateTable(Action._fb2int(b), Action._fb2int(c))
    vm:Replace(a)
end

function Action.GetTable(inst, vm)
    local a, b, c = inst:ABC()
    a = a + 1
    b = b + 1
    vm:GetRK(c)
    vm:GetTable(b)
    vm:Replace(a)
end

function Action.SetTable(inst, vm)
    local a, b, c = inst:ABC()
    a = a + 1
    vm:GetRK(b)
    vm:GetRK(c)
    vm:SetTable(a)
end

function Action.SetList(inst, vm)
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

function Action.Self(inst, vm)
    local a, b, c = inst:ABC()
    a = a + 1
    b = b + 1
    vm:Copy(b, a + 1)
    vm:GetRK(c)
    vm:GetTable(b)
    vm:Replace(a)
end

function Action.Closure(inst, vm)
    local a, bx = inst:ABx()
    a = a + 1
    vm:LoadProto(bx + 1)
    vm:Replace(a)
end

function Action.Vararg(inst, vm)
    local a, b, _ = inst:ABC()
    a = a + 1
    if b ~= 1 then
        vm:LoadVararg(b - 1)
        Action._popResults(a, b, vm)
    end
end

function Action.TailCall(inst, vm)
    local a, b, _ = inst:ABC()
    a = a + 1
    local c = 0
    local nargs = Action._pushFuncAndArgs(a, b, vm)
    vm:Call(nargs, c - 1)
    Action._popResults(a, c, vm)
end

function Action.Call(inst, vm)
    local a, b, c = inst:ABC()
    a = a + 1
    local nargs = Action._pushFuncAndArgs(a, b, vm)
    vm:Call(nargs, c - 1)
    Action._popResults(a, c, vm)
end

function Action.Add(inst, vm)
    Action._binaryArith(inst, vm, OPERATION.LUA_OPADD)
end

function Action.Sub(inst, vm)
    Action._binaryArith(inst, vm, OPERATION.LUA_OPSUB)
end

function Action.Mul(inst, vm)
    Action._binaryArith(inst, vm, OPERATION.LUA_OPMUL)
end

function Action.Mod(inst, vm)
    Action._binaryArith(inst, vm, OPERATION.LUA_OPMOD)
end

function Action.Pow(inst, vm)
    Action._binaryArith(inst, vm, OPERATION.LUA_OPPOW)
end

function Action.Div(inst, vm)
    Action._binaryArith(inst, vm, OPERATION.LUA_OPDIV)
end

function Action.Idiv(inst, vm)
    Action._binaryArith(inst, vm, OPERATION.LUA_OPIDIV)
end

function Action.Band(inst, vm)
    Action._binaryArith(inst, vm, OPERATION.LUA_OPBAND)
end

function Action.Bor(inst, vm)
    Action._binaryArith(inst, vm, OPERATION.LUA_OPBOR)
end

function Action.Bxor(inst, vm)
    Action._binaryArith(inst, vm, OPERATION.LUA_OPBXOR)
end

function Action.Shl(inst, vm)
    Action._binaryArith(inst, vm, OPERATION.LUA_OPSHL)
end

function Action.Shr(inst, vm)
    Action._binaryArith(inst, vm, OPERATION.LUA_OPSHR)
end

function Action.Unm(inst, vm)
    Action._unaryArith(inst, vm, OPERATION.LUA_OPUNM)
end

function Action.Bnot(inst, vm)
    Action._unaryArith(inst, vm, OPERATION.LUA_OPBNOT)
end

function Action.Eq(inst, vm)
    Action._compare(inst, vm, OPERATION.LUA_OPEQ)
end

function Action.Lt(inst, vm)
    Action._compare(inst, vm, OPERATION.LUA_OPLT)
end

function Action.Le(inst, vm)
    Action._compare(inst, vm, OPERATION.LUA_OPLE)
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
