local LuaStack = require("runtime/state/luastack")
local LuaType = require("runtime/state/luatype")
local Util = require("common/util")

local LuaState = {
    stack = nil,
}


function LuaState:new()
    LuaState.__index = LuaState
    self = setmetatable({}, LuaState)
    self.stack = LuaStack:new(20)
    return self
end


function LuaState:GetTop()
    return self.stack:gettop()
end


function LuaState:AbsIndex(idx)
    return self.stack:absIndex(idx)
end


function LuaState:CheckStack(freenum)
    self.stack:ensure(freenum)
    return true
end


function LuaState:Pop(n)
    for _ = 1, n do
        self.stack:pop()
    end
end


function LuaState:Copy(fromIdx, toIdx)
    local val = self.stack:get(fromIdx)
    self.stack:set(toIdx, val)
end


function LuaState:PushValue(idx)
    local val = self.stack:get(idx)
    self.stack:push(val)
end


function LuaState:Replace(idx)
    local val = self.stack:pop()
    self.stack:set(idx, val)
end


function LuaState:Insert(idx)
    self:Rotate(idx, 1)
end


function LuaState:Remove(idx)
    self:Rotate(idx, -1)
    self:Pop(1)
end

-- What does lua_rotate do?
-- https://stackoverflow.com/a/52241763
function LuaState:Rotate(idx, n)
    local t3 = self:GetTop()
    local t1 = self:AbsIndex(idx)
    local t2
    if n >= 0 then
        t2 = t3 - n
    else
        t2 = t1 - n - 1
    end
    self.stack:reverse(t1, t2)
    self.stack:reverse(t2 + 1, t3)
    self.stack:reverse(t1, t3)
end


function LuaState:SetTop(idx)
    local newTop = self:AbsIndex(idx)
    if newTop < 0 then
        Util:panic("[LuaState:SetTop ERROR] Stack underflow!")
    end
    local operateSlotNum = newTop - self:GetTop()
    if operateSlotNum < 0 then
        for _ = 1, -operateSlotNum do
            self.stack:pop()
        end
    elseif operateSlotNum > 0 then
        for _ = 1, operateSlotNum do
            self.stack:push(nil)
        end
    end
end




function LuaState:pushLuaStack(stack)
    stack.prev = self.stack
    self.stack = stack
end


function LuaState:popLuaStack()
    local stack = self.stack
    self.stack = stack.prev
    stack.prev = nil
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
        else
            Util:printf("[%s]", self:TypeName(t))
        end
    end
    Util:println("")
end

return LuaState
