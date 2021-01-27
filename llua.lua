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
    local ls = State:new()
    ls:Load(data, arg[1], "b")
    ls:Call(0, 0)
end


LLUA:main()
