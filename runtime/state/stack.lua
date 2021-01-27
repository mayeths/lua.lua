local Util = require("common/util")

-- NOTE: Index start from 1 in Lua API

local Stack = {
    -- virtual stack
    slots = nil,
    _top = nil,
    -- call info
    closure = nil,
    varargs = nil,
    pc = nil,
    prev = nil,
}


function Stack:new(capacity)
    Stack.__index = Stack
    self = setmetatable({}, Stack)
    self.slots = {}
    for i = 1, capacity do
        self.slots[i] = self.slots
    end
    self._top = 0
    self.pc = 0
    return self
end


function Stack:gettop()
    return self._top
end


function Stack:settop(n)
    self._top = n
end


function Stack:ensure(freenum)
    for i = #self.slots + 1, self._top + freenum do
        self.slots[i] = self.slots
    end
end


function Stack:get(idx)
    if not self:isValid(idx) then
        Util:panic("[Stack:get ERROR] Invalid index!")
    end
    local absIdx = self:absIndex(idx)
    local val = self.slots[absIdx]
    if val == self.slots then
        return nil
    else
        return val
    end
end


function Stack:set(idx, val)
    if not self:isValid(idx) then
        Util:panic("[Stack:set ERROR] Invalid index!")
    end
    local absIdx = self:absIndex(idx)
    if val == nil then
        self.slots[absIdx] = self.slots
    else
        self.slots[absIdx] = val
    end
end


function Stack:push(val)
    if self._top == #self.slots then
        Util:panic("[Stack:push ERROR] Stack overflow!")
    end
    self._top = self._top + 1
    if val == nil then
        self.slots[self._top] = self.slots
    else
        self.slots[self._top] = val
    end
end


function Stack:pushN(vals, n)
    if n < 0 then
        n = #vals
    end
    for i = 1, n do
        self:push(vals[i])
    end
end


function Stack:pop()
    if self._top < 1 then
        Util:panic("[Stack:pop ERROR] Stack underflow!")
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


function Stack:popN(n)
    local vals = {}
    for i = n, 1, -1 do
        vals[i] = self:pop()
    end
    return vals
end


function Stack:absIndex(idx)
    if idx < 0 then
        return self._top + idx + 1
    else
        return idx
    end
end


function Stack:isValid(idx)
    local absIdx = self:absIndex(idx)
    return absIdx >= 1 and absIdx <= self._top
end


function Stack:reverse(i, j)
    while i < j do
        local vali, valj = self.slots[i], self.slots[j]
        self.slots[i], self.slots[j] = valj, vali
        i = i + 1
        j = j - 1
    end
end

return Stack