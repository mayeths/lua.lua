require("runtime/state/state")
require("runtime/state/luaoperation")
require("util/util")


LLUA = {}


function LLUA:main()
    local state = LuaState:new()
    state:PushInteger(1)
    state:PushString("2.0")
    state:PushString("3.0")
    state:PushNumber(4.0)
    LLUA:printStack(state)
    state:Arith(LuaOperation.LUA_OPADD)
    LLUA:printStack(state)
    state:Arith(LuaOperation.LUA_OPBNOT)
    LLUA:printStack(state)
    state:Len(2)
    LLUA:printStack(state)
    state:Concat(3)
    LLUA:printStack(state)
    state:PushBoolean(state:Compare(1, 2, LuaOperation.LUA_OPEQ))
    LLUA:printStack(state)
end


function LLUA:printStack(ls)
    local top = ls:GetTop()
    for i = 1, top do
        local t = ls:Type(i)
        if t == LuaType.LUA_TBOOLEAN then
            Util:printf("[%s]", tostring(ls:ToBoolean(i)))
        elseif t == LuaType.LUA_TNUMBER then
            Util:printf("[%s]", tostring(ls:ToNumber(i)))
        elseif t == LuaType.LUA_TNIL then
            Util:printf("[%s]", "nil")
        elseif t == LuaType.LUA_TSTRING then
            Util:printf('["%s"]', ls:ToString(i))
        end
    end
    Util:println("")
end


LLUA:main()
