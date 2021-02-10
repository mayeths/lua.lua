local Throw = require("util/throw")
local Convert = {}

-- Return the converted value and convert result
-- (Except any2boolean)

function Convert:any2boolean(val)
    return not not val
end


function Convert:any2float(val)
    local t = type(val)
    if t == "number" then
        return val + 0.0, true
    elseif t == "string" then
        return Convert:str2float(val)
    else
        return 0.0, false
    end
end


function Convert:any2int(val)
    local t = type(val)
    if t == "number" then
        return math.floor(val), true
    elseif t == "string" then
        return Convert:str2int(val)
    else
        return 0, false
    end
end


function Convert:any2str(val)
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
        -- TODO: convert the custom type to string
        Throw:error("[Convert:any2str ERROR] unsupported convert")
    end
end


function Convert:float2int(val)
    local t = math.type(val)
    if t == "float" then
        return math.floor(val), true
    elseif t == "integer" then
        return val, true
    else
        return 0, false
    end
end


function Convert:int2float(val)
    local t = math.type(val)
    if t == "integer" then
        return val + 0.0, true
    elseif t == "float" then
        return val, true
    else
        return 0.0, false
    end
end


function Convert:str2int(val)
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


function Convert:str2float(val)
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


return Convert
