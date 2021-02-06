local Util = {}


function Util:printf(fmt, ...)
    local msg = string.format(fmt, ...)
    io.stdout:write(msg)
end


function Util:println(fmt, ...)
    Util:printf(fmt.."\n", ...)
end


function Util:panic(fmt, ...)
    local msg = string.format(fmt.."\n", ...)
    error(msg, 0)
end


return Util
