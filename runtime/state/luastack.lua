local Util = require("common/util")

-- NOTE: Index start from 1 in Lua API

local LuaStack = {
    -- virtual stack
    slots = nil,
    _top = nil,
    -- call info
    closure = nil,
    varargs = nil,
    pc = nil,
    prev = nil,
}


function LuaStack:new(capacity)
    LuaStack.__index = LuaStack
    self = setmetatable({}, LuaStack)
    self.slots = {}
    for i = 1, capacity do
        self.slots[i] = self.slots
    end
    self._top = 0
    self.pc = 0
    return self
end


function LuaStack:gettop()
    return self._top
end


function LuaStack:settop(n)
    self._top = n
end


function LuaStack:ensure(freenum)
    for i = #self.slots + 1, self._top + freenum do
        self.slots[i] = self.slots
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
    if val == nil then
        self.slots[absIdx] = self.slots
    else
        self.slots[absIdx] = val
    end
end


function LuaStack:push(val)
    if self._top == #self.slots then
        Util:panic("[LuaStack:push ERROR] Stack overflow!")
    end
    self._top = self._top + 1
    if val == nil then
        self.slots[self._top] = self.slots
    else
        self.slots[self._top] = val
    end
end


function LuaStack:pushN(vals, n)
    if n < 0 then
        n = #vals
    end
    for i = 1, n do
        self:push(vals[i])
    end
end


function LuaStack:pop()
    if self._top < 1 then
        Util:panic("[LuaStack:pop ERROR] Stack underflow!")
    end
    local val = self.slots[self._top]
    self.slots[self._top] = self.slots
    self._top = self._top - 1
    if val == self.slots then
        return nil
    else
        return val
    end
end


function LuaStack:popN(n)
    local vals = {}
    for i = n, 1, -1 do
        vals[i] = self:pop()
    end
    return vals
end


function LuaStack:absIndex(idx)
    if idx < 0 then
        return self._top + idx + 1
    else
        return idx
    end
end


function LuaStack:isValid(idx)
    local absIdx = self:absIndex(idx)
    return absIdx >= 1 and absIdx <= self._top
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
