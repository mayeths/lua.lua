require("runtime/state/state")
require("runtime/util/util")


Main = {}


function Main:main()
    local ls = LuaState:new()
    ls:PushBoolean(true)
    Main:printStack(ls)
    ls:PushInteger(10)
    Main:printStack(ls)
    ls:PushNil()
    Main:printStack(ls)
    ls:PushString("hello")
    Main:printStack(ls)
    ls:PushValue(-4)
    Main:printStack(ls)
    ls:Replace(3)
    Main:printStack(ls)
    ls:SetTop(6)
    Main:printStack(ls)
    ls:Remove(-3)
    Main:printStack(ls)
    ls:SetTop(-5)
    Main:printStack(ls)
end


function Main:printStack(ls)
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


Main:main()
