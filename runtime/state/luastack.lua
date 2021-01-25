local Util = require("common/util")

-- NOTE: Index start from 1 in Lua API

local LuaStack = {
    slots = nil,
    _capacity = nil,
}


function LuaStack:new(capacity)
    LuaStack.__index = LuaStack
    self = setmetatable({}, LuaStack)
    self.slots = {}
    self._capacity = capacity
    return self
end


function LuaStack:size()
    return #self.slots
end


function LuaStack:capacity()
    return self._capacity
end


function LuaStack:ensure(freenum)
    local currfree = self._capacity - #self.slots
    local needmore = freenum - currfree
    if needmore > 0 then
        self._capacity = self._capacity + needmore
    end
end


function LuaStack:get(idx)
    if not self:isValid(idx) then
        Util:panic("[LuaStack:get ERROR] Invalid index!")
    end
    local absIdx = self:absIndex(idx)
    local val = self.slots[absIdx]
    if val == self.slots then
        return nil
    else
        return val
    end
end


function LuaStack:set(idx, val)
    if not self:isValid(idx) then
        Util:panic("[LuaStack:set ERROR] Invalid index!")
    end
    local absIdx = self:absIndex(idx)
    self.slots[absIdx] = val
end


function LuaStack:push(val)
    if #self.slots >= self._capacity then
        Util:panic("[LuaStack:push ERROR] Stack overflow!")
    end
    self.slots[#self.slots + 1] = val or self.slots
end


function LuaStack:pop()
    if #self.slots < 1 then
        Util:panic("[LuaStack:pop ERROR] Stack underflow!")
    end
    local val = table.remove(self.slots)
    if val == self.slots then
        return nil
    else
        return val
    end
end


function LuaStack:absIndex(idx)
    if idx < 0 then
        return #self.slots + idx + 1
    else
        return idx
    end
end


function LuaStack:isValid(idx)
    local absIdx = self:absIndex(idx)
    return absIdx >= 1 and absIdx <= #self.slots
end


function LuaStack:reverse(i, j)
    while i < j do
        local vali, valj = self.slots[i], self.slots[j]
        self.slots[i], self.slots[j] = valj, vali
        i = i + 1
        j = j - 1
    end
end

return LuaStack
