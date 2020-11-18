require("runtime/state/state")
require("util/util")


LLUA = {}


function LLUA:main()
    local ls = LuaState:new()
    ls:PushBoolean(true)
    LLUA:printStack(ls)
    ls:PushInteger(10)
    LLUA:printStack(ls)
    ls:PushNil()
    LLUA:printStack(ls)
    ls:PushString("hello")
    LLUA:printStack(ls)
    ls:PushValue(-4)
    LLUA:printStack(ls)
    ls:Replace(3)
    LLUA:printStack(ls)
    ls:SetTop(6)
    LLUA:printStack(ls)
    ls:Remove(-3)
    LLUA:printStack(ls)
    ls:SetTop(-5)
    LLUA:printStack(ls)
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
