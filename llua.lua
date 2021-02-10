local TYPE = require("const/type")
local State = require("runtime/state/state")
local Fmt = require("util/fmt")
local Throw = require("util/throw")


LLUA = {}


function LLUA:main()
    if #arg < 1 then
        Throw:error("[LLUA ERROR] Running LLUA require a bytecode file")
    end
    local fd = io.open(arg[1], "rb")
    local data = fd:read("*all")
    fd:close()
    local state = State:new()
    state:Register("print", LLUA.print)
    state:Load(data, arg[1], "b")
    state:Call(0, 0)
end


function LLUA.print(state)
    local nargs = state:GetTop()
    for i = 1, nargs do
        if i ~= 1 then
            Fmt:printf("\t")
        end
        local t = state:Type(i)
        if t == TYPE.LUA_TBOOLEAN then
            Fmt:printf(tostring(state:ToBoolean(i)))
        elseif t == TYPE.LUA_TNUMBER then
            if state:IsInteger(i) then
                Fmt:printf(tostring(state:ToInteger(i)))
            else
                Fmt:printf(tostring(state:ToNumber(i)))
            end
        elseif t == TYPE.LUA_TNIL then
            Fmt:printf("nil")
        elseif t == TYPE.LUA_TSTRING then
            Fmt:printf("%s", state:ToString(i))
        else
            Fmt:printf("%s: %s", state:TypeName(t), t)
        end
    end
    Fmt:printf("\n")
    return 0
end


LLUA:main()
