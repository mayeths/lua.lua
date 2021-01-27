local State = require("runtime/state/state")
require("unittest/lest")

SCENARIO("Testing runtime/state/state basic function", function ()

    GIVEN("a new State", function ()
        local state = nil

        SETUP(function ()
            state = State:new(20)
        end)

        IT_SHOULD("return an empty lua state correctly", function ()
            EXPECT(state:GetTop()).TOEQUAL(0)
        end)

        IT_SHOULD("push a nil value correctly", function ()
            state:PushNil()
            local top = state:GetTop()
            EXPECT(top).TOEQUAL(1)
            EXPECT(state:IsNil(top)).TOEQUAL(true)
        end)

        IT_SHOULD("push a boolean value correctly", function ()
            state:PushBoolean(true)
            local top = state:GetTop()
            EXPECT(top).TOEQUAL(1)
            EXPECT(state:ToBoolean(top)).TOEQUAL(true)
            state:PushBoolean(false)
            top = state:GetTop()
            EXPECT(top).TOEQUAL(2)
            EXPECT(state:ToBoolean(top)).TOEQUAL(false)
        end)

        IT_SHOULD("push a integer correctly", function ()
            state:PushInteger(100)
            local top = state:GetTop()
            EXPECT(top).TOEQUAL(1)
            EXPECT(state:IsInteger(top)).TOEQUAL(true)
            EXPECT(state:ToInteger(top)).TOEQUAL(100)
        end)

        IT_SHOULD("push a number correctly", function ()
            state:PushNumber(4.123)
            local top = state:GetTop()
            EXPECT(top).TOEQUAL(1)
            EXPECT(state:IsNumber(top)).TOEQUAL(true)
            EXPECT(state:ToNumber(top)).TOEQUAL(4.123)
        end)

        IT_SHOULD("push a string correctly", function ()
            state:PushString("xyz123")
            local top = state:GetTop()
            EXPECT(state:IsString(top)).TOEQUAL(true)
            EXPECT(state:ToString(top)).TOEQUAL("xyz123")
        end)

    end)

end)


