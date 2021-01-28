local TYPE = require("lua/type")
local State = require("runtime/state/state")
local Util = require("common/util")


LLUA = {}


function LLUA:main()
    if #arg < 1 then
        Util:panic("[LLUA ERROR] Running LLUA require a bytecode file")
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
        local t = state:Type(i)
        if t == TYPE.LUA_TBOOLEAN then
            Util:printf(tostring(state:ToBoolean(i)))
        elseif t == TYPE.LUA_TNUMBER then
            if state:IsInteger(i) then
                Util:printf(tostring(state:ToInteger(i)))
            else
                Util:printf(tostring(state:ToNumber(i)))
            end
        elseif t == TYPE.LUA_TNIL then
            Util:printf("nil")
        elseif t == TYPE.LUA_TSTRING then
            Util:printf("%s", state:ToString(i))
        else
            Util:printf("%s: %s", state:TypeName(t), t)
        end
    end
    Util:printf("\n")
    return 0
end


LLUA:main()
