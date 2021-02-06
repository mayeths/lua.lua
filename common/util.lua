local Util = {}


function Util:printf(fmt, ...)
    if #{...} ~= 0 then
        fmt = string.format(fmt, ...)
    end
    io.stdout:write(fmt)
end


function Util:println(fmt, ...)
    Util:printf(fmt.."\n", ...)
end


function Util:panic(fmt, ...)
    local msg = string.format(fmt.."\n", ...)
    error(msg, 0)
end


return Util
