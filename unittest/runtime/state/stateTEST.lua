require("unittest/lest")
local STACK = require("lua/stack")
local OPERATION = require("lua/operation")
local State = require("runtime/state/state")

SCENARIO("Testing runtime/state/state basic function", function ()

    GIVEN("a new State", function ()
        local state = nil

        SETUP(function ()
            state = State:new()
        end)


        IT_SHOULD("GetTop() correctly", function ()
            EXPECT(state:GetTop()).TOEQUAL(0)
        end)


        IT_SHOULD("AbsIndex() correctly", function ()
            EXPECT(state:AbsIndex(0)).TOEQUAL(0)
            EXPECT(state:AbsIndex(1)).TOEQUAL(1)
            EXPECT(state:AbsIndex(2)).TOEQUAL(2)
            EXPECT(state:AbsIndex(-1)).TOEQUAL(0)
            state:PushNil()
            EXPECT(state:AbsIndex(-1)).TOEQUAL(1)
            state:PushNil()
            EXPECT(state:AbsIndex(-1)).TOEQUAL(2)
            EXPECT(state:AbsIndex(STACK.LUA_REGISTRYINDEX)).TOEQUAL(STACK.LUA_REGISTRYINDEX)
            EXPECT(state:AbsIndex(STACK.LUA_REGISTRYINDEX - 1))
                .TOEQUAL(STACK.LUA_REGISTRYINDEX - 1)
        end)


        IT_SHOULD("CheckStack() correctly", function ()
            EXPECT(true).TOEQUAL(true)
        end)


        IT_SHOULD("Pop() correctly", function ()
            EXPECT(state:GetTop()).TOEQUAL(0)
            state:PushNil()
            EXPECT(state:GetTop()).TOEQUAL(1)
            state:Pop(1)
            EXPECT(state:GetTop()).TOEQUAL(0)
        end)


        IT_SHOULD("PushNil() correctly", function ()
            state:PushNil()
            local top = state:GetTop()
            EXPECT(top).TOEQUAL(1)
            EXPECT(state:IsNil(top)).TOEQUAL(true)
        end)

        IT_SHOULD("Copy() correctly", function ()
            state:PushNil()
            state:PushString("hello")
            EXPECT(state:IsNil(1)).TOEQUAL(true)
            EXPECT(state:ToString(2)).TOEQUAL("hello")
            state:Copy(2, 1)
            EXPECT(state:GetTop()).TOEQUAL(2)
            EXPECT(state:ToString(2)).TOEQUAL("hello")
            EXPECT(state:ToString(1)).TOEQUAL("hello")
        end)

        IT_SHOULD("PushValue() correctly", function ()
            state:PushString("hello")
            EXPECT(state:GetTop()).TOEQUAL(1)
            EXPECT(state:ToString(1)).TOEQUAL("hello")
            state:PushValue(1)
            EXPECT(state:GetTop()).TOEQUAL(2)
            EXPECT(state:ToString(2)).TOEQUAL("hello")
        end)


        IT_SHOULD("Replace() correctly", function ()
            state:PushNil()
            state:PushString("hello")
            EXPECT(state:IsNil(1)).TOEQUAL(true)
            EXPECT(state:ToString(2)).TOEQUAL("hello")
            state:Replace(1)
            EXPECT(state:GetTop()).TOEQUAL(1)
            EXPECT(state:ToString(1)).TOEQUAL("hello")
        end)


        IT_SHOULD("Insert() correctly", function ()
            state:PushInteger(123)
            state:PushString("hello")
            EXPECT(state:ToInteger(1)).TOEQUAL(123)
            EXPECT(state:ToString(2)).TOEQUAL("hello")
            state:Insert(1)
            EXPECT(state:ToString(1)).TOEQUAL("hello")
            EXPECT(state:ToInteger(2)).TOEQUAL(123)
        end)


        IT_SHOULD("Remove() correctly", function ()
            state:PushInteger(123)
            state:PushString("hello")
            EXPECT(state:GetTop()).TOEQUAL(2)
            EXPECT(state:ToInteger(1)).TOEQUAL(123)
            EXPECT(state:ToString(2)).TOEQUAL("hello")
            state:Remove(1)
            EXPECT(state:GetTop()).TOEQUAL(1)
            EXPECT(state:ToString(1)).TOEQUAL("hello")
        end)


        IT_SHOULD("Rotate() correctly", function ()
            state:PushBoolean(true)
            state:PushBoolean(false)
            state:PushInteger(123)
            state:PushInteger(456)
            state:PushNumber(100.1)
            state:PushNumber(200.2)
            state:PushString("hello")
            EXPECT(state:GetTop()).TOEQUAL(7)
            state:Rotate(3, 2)
            EXPECT(state:ToBoolean(1)).TOEQUAL(true)
            EXPECT(state:ToBoolean(2)).TOEQUAL(false)
            EXPECT(state:ToNumber(3)).TOEQUAL(200.2)
            EXPECT(state:ToString(4)).TOEQUAL("hello")
            EXPECT(state:ToInteger(5)).TOEQUAL(123)
            EXPECT(state:ToInteger(6)).TOEQUAL(456)
            EXPECT(state:ToNumber(7)).TOEQUAL(100.1)
            state:Rotate(3, -4)
            EXPECT(state:ToBoolean(1)).TOEQUAL(true)
            EXPECT(state:ToBoolean(2)).TOEQUAL(false)
            EXPECT(state:ToNumber(3)).TOEQUAL(100.1)
            EXPECT(state:ToNumber(4)).TOEQUAL(200.2)
            EXPECT(state:ToString(5)).TOEQUAL("hello")
            EXPECT(state:ToInteger(6)).TOEQUAL(123)
            EXPECT(state:ToInteger(7)).TOEQUAL(456)
        end)


        IT_SHOULD("SetTop() correctly", function ()
            EXPECT(state:GetTop()).TOEQUAL(0)
            state:SetTop(3)
            EXPECT(state:GetTop()).TOEQUAL(3)
            EXPECT(state:IsNil(1)).TOEQUAL(true)
            EXPECT(state:IsNil(2)).TOEQUAL(true)
            EXPECT(state:IsNil(3)).TOEQUAL(true)
            state:SetTop(1)
            EXPECT(state:GetTop()).TOEQUAL(1)
            EXPECT(state:IsNil(1)).TOEQUAL(true)
        end)


        IT_SHOULD("Arith() correctly", function ()

            state:PushInteger(123)
            state:PushInteger(456)
            state:Arith(OPERATION.LUA_OPADD)
            EXPECT(state:ToInteger(-1)).TOEQUAL(123 + 456)
            state:PushNumber(123.0)
            state:PushNumber(456.0)
            state:Arith(OPERATION.LUA_OPADD)
            EXPECT(state:ToNumber(-1)).TOEQUAL(123.0 + 456.0)

            state:PushInteger(123)
            state:PushInteger(456)
            state:Arith(OPERATION.LUA_OPSUB)
            EXPECT(state:ToInteger(-1)).TOEQUAL(123 - 456)
            state:PushNumber(123.0)
            state:PushNumber(456.0)
            state:Arith(OPERATION.LUA_OPSUB)
            EXPECT(state:ToNumber(-1)).TOEQUAL(123.0 - 456.0)

            state:PushInteger(123)
            state:PushInteger(456)
            state:Arith(OPERATION.LUA_OPMUL)
            EXPECT(state:ToInteger(-1)).TOEQUAL(123 * 456)
            state:PushNumber(123.0)
            state:PushNumber(456.0)
            state:Arith(OPERATION.LUA_OPMUL)
            EXPECT(state:ToNumber(-1)).TOEQUAL(123.0 * 456.0)

            state:PushInteger(123)
            state:PushInteger(456)
            state:Arith(OPERATION.LUA_OPMOD)
            EXPECT(state:ToInteger(-1)).TOEQUAL(123 % 456)
            state:PushNumber(123.0)
            state:PushNumber(456.0)
            state:Arith(OPERATION.LUA_OPMOD)
            EXPECT(state:ToNumber(-1)).TOEQUAL(123.0 % 456.0)

            state:PushNumber(123.0)
            state:PushNumber(4.0)
            state:Arith(OPERATION.LUA_OPPOW)
            EXPECT(state:ToNumber(-1)).TOEQUAL(123.0 ^ 4.0)

            state:PushNumber(123.0)
            state:PushNumber(456.0)
            state:Arith(OPERATION.LUA_OPDIV)
            EXPECT(state:ToNumber(-1)).TOEQUAL(123.0 / 456.0)

            state:PushInteger(456)
            state:PushInteger(123)
            state:Arith(OPERATION.LUA_OPIDIV)
            EXPECT(state:ToInteger(-1)).TOEQUAL(456 // 123)
            state:PushNumber(456.0)
            state:PushNumber(123.0)
            state:Arith(OPERATION.LUA_OPIDIV)
            EXPECT(state:ToNumber(-1)).TOEQUAL(456.0 // 123.0)

            state:PushInteger(456)
            state:PushInteger(123)
            state:Arith(OPERATION.LUA_OPBAND)
            EXPECT(state:ToInteger(-1)).TOEQUAL(456 & 123)

            state:PushInteger(456)
            state:PushInteger(123)
            state:Arith(OPERATION.LUA_OPBOR)
            EXPECT(state:ToInteger(-1)).TOEQUAL(456 | 123)

            state:PushInteger(456)
            state:PushInteger(123)
            state:Arith(OPERATION.LUA_OPBXOR)
            EXPECT(state:ToInteger(-1)).TOEQUAL(456 ~ 123)

            state:PushInteger(456)
            state:PushInteger(2)
            state:Arith(OPERATION.LUA_OPSHL)
            EXPECT(state:ToInteger(-1)).TOEQUAL(456 << 2)

            state:PushInteger(456)
            state:PushInteger(2)
            state:Arith(OPERATION.LUA_OPSHR)
            EXPECT(state:ToInteger(-1)).TOEQUAL(456 >> 2)

            state:PushInteger(123)
            state:Arith(OPERATION.LUA_OPUNM)
            EXPECT(state:ToInteger(-1)).TOEQUAL(-123)
            state:PushNumber(123.0)
            state:Arith(OPERATION.LUA_OPUNM)
            EXPECT(state:ToNumber(-1)).TOEQUAL(-123.0)

            state:PushInteger(123)
            state:Arith(OPERATION.LUA_OPBNOT)
            EXPECT(state:ToInteger(-1)).TOEQUAL(~123)

            EXPECT(state:GetTop()).TOEQUAL(20)

        end)


        IT_SHOULD("Compare() correctly", function ()
            state:PushBoolean(true)
            state:PushBoolean(false)
            state:PushInteger(123)
            state:PushInteger(456)
            state:PushString("hello")
            state:PushString("world")
            EXPECT(state:Compare(1, 2, OPERATION.LUA_OPEQ)).TOEQUAL(false)
            EXPECT(function()
                state:Compare(1, 2, OPERATION.LUA_OPLE)
            end).TOTHROW()
            EXPECT(function()
                state:Compare(1, 2, OPERATION.LUA_OPLT)
            end).TOTHROW()
            EXPECT(state:Compare(3, 4, OPERATION.LUA_OPEQ)).TOEQUAL(false)
            EXPECT(state:Compare(3, 4, OPERATION.LUA_OPLE)).TOEQUAL(true)
            EXPECT(state:Compare(3, 4, OPERATION.LUA_OPLT)).TOEQUAL(true)
            EXPECT(state:Compare(5, 6, OPERATION.LUA_OPEQ)).TOEQUAL(false)
            EXPECT(state:Compare(5, 6, OPERATION.LUA_OPLE)).TOEQUAL(true)
            EXPECT(state:Compare(5, 6, OPERATION.LUA_OPLT)).TOEQUAL(true)
            EXPECT(state:Compare(1, 6, OPERATION.LUA_OPEQ)).TOEQUAL(false)
        end)


        IT_SHOULD("Len() correctly", function ()
            state:PushString("hello")
            state:Len(1)
            EXPECT(state:ToInteger(2)).TOEQUAL(5)
            state:NewTable()
            EXPECT(state:GetTop()).TOEQUAL(3)
            state:PushString("first field")
            state:SetI(3, 1)
            state:Len(3)
            EXPECT(state:GetTop()).TOEQUAL(4)
            EXPECT(state:ToInteger(4)).TOEQUAL(1)
            state:PushString("second field")
            state:SetI(3, 2)
            state:Len(3)
            EXPECT(state:GetTop()).TOEQUAL(5)
            EXPECT(state:ToInteger(5)).TOEQUAL(2)
            state:PushNumber(1.23)
            EXPECT(function ()
                state:Len(6)
            end).TOTHROW()
        end)


        IT_SHOULD("Concat() correctly", function ()
            EXPECT(state:GetTop()).TOEQUAL(0)
            state:Concat(0)
            EXPECT(state:GetTop()).TOEQUAL(1)
            state:PushString("hello")
            EXPECT(state:GetTop()).TOEQUAL(2)
            state:Concat(1)
            EXPECT(state:GetTop()).TOEQUAL(2)
            state:PushString(",world")
            state:Concat(2)
            EXPECT(state:GetTop()).TOEQUAL(2)
            EXPECT(state:ToString(2)).TOEQUAL("hello,world")
            state:PushNumber(1.23)
            state:Concat(2)
            EXPECT(state:GetTop()).TOEQUAL(2)
            EXPECT(state:ToString(2)).TOEQUAL("hello,world1.23")
            state:PushBoolean(true)
            EXPECT(function ()
                state:Concat(2)
            end).TOTHROW()
            state:PushString("s1")
            state:PushString("s2")
            state:PushString("s3")
            EXPECT(state:GetTop()).TOEQUAL(6)
            state:Concat(3)
            EXPECT(state:ToString(4)).TOEQUAL("s1s2s3")
        end)


        IT_SHOULD("PushBoolean() correctly", function ()
            state:PushBoolean(true)
            local top = state:GetTop()
            EXPECT(top).TOEQUAL(1)
            EXPECT(state:ToBoolean(top)).TOEQUAL(true)
            state:PushBoolean(false)
            top = state:GetTop()
            EXPECT(top).TOEQUAL(2)
            EXPECT(state:ToBoolean(top)).TOEQUAL(false)
        end)

        IT_SHOULD("PushInteger() correctly", function ()
            state:PushInteger(100)
            local top = state:GetTop()
            EXPECT(top).TOEQUAL(1)
            EXPECT(state:IsInteger(top)).TOEQUAL(true)
            EXPECT(state:ToInteger(top)).TOEQUAL(100)
        end)

        IT_SHOULD("PushNumber() correctly", function ()
            state:PushNumber(4.123)
            local top = state:GetTop()
            EXPECT(top).TOEQUAL(1)
            EXPECT(state:IsNumber(top)).TOEQUAL(true)
            EXPECT(state:ToNumber(top)).TOEQUAL(4.123)
        end)

        IT_SHOULD("PushString() correctly", function ()
            state:PushString("xyz123")
            local top = state:GetTop()
            EXPECT(state:IsString(top)).TOEQUAL(true)
            EXPECT(state:ToString(top)).TOEQUAL("xyz123")
        end)

    end)

end)


