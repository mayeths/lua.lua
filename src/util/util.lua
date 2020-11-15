Util = {}


function Util:printf(fmt, ...)
    local msg = string.format(fmt, ...)
    io.stdout:write(msg)
end


function Util:println(fmt, ...)
    Util:printf(fmt.."\n", ...)
end


function Util:panic(fmt, ...)
    local msg = string.format(fmt.."\n", ...)
    io.stderr:write(msg)
    os.exit(1)
end


function Util:assert(got, expect, errmsg)
    if got == expect then
        return
    end
    local str1 = tostring(got)
    local str2 = tostring(expect)
    local formattedMsg = errmsg.." Got "..str1.." Expect "..str2
    Util:panic(formattedMsg)
end


