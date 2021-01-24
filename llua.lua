local LuaState = require("runtime/state/state")
local LuaOperation = require("runtime/state/luaoperation")
local Util = require("common/util")


LLUA = {}


function LLUA:main()
    local state = LuaState:new()
    state:PushInteger(1)
    state:PushString("2.0")
    state:PushString("3.0")
    state:PushNumber(4.0)
    state:printStack()
    state:Arith(LuaOperation.LUA_OPADD)
    state:printStack()
    state:Arith(LuaOperation.LUA_OPBNOT)
    state:printStack()
    state:Len(2)
    state:printStack()
    state:Concat(3)
    state:printStack()
    state:PushBoolean(state:Compare(1, 2, LuaOperation.LUA_OPEQ))
    state:printStack()
end


LLUA:main()
