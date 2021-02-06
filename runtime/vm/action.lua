local OPERATION = require("lua/operation")
local TYPE = require("lua/type")
local STACK = require("lua/stack")
local Util = require("common/util")
local Throw = require("common/throw")

local Action = {}


function Action.LoadNil(inst, state)
    local a, b, _ = inst:ABC()
    a = a + 1
    state:PushNil()
    for i = a, a + b do
        state:Copy(-1, i)
    end
    state:Pop(1)
end

function Action.LoadBool(inst, state)
    local a, b, c = inst:ABC()
    a = a + 1
    state:PushBoolean(b ~= 0)
    state:Replace(a)
    if c ~= 0 then
        state:AddPC(1)
    end
end

function Action.LoadK(inst, state)
    local a, bx = inst:ABx()
    a = a + 1
    state:GetConst(bx)
    state:Replace(a)
end

function Action.LoadKx(inst, state)
    local a, _ = inst:ABx()
    a = a + 1
    local ax = state:Fetch() >> 6
    state:GetConst(ax)
    state:Replace(a)
end

function Action.ForPrep(inst, state)
    local a, sBx = inst:AsBx()
    a = a + 1
    if state:Type(a) == TYPE.LUA_TSTRING then
        state:PushNumber(state:ToNumber(a))
        state:Replace(a)
    end
    if state:Type(a + 1) == TYPE.LUA_TSTRING then
        state:PushNumber(state:ToNumber(a + 1))
        state:Replace(a + 1)
    end
    if state:Type(a + 2) == TYPE.LUA_TSTRING then
        state:PushNumber(state:ToNumber(a + 2))
        state:Replace(a + 2)
    end
    state:PushValue(a)
    state:PushValue(a + 2)
    state:Arith(OPERATION.LUA_OPSUB)
    state:Replace(a)
    state:AddPC(sBx)
end

function Action.ForLoop(inst, state)
    local a, sBx = inst:AsBx()
    a = a + 1
    state:PushValue(a + 2)
    state:PushValue(a)
    state:Arith(OPERATION.LUA_OPADD)
    state:Replace(a)
    local isPositiveStep = state:ToNumber(a + 2) >= 0
    if isPositiveStep and state:Compare(a, a + 1, OPERATION.LUA_OPLE) or not isPositiveStep and state:Compare(a + 1, a, OPERATION.LUA_OPLE) then
        state:AddPC(sBx)
        state:Copy(a, a + 3)
    end
end

function Action.Move(inst, state)
    local a, b, _ = inst:ABC()
    state:Copy(b + 1, a + 1)
end

function Action.Jmp(inst, state)
    local a, sBx = inst:AsBx()
    state:AddPC(sBx)
    if a ~= 0 then
        state:CloseUpvalues(a)
        Throw:error("todo: jmp!")
    end
end

function Action.No(inst, state)
    local a, b, _ = inst:ABC()
    a = a + 1
    b = b + 1
    state:PushBoolean(not state:ToBoolean(b))
    state:Replace(a)
end

function Action.Test(inst, state)
    local a, _, c = inst:ABC()
    a = a + 1
    if state:ToBoolean(a) ~= (c ~= 0) then
        state:AddPC(1)
    end
end

function Action.TestSet(inst, state)
    local a, b, c = inst:ABC()
    a = a + 1
    b = b + 1
    if state:ToBoolean(b) == (c ~= 0) then
        state:Copy(b, a)
    else
        state:AddPC(1)
    end
end

function Action.Length(inst, state)
    local a, b, _ = inst:ABC()
    a = a + 1
    b = b + 1
    state:Len(b)
    state:Replace(a)
end

function Action.Concat(inst, state)
    local a, b, c = inst:ABC()
    a = a + 1
    b = b + 1
    c = c + 1
    local n = c - b + 1
    state:CheckStack(n)
    for i = b, c do
        state:PushValue(i)
    end
    state:Concat(n)
    state:Replace(a)
end

function Action.NewTable(inst, state)
    local a, b, c = inst:ABC()
    a = a + 1
    state:CreateTable(Action._fb2int(b), Action._fb2int(c))
    state:Replace(a)
end

function Action.GetTable(inst, state)
    local a, b, c = inst:ABC()
    a = a + 1
    b = b + 1
    state:GetRK(c)
    state:GetTable(b)
    state:Replace(a)
end

function Action.SetTable(inst, state)
    local a, b, c = inst:ABC()
    a = a + 1
    state:GetRK(b)
    state:GetRK(c)
    state:SetTable(a)
end

function Action.SetList(inst, state)
    local a, b, c = inst:ABC()
    a = a + 1
    if c > 0 then
        c = c - 1
    else
        c = (state:Fetch() >> 6)
    end
    local b0 = b == 0
    if b0 then
        b = state:ToInteger(-1) - a - 1
        state:Pop(1)
    end
    state:CheckStack(1)
    local idx = c * 50
    for i = 1, b do
        idx = idx + 1
        state:PushValue(a + i)
        state:SetI(a, idx)
    end
    if b0 then
        for i = state:RegisterCount() + 1, state:GetTop() do
            idx = idx + 1
            state:PushValue(i)
            state:SetI(a, idx)
        end
        state:SetTop(state:RegisterCount())
    end
end

function Action.Self(inst, state)
    local a, b, c = inst:ABC()
    a = a + 1
    b = b + 1
    state:Copy(b, a + 1)
    state:GetRK(c)
    state:GetTable(b)
    state:Replace(a)
end

function Action.Closure(inst, state)
    local a, bx = inst:ABx()
    a = a + 1
    state:LoadProto(bx + 1)
    state:Replace(a)
end

