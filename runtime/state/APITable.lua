local LuaState = require("runtime/state/luastate")


function LuaState:NewTable()
    self:CreateTable(0, 0)
end


function LuaState:CreateTable(nArr, nRec)
    local t = {}
    self.stack:push(t)
end

function LuaState:GetTable(idx)
    local t = self.stack:get(idx)
    local k = self.stack:pop()
    self.stack:push(t[k])
    return type(t[k])
end


function LuaState:GetFeild(idx, k)
    local t = self.stack:get(idx)
    self.stack:push(t[k])
    return type(t[k])
end


function LuaState:GetI(idx, i)
    local t = self.stack:get(idx)
    self.stack:push(t[i])
    return type(t[i])
end


function LuaState:SetTable(idx)
    local t = self.stack:get(idx)
    local v = self.stack:pop()
    local k = self.stack:pop()
    t[k] = v
end


function LuaState:SetField(idx, k)
    local t = self.stack:get(idx)
    local v = self.stack:pop()
    t[k] = v
end


function LuaState:SetI(idx, i)
    local t = self.stack:get(idx)
    local v = self.stack:pop()
    t[i] = v
end


