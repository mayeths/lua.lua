local STACK = require("lua/stack")
local Throw = require("common/throw")

-- NOTE: Index start from 1 in Lua API

local Stack = {
    -- virtual stack
    slots = nil,
    _top = nil,
    -- call info
    state = nil,
    closure = nil,
    varargs = nil,
    openuvs = nil,
    pc = nil,
    prev = nil,
}


function Stack:new(capacity, state)
    Stack.__index = Stack
    self = setmetatable({}, Stack)
    self.slots = {}
    for i = 1, capacity do
        self.slots[i] = self.slots
    end
    self._top = 0
    self.state = state
    self.openuvs = {}
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
    if idx < STACK.LUA_REGISTRYINDEX then
        local uvidx = STACK.LUA_REGISTRYINDEX - idx
        if self.closure == nil or uvidx > self.closure.uvnum then
            return nil
        else
            local uv = self.closure.upvalues[uvidx]
            if uv.stk ~= nil then
                return uv.stk:get(uv.idx + 1)
            else
                return uv.val
            end
        end
    elseif idx == STACK.LUA_REGISTRYINDEX then
        return self.state.registry
    end
    if not self:isValid(idx) then
        Throw:error("[Stack:get ERROR] Invalid index!")
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
    if idx < STACK.LUA_REGISTRYINDEX then
        local uvidx = STACK.LUA_REGISTRYINDEX - idx
        if self.closure == nil or uvidx > self.closure.uvnum then
            return
        else
            local uv = self.closure.upvalues[uvidx]
            if uv.stk ~= nil then
                uv.stk:set(uv.idx + 1, val)
            else
                uv.val = val
            end
            return
        end
    elseif idx == STACK.LUA_REGISTRYINDEX then
        self.state.registry = val
        return
    end
    if not self:isValid(idx) then
        Throw:error("[Stack:set ERROR] Invalid index! (%d)", idx)
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
        Throw:error("[Stack:push ERROR] Stack overflow!")
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
        Throw:error("[Stack:pop ERROR] Stack underflow!")
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
    if idx >= 0 or idx <= STACK.LUA_REGISTRYINDEX then
        return idx
    end
    return self._top + idx + 1
end


function Stack:isValid(idx)
    if idx < STACK.LUA_REGISTRYINDEX then
        local uvidx = STACK.LUA_REGISTRYINDEX - idx
        -- Upvalue index "uvidx" start from 0 but we stored it from 1
        return self.closure ~= nil and uvidx <= self.closure.uvnum
    elseif idx == STACK.LUA_REGISTRYINDEX then
        return true
    end
    local absIdx = self:absIndex(idx)
    local a = absIdx >= 1 and absIdx <= self._top
    if a == false then
        print("fffffffffffffff", idx, absIdx, self._top)
    end
    return a
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
