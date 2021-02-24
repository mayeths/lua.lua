local TYPE = require("const/type")
local Throw = require("util/throw")
local Value = {}


function Value.TypeID(val)
    local valtype = type(val)
    if valtype == "nil" then
        return TYPE.LUA_TNIL
    elseif valtype == "boolean" then
        return TYPE.LUA_TBOOLEAN
    elseif valtype == "number" then
        return TYPE.LUA_TNUMBER
    elseif valtype == "string" then
        return TYPE.LUA_TSTRING
    elseif valtype == "table" then
        if val.t == TYPE.LUA_TTABLE then
            return TYPE.LUA_TTABLE
        elseif val.t == TYPE.LUA_TFUNCTION then
            return TYPE.LUA_TFUNCTION
        end
        Throw:error("[Value.TypeID ERROR] Unknown type wrapper!")
    end
    Throw:error("[Value.TypeID ERROR] Unknown type!")
end


function Value.TypeName(val)
    local valtype = type(val)
    if valtype ~= "table" then
        return valtype
    elseif val.t == TYPE.LUA_TTABLE then
        return "table"
    elseif val.t == TYPE.LUA_TFUNCTION then
        return "function"
    end
    Throw:error("[Value.TypeName ERROR] Unknown type!")
end


function Value.TypeID2Name(tid)
    if tid == TYPE.LUA_TNONE then
        return "none"
    elseif tid == TYPE.LUA_TNIL then
        return "nil"
    elseif tid == TYPE.LUA_TBOOLEAN then
        return "boolean"
    elseif tid == TYPE.LUA_TNUMBER then
        return "number"
    elseif tid == TYPE.LUA_TSTRING then
        return "string"
    elseif tid == TYPE.LUA_TTABLE then
        return "table"
    elseif tid == TYPE.LUA_TFUNCTION then
        return "function"
    elseif tid == TYPE.LUA_TTHREAD then
        return "thread"
    elseif tid == TYPE.LUA_TUSERDATA then
        return "userdata"
    end
    Throw:error("[Value.TypeName ERROR] Unknown typeid %d!", tid)
end


function Value.TypeName2ID(tname)
    if tname == "none" then
        return TYPE.LUA_TNONE
    elseif tname == "nil" then
        return TYPE.LUA_TNIL
    elseif tname == "boolean" then
        return TYPE.LUA_TBOOLEAN
    elseif tname == "number" then
        return TYPE.LUA_TNUMBER
    elseif tname == "string" then
        return TYPE.LUA_TSTRING
    elseif tname == "table" then
        return TYPE.LUA_TTABLE
    elseif tname == "function" then
        return TYPE.LUA_TFUNCTION
    elseif tname == "thread" then
        return TYPE.LUA_TTHREAD
    else
        return TYPE.LUA_TUSERDATA
    end
end


function Value.Any2Boolean(val)
    return not not val
end


function Value.Any2Float(val)
    local t = type(val)
    if t == "number" then
        return val + 0.0, true
    elseif t == "string" then
        return Value.str2float(val)
    else
        return 0.0, false
    end
end


function Value.Any2Int(val)
    local t = type(val)
    if t == "number" then
        return math.floor(val), true
    elseif t == "string" then
        return Value.str2int(val)
    else
        return 0, false
    end
end


function Value.Any2Str(val)
    local t = type(val)
    if t == "number" then
        return tostring(val), true
    elseif t == "string" then
        return val, true
    else
        if val.t == "table" then
            return tostring(val.table), true
        elseif val.t == "function" then
            return "function: "..tostring(val.proto):sub(8)
        end
        Throw:error("[Value.Any2str ERROR] unsupported convert")
    end
end


function Value.Float2Int(val)
    local t = math.type(val)
    if t == "float" then
        return math.floor(val), true
    elseif t == "integer" then
        return val, true
    else
        return 0, false
    end
end


function Value.Int2Float(val)
    local t = math.type(val)
    if t == "integer" then
        return val + 0.0, true
    elseif t == "float" then
        return val, true
    else
        return 0.0, false
    end
end


function Value.Str2Int(val)
    local t = type(val)
    if t == "string" then
        local result = tonumber(val)
        if result == nil then
            return 0, false
        end
        return math.floor(result), true
    elseif t == "number" then
        return val, true
    else
        return 0, false
    end
end


function Value.Str2Float(val)
    local t = type(val)
    if t == "string" then
        local result = tonumber(val)
        if result == nil then
            return 0.0, false
        end
        return result + 0.0, true
    elseif t == "number" then
        return val + 0.0, true
    else
        return 0.0, false
    end
end


function Value.GetMetatable(val, state)
    if type(val) == "table" and val.t == TYPE.LUA_TTABLE then
        return val.metatable
    else
        return state.metatables[Value.TypeID(val)]
    end
end


function Value.SetMetatable(val, mt, state)
    if type(val) == "table" and val.t == TYPE.LUA_TTABLE then
        val.metatable = mt
    else
        state.metatables[Value.TypeID(val)] = mt
    end
end


function Value.GetMetaField(val, field, state)
    local mt = Value.GetMetatable(val, state)
    if not mt or type(mt) ~= "table" or mt.t ~= TYPE.LUA_TTABLE then
        return nil
    end
    return mt.table[field]
end


function Value.CallMetamethod(a, b, name, state)
    local metamethod = Value.GetMetaField(a, name, state)
    if not metamethod then
        metamethod = Value.GetMetaField(b, name, state)
        if not metamethod then
            return nil, false
        end
    end
    state.stack:ensure(4)
    state.stack:push(metamethod)
    state.stack:push(a)
    state.stack:push(b)
    state:Call(2, 1)
    return state.stack:pop(), true
end


function Value.GetTable(val, k, state)
    local typ = Value.TypeID(val)
    if typ == TYPE.LUA_TTABLE then
        local result = val.table[k]
        if result ~= nil then
            state.stack:push(result)
            return Value.TypeID(result)
        end
    end

    local __index = Value.GetMetaField(val, "__index", state)
    local __indext = Value.TypeID(__index)
    if __indext == TYPE.LUA_TTABLE then
        return Value.GetTable(__index, k, state)
    elseif __indext == TYPE.LUA_TFUNCTION then
        state.stack:push(__index)
        state.stack:push(val)
        state.stack:push(k)
        state:Call(2, 1)
        local result = state.stack:get(-1)
        return Value.TypeID(result)
    else
        -- TODO: error
    end
end


return Value