function Action.Vararg(inst, state)
    local a, b, _ = inst:ABC()
    a = a + 1
    if b ~= 1 then
        state:LoadVararg(b - 1)
        Action._popResults(a, b, state)
    end
end

function Action.TailCall(inst, state)
    local a, b, _ = inst:ABC()
    a = a + 1
    local c = 0
    local nargs = Action._pushFuncAndArgs(a, b, state)
    state:Call(nargs, c - 1)
    Action._popResults(a, c, state)
end

function Action.Call(inst, state)
    local a, b, c = inst:ABC()
    a = a + 1
    local nargs = Action._pushFuncAndArgs(a, b, state)
    state:Call(nargs, c - 1)
    Action._popResults(a, c, state)
end

function Action.GetTabUp(inst, state)
    local a, b, c = inst:ABC()
    a = a + 1
    b = b + 1
    state:GetRK(c)
    state:GetTable(STACK.LUA_REGISTRYINDEX - b)
    state:Replace(a)
end

function Action.SetTabUp(inst, state)
    local a, b, c = inst:ABC()
    a = a + 1
    state:GetRK(b)
    state:GetRK(c)
    state:SetTable(STACK.LUA_REGISTRYINDEX - a)
end


function Action.GetUpval(inst, state)
    local a, b, _ = inst:ABC()
    a = a + 1
    b = b + 1
    state:Copy(STACK.LUA_REGISTRYINDEX - b, a)
end


function Action.SetUpval(inst, state)
    local a, b, _ = inst:ABC()
    a = a + 1
    b = b + 1
    state:Copy(a, STACK.LUA_REGISTRYINDEX - b)
end

function Action.Add(inst, state)
    Action._binaryArith(inst, state, OPERATION.LUA_OPADD)
end

function Action.Sub(inst, state)
    Action._binaryArith(inst, state, OPERATION.LUA_OPSUB)
end

function Action.Mul(inst, state)
    Action._binaryArith(inst, state, OPERATION.LUA_OPMUL)
end

function Action.Mod(inst, state)
    Action._binaryArith(inst, state, OPERATION.LUA_OPMOD)
end

function Action.Pow(inst, state)
    Action._binaryArith(inst, state, OPERATION.LUA_OPPOW)
end

function Action.Div(inst, state)
    Action._binaryArith(inst, state, OPERATION.LUA_OPDIV)
end

function Action.Idiv(inst, state)
    Action._binaryArith(inst, state, OPERATION.LUA_OPIDIV)
end

function Action.Band(inst, state)
    Action._binaryArith(inst, state, OPERATION.LUA_OPBAND)
end

function Action.Bor(inst, state)
    Action._binaryArith(inst, state, OPERATION.LUA_OPBOR)
end

function Action.Bxor(inst, state)
    Action._binaryArith(inst, state, OPERATION.LUA_OPBXOR)
end

function Action.Shl(inst, state)
    Action._binaryArith(inst, state, OPERATION.LUA_OPSHL)
end

function Action.Shr(inst, state)
    Action._binaryArith(inst, state, OPERATION.LUA_OPSHR)
end

function Action.Unm(inst, state)
    Action._unaryArith(inst, state, OPERATION.LUA_OPUNM)
end

function Action.Bnot(inst, state)
    Action._unaryArith(inst, state, OPERATION.LUA_OPBNOT)
end

function Action.Eq(inst, state)
    Action._compare(inst, state, OPERATION.LUA_OPEQ)
end

function Action.Lt(inst, state)
    Action._compare(inst, state, OPERATION.LUA_OPLT)
end

function Action.Le(inst, state)
    Action._compare(inst, state, OPERATION.LUA_OPLE)
end


function Action._binaryArith(inst, state, op)
    local a, b, c = inst:ABC()
    a = a + 1
    state:GetRK(b)
    state:GetRK(c)
    state:Arith(op)
    state:Replace(a)
end

function Action._unaryArith(inst, state, op)
    local a, b, _ = inst:ABC()
    a = a + 1
    b = b + 1
    state:PushValue(b)
    state:Arith(op)
    state:Replace(a)
end

function Action._compare(inst, state, op)
    local a, b, c = inst:ABC()
    state:GetRK(b)
    state:GetRK(c)
    if state:Compare(-2, -1, op) ~= (a ~= 0) then
        state:AddPC(1)
    end
    state:Pop(2)
end

function Action._fb2int(x)
    if x < 8 then
        return x
    else
        return ((x & 7) + 8) << ((x >> 3) - 1)
    end
end

function Action._pushFuncAndArgs(a, b, state)
    if b >= 1 then
        state:CheckStack(b)
        for i = a, a + b - 1 do
            state:PushValue(i)
        end
        return b - 1
    else
        Action._fixStack(a, state)
        return state:GetTop() - state:RegisterCount() - 1
    end
end

function Action._fixStack(a, state)
    local x = state:ToInteger(-1)
    state:Pop(1)
    state:CheckStack(x - a)
    for i = a, x - 1 do
        state:PushValue(i)
    end
    state:Rotate(state:RegisterCount() + 1, x - a)
end

function Action._popResults(a, c, state)
    if c == 1 then
        --
    elseif c > 1 then
        for i = a + c - 2, a, -1 do
            state:Replace(i)
        end
    else
        state:CheckStack(1)
        state:PushInteger(a)
    end
end

function Action._return(inst, state)
    local a, b, _ = inst:ABC()
    a = a + 1
    if b == 1 then
        --
    elseif b > 1 then
        state:CheckStack(b - 1)
        for i = a, a + b - 2 do
            state:PushValue(i)
        end
    else
        Action._fixStack(a, state)
    end
end

return Action
