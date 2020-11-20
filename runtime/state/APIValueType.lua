require("util/util")


function LuaState:TypeName(tid)
    if tid == LuaType.LUA_TNONE then
        return "no value"
    elseif tid == LuaType.LUA_TNIL then
        return "nil"
    elseif tid == LuaType.LUA_TBOOLEAN then
        return "boolean"
    elseif tid == LuaType.LUA_TNUMBER then
        return "number"
    elseif tid == LuaType.LUA_TSTRING then
        return "string"
    elseif tid == LuaType.LUA_TTABLE then
        return "table"
    elseif tid == LuaType.LUA_TFUNCTION then
        return "function"
    elseif tid == LuaType.LUA_TTHREAD then
        return "thread"
    else
        return "userdata"
    end
end


function LuaState:Type(idx)
    if not self.stack:isValid(idx) then
        return LuaType.LUA_TNONE
    end
    local val = self.stack:get(idx)
    local valtype = type(val)
    if valtype == "nil" then
        return LuaType.LUA_TNIL
    elseif valtype == "boolean" then
        return LuaType.LUA_TBOOLEAN
    elseif valtype == "number" then
        return LuaType.LUA_TNUMBER
    elseif valtype == "string" then
        return LuaType.LUA_TSTRING
    else
        Util:panic("[LuaState:Type ERROR] Unknown type!")
    end
end


function LuaState:IsNone(idx)
    return self:Type(idx) == LuaType.LUA_TNONE
end


function LuaState:IsNil(idx)
    return self:Type(idx) == LuaType.LUA_TNIL
end


function LuaState:IsNoneOrNil(idx)
    return self:Type(idx) <= LuaType.LUA_TNIL
end


function LuaState:IsBoolean(idx)
    return self:Type(idx) == LuaType.LUA_TBOOLEAN
end


function LuaState:IsTable(idx)
    return self:Type(idx) == LuaType.LUA_TTABLE
end


function LuaState:IsFunction(idx)
    return self:Type(idx) == LuaType.LUA_TFUNCTION
end


function LuaState:IsThread(idx)
    return self:Type(idx) == LuaType.LUA_TTHREAD
end


function LuaState:IsString(idx)
    local t = self:Type(idx)
    return t == LuaType.LUA_TSTRING or t == LuaType.LUA_TNUMBER
end


function LuaState:IsNumber(idx)
    local val = self.stack:get(idx)
    return math.type(val) ~= nil
end


function LuaState:IsInteger(idx)
    local val = self.stack:get(idx)
    return math.type(val) == "integer"
end


function LuaState:ToBoolean(idx)
    local t = self:Type(idx)
    if t == LuaType.LUA_TNIL then
        return false
    elseif t == LuaType.LUA_TBOOLEAN then
        return self.stack:get(idx)
    else
        return true
    end
end


function LuaState:ToInteger(idx)
    local i, _ = self:ToIntegerX(idx)
    return i
end


function LuaState:ToIntegerX(idx)
    local val = self.stack:get(idx)
    local mtype = math.type(val)
    if mtype == "integer" then
        return val, true
    elseif mtype == "float" then
        return math.tointeger(val), true
    else
        return 0, false
    end
end


function LuaState:ToNumber(idx)
    local n, _ = self:ToNumberX(idx)
    return n
end


function LuaState:ToNumberX(idx)
    local val = self.stack:get(idx)
    local mtype = math.type(val)
    if mtype ~= nil then
        return val+0.0, true
    else
        return 0, false
    end
end


function LuaState:ToString(idx)
    local s, _ = self:ToStringX(idx)
    return s
end


function LuaState:ToStringX(idx)
    local val = self.stack:get(idx)
    local t = type(val)
    if t == "string" then
        return val, true
    elseif t == "number" then
        return tostring(t), true
    else
        return "", false
    end
end

