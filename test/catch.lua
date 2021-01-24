require("common/color")
local Util = require("common/util")


function SCENARIO(name, body)
    __CATCH_HANDLE_SCOPE__(Color:blue("Scenario"), name, body)
end


function GIVEN(name, body)
    __CATCH_SETUPS__ = {}
    __CATCH_TEARDOWNS__ = {}
    __CATCH_HANDLE_SCOPE__("Given", name, body)
end


function SETUP(fn)
    __CATCH_SETUPS__[#__CATCH_SETUPS__ + 1] = fn
end


function TEARDOWN(fn)
    __CATCH_TEARDOWNS__[#__CATCH_TEARDOWNS__ + 1] = fn
end


function IT_SHOULD(name, body)
    for _, setup in ipairs(__CATCH_SETUPS__) do
        local status, err = pcall(setup)
        __CATCH_CHECK_PCALL__(status, err)
    end
    __CATCH_HANDLE_SCOPE__("It should", name, body)
    for _, teardown in ipairs(__CATCH_TEARDOWNS__) do
        local status, err = pcall(teardown)
        __CATCH_CHECK_PCALL__(status, err)
    end
end


function EXPECT(val)
    return {
        TOEQUAL = function (target)
            __CATCH_CONFIRM_EXPECT__(val, target, "to equal")
        end,
        TOBE = function (typ)
            __CATCH_CONFIRM_EXPECT__(type(val), typ, "to be")
        end,
    }
end


function __CATCH_HANDLE_SCOPE__(scope, name, body)
    __CATCH_SCOPE_DEPTH__ = __CATCH_SCOPE_DEPTH__ or 0
    Util:println(
        string.rep(" ", __CATCH_SCOPE_DEPTH__ * 4)..
        scope.." "..name
    )

    __CATCH_SCOPE_DEPTH__ = __CATCH_SCOPE_DEPTH__ + 1
    local status, err = pcall(body)
    __CATCH_SCOPE_DEPTH__ = __CATCH_SCOPE_DEPTH__ - 1

    __CATCH_CHECK_PCALL__(status, err)
end


function __CATCH_CHECK_PCALL__(status, err)
    if status == true then
        return
    end
    Util:println(Color:red("ERROR ")..err)
    local idx1, idx2 = string.find(err, ":%d+:")
    local fname = string.sub(err, 1, idx1 - 1)
    local lineno = string.sub(err, idx1 + 1, idx2 - 1)
    __CATCH_PRINT_SOURCE__(fname, lineno)
    os.exit(1)
end


function __CATCH_CONFIRM_EXPECT__(gotval, expectval, connectword)
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
    __CATCH_PRINT_SOURCE__(fname, lineno)
    os.exit(1)
end


function __CATCH_PRINT_SOURCE__(fname, lineno)
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
