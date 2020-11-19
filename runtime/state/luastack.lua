require("util/util")

LuaStack = {
    slots = nil,
    size = nil,
    capacity = nil, -- The maximum elements that slots can hold
}


function LuaStack:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.slots = o.slots or {}
    self.size = o.size or 0
    self.capacity = o.capacity or 0
    return o
end


function LuaStack:ensure(freenum)
    local currfree = self.capacity - self.size
    if currfree < freenum then
        self.capacity = self.capacity + (freenum - currfree)
    end
end


function LuaStack:get(idx)
    if not self:isValid(idx) then
        Util:panic("[LuaStack:get ERROR] Invalid index!")
    end
    local absIdx = self:absIndex(idx)
    return self.slots[absIdx]
end


function LuaStack:set(idx, val)
    if not self:isValid(idx) then
        Util:panic("[LuaStack:set ERROR] Invalid index!")
    end
    local absIdx = self:absIndex(idx)
    self.slots[absIdx] = val
end


function LuaStack:push(val)
    if self.size >= self.capacity then
        Util:panic("[LuaStack:push ERROR] Stack overflow!")
    end
    self.size = self.size + 1
    self.slots[self.size] = val
end


function LuaStack:pop()
    if self.size < 1 then
        Util:panic("[LuaStack:pop ERROR] Stack underflow!")
    end
    local val = nil
    if #self.slots >= self.size then
        val = table.remove(self.slots, self.size)
    end
    self.size = self.size - 1
    return val
end


function LuaStack:absIndex(idx)
    if idx < 0 then
        return self.size + idx + 1
    else
        return idx
    end
end


function LuaStack:isValid(idx)
    local absIdx = self:absIndex(idx)
    return absIdx >= 1 and absIdx <= self.size
end


function LuaStack:reverse(i, j)
    while i < j do
        local vali, valj = self.slots[i], self.slots[j]
        self.slots[i], self.slots[j] = valj, vali
        i = i + 1
        j = j - 1
    end
end
