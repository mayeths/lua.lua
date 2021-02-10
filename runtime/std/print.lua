local TYPE = require("lua/type")
local Fmt = require("util/fmt")

local function Print(state)
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


return Print
