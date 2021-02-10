local Fmt = {}


function Fmt:printf(fmt, ...)
    if #{...} ~= 0 then
        fmt = string.format(fmt, ...)
    end
    io.stdout:write(fmt)
end


function Fmt:println(fmt, ...)
    Fmt:printf(fmt.."\n", ...)
end


return Fmt
