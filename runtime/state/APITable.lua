local LuaState = require("runtime/state/luastate")


function LuaState:NewTable()
    self:CreateTable(0, 0)
end


function LuaState:CreateTable(nArr, nRec)
    local t = { table = {}}
    self.stack:push(t)
end

function LuaState:GetTable(idx)
    local t = self.stack:get(idx)
    local k = self.stack:pop()
    self.stack:push(t.table[k])
    return type(t.table[k])
end


function LuaState:GetFeild(idx, k)
    local t = self.stack:get(idx)
    self.stack:push(t.table[k])
    return type(t.table[k])
end


function LuaState:GetI(idx, i)
    local t = self.stack:get(idx)
    self.stack:push(t.table[i])
    return type(t.table[i])
end


function LuaState:SetTable(idx)
    local t = self.stack:get(idx)
    local v = self.stack:pop()
    local k = self.stack:pop()
    t.table[k] = v
end


function LuaState:SetField(idx, k)
    local t = self.stack:get(idx)
    local v = self.stack:pop()
    t.table[k] = v
end


function LuaState:SetI(idx, i)
    local t = self.stack:get(idx)
    local v = self.stack:pop()
    t.table[i] = v
end


