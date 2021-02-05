local Color = require("common/color")
local Util = require("common/util")


function SCENARIO(name, body)
    __LEST_HANDLE_SCOPE__(Color:blue("SCENARIO"), name, body)
end


function GIVEN(name, body)
    __LEST_SETUPS__ = {}
    __LEST_TEARDOWNS__ = {}
    __LEST_HANDLE_SCOPE__("Given", name, body)
end


function SETUP(fn)
    __LEST_SETUPS__[#__LEST_SETUPS__ + 1] = fn
end


function TEARDOWN(fn)
    __LEST_TEARDOWNS__[#__LEST_TEARDOWNS__ + 1] = fn
end


function IT_SHOULD(name, body)
    for _, setup in ipairs(__LEST_SETUPS__) do
        xpcall(setup, __LEST_CHECK_PCALL__)
    end
    __LEST_HANDLE_SCOPE__("It should", name, body)
    for _, teardown in ipairs(__LEST_TEARDOWNS__) do
        xpcall(teardown, __LEST_CHECK_PCALL__)
    end
end


function EXPECT(val)
    return {
        TOEQUAL = function (target)
            __LEST_CONFIRM_EXPECT__(val, target, "to equal")
        end,
        TOBE = function (typ)
            __LEST_CONFIRM_EXPECT__(type(val), typ, "to be")
        end,
    }
end


function __LEST_HANDLE_SCOPE__(scope, name, body)
    __LEST_SCOPE_DEPTH__ = __LEST_SCOPE_DEPTH__ or 0
    Util:println(
        string.rep(" ", __LEST_SCOPE_DEPTH__ * 4)..
        scope.." "..name
    )

    __LEST_SCOPE_DEPTH__ = __LEST_SCOPE_DEPTH__ + 1
    xpcall(body, __LEST_CHECK_PCALL__)
    __LEST_SCOPE_DEPTH__ = __LEST_SCOPE_DEPTH__ - 1

end


function __LEST_CHECK_PCALL__(err)
    Util:println(Color:red("ERROR ")..err)
    local idx1, idx2 = string.find(err, ":%d+:")
    local fname = string.sub(err, 1, idx1 - 1)
    local lineno = string.sub(err, idx1 + 1, idx2 - 1)
    __LEST_PRINT_SOURCE__(fname, lineno)
    local trace = debug.traceback(nil, 2)
    for line in trace:gmatch("[^\n]+") do
        local stop = string.find(line, "in function 'xpcall'")
        if stop then
            break
        end
        Util:println(line)
    end
    os.exit(1)
end


function __LEST_CONFIRM_EXPECT__(gotval, expectval, connectword)
    if expectval == gotval then
        return
    end
    local info = debug.getinfo(3, "nlS")
    local fname = info.short_src
    local lineno = info.currentline
    Util:println(
        Color:red("ERROR ")..
        fname..":"..tostring(lineno)..":"..
        " expecting "..tostring(gotval)..
        " "..connectword.." "..tostring(expectval)
    )
    __LEST_PRINT_SOURCE__(fname, lineno)
    os.exit(1)
end


function __LEST_PRINT_SOURCE__(fname, lineno)
    lineno = math.floor(lineno)
    local file = io.open(fname, "r")
    local buf = {}
    local count = 1
    local range = 1
    for line in file:lines() do
        if count > lineno + range then
            break
        elseif count >= lineno - range then
            buf[#buf + 1] = line
        end
        count = count + 1
    end
    file:close()
    local maxwidth = #tostring(lineno + range)
    for i = 1, #buf do
        local reallineno = lineno + i - 2
        local curr = tostring(reallineno)
        local pad = string.rep(" ", maxwidth - #curr)
        if i == range + 1 then
            Util:println("-> "..curr..pad.." |"..buf[i])
        else
            Util:println("   "..curr..pad.." |"..buf[i])
        end
    end
end
