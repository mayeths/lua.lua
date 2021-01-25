local LuaStack = require("runtime/state/luastack")
local LuaType = require("runtime/state/luatype")
local Util = require("common/util")

local LuaState = {
    stack = nil,
}


function LuaState:new(capacity)
    LuaState.__index = LuaState
    self = setmetatable({}, LuaState)
    self.__index = self
    self.stack = LuaStack:new(20)
    return self
end


function LuaState:printStack()
    local top = self:GetTop()
    for i = 1, top do
        local t = self:Type(i)
        if t == LuaType.LUA_TBOOLEAN then
            Util:printf("[%s]", tostring(self:ToBoolean(i)))
        elseif t == LuaType.LUA_TNUMBER then
            if self:IsInteger(i) then
                Util:printf("[%s]", tostring(self:ToInteger(i)))
            else
                Util:printf("[%s]", tostring(self:ToNumber(i)))
            end
        elseif t == LuaType.LUA_TNIL then
            Util:printf("[%s]", "nil")
        elseif t == LuaType.LUA_TSTRING then
            Util:printf('["%s"]', self:ToString(i))
        end
    end
    Util:println("")
end

return LuaState
