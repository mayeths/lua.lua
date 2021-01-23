require("runtime/state/luastack")
require("runtime/state/luatype")
require("common/util")
LuaState = {
    stack = nil,
}


function LuaState:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.stack = o.stack or LuaStack:new({ capacity = 20 })
    return o
end


function LuaState:printStack()
    local top = self:GetTop()
    for i = 1, top do
        local t = self:Type(i)
        if t == LuaType.LUA_TBOOLEAN then
            Util:printf("[%s]", tostring(self:ToBoolean(i)))
        elseif t == LuaType.LUA_TNUMBER then
            Util:printf("[%s]", tostring(self:ToNumber(i)))
        elseif t == LuaType.LUA_TNIL then
            Util:printf("[%s]", "nil")
        elseif t == LuaType.LUA_TSTRING then
            Util:printf('["%s"]', self:ToString(i))
        end
    end
    Util:println("")
end
