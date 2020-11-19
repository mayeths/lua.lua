Convert = {}

--
-- Part1: any2x
--

function Convert:any2boolean(val)
    local t = type(val)
    if t == "nil" then
        return false
    elseif t == "boolean" then
        return val
    else
        return true
    end
end


function Convert:any2float(val)
    local t = type(val)
    if t == "number" then
        return t, true
    elseif t == "string" then
        return Convert:str2float(val)
    else
        return 0, false
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
    return tostring(val), true
end


--
-- Part2: number2number
--

function Convert:float2int(val)
    if type(val) == "number" then
        return math.floor(val), true
    else
        return 0, false
    end
end


function Convert:int2float(val)
    if math.type(val) ~= nil then
        return val + 0.0, true
    else
        return 0, false
    end
end


--
-- Part3: str2x
--


function Convert:str2int(str)
    local result = tonumber(str)
    if result == nil then
        return nil, false
    else
        return math.floor(result), true
    end
end


function Convert:str2float(str)
    local result = tonumber(str)
    return result, result ~= nil
end

