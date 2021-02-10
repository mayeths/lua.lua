local Color = require("util/color")
local Fmt = require("util/fmt")
local Throw = require("util/throw")


local Lest = {
    setups = {},
    teardowns = {},
}


Throw:setDebugMode()


function SCENARIO(name, body)
    Lest.HandleScope(Color:blue("SCENARIO"), name, body)
end


function GIVEN(name, body)
    Lest.setups = {}
    Lest.teardowns = {}
    Lest.HandleScope("Given", name, body)
end


function SETUP(fn)
    Lest.setups[#Lest.setups + 1] = fn
end


function TEARDOWN(fn)
    Lest.teardowns[#Lest.teardowns + 1] = fn
end


function IT_SHOULD(name, body)
    for _, setup in ipairs(Lest.setups) do
        xpcall(setup, Lest.CheckPcall)
    end
    Lest.HandleScope("It should", name, body)
    for _, teardown in ipairs(Lest.teardowns) do
        xpcall(teardown, Lest.CheckPcall)
    end
end


function EXPECT(val)
    return {
        TOEQUAL = function (target)
            Lest.ConfirmExpect(val, target, "to equal")
        end,
        TOBE = function (typ)
            Lest.ConfirmExpect(type(val), typ, "to be")
        end,
        TOTHROW = function ()
            local status = pcall(val)
            if status == true then
                Lest.ConfirmExpect("function", "error", "to throw")
            end
        end
    }
end


function Lest.HandleScope(scope, name, body)
    Lest.scopeDepth = Lest.scopeDepth or 0
    Fmt:println(
        string.rep(" ", Lest.scopeDepth * 4)..
        scope.." "..name
    )

    Lest.scopeDepth = Lest.scopeDepth + 1
    xpcall(body, Lest.CheckPcall)
    Lest.scopeDepth = Lest.scopeDepth - 1

end


function Lest.CheckPcall(err)
    Fmt:println(Color:red("ERROR: ")..err)
    local idx1, idx2 = string.find(err, ":%d+:")
    local fname = string.sub(err, 1, idx1 - 1)
    local lineno = string.sub(err, idx1 + 1, idx2 - 1)
    Lest.PrintSource(fname, lineno)
    Lest.PrintTraceback(fname)
    os.exit(1)
end


function Lest.ConfirmExpect(gotval, expectval, connectword)
    if expectval == gotval then
        return
    end
    local info = debug.getinfo(3, "nlS")
    local fname = info.short_src
    local lineno = info.currentline
    Fmt:println(
        Color:red("ERROR: ")..
        fname..":"..tostring(lineno)..":"..
        " expecting "..tostring(gotval)..
        " "..connectword.." "..tostring(expectval)
    )
    Lest.PrintSource(fname, lineno)
    os.exit(1)
end


function Lest.PrintSource(fname, lineno)
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
            Fmt:println("-> "..curr..pad.." |"..buf[i])
        else
            Fmt:println("   "..curr..pad.." |"..buf[i])
        end
    end
end


function Lest.PrintTraceback(fname)
    local trace = debug.traceback(nil, 3)
    trace = string.gsub(trace, "^stack traceback:\n", "", 1)
    Fmt:println(Color:red("TRACEBACK:"))
    for line in string.gmatch(trace, "[^\n]+") do
        local istargetline = string.find(line, fname)
        if istargetline then
            line = "->\t"..string.sub(line, 2)
        end
        local stop = string.find(line, "in function 'xpcall'")
        if stop then
            break
        end
        Fmt:println(line)
    end
end

