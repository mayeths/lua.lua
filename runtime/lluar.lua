local Util = require("common/util")
require("common/arg")
LLUAR = {
    NAME = "Lua.lua runtime",
    VERSION = "0.1.0",
    INFO = "Copyright (C) 2021 Mayeths",
}
LLUAR_ARG = ARG:new("lluar", "The runtime of lua.lua", "-",
    {
        param_name = "binarychunk",
        unmatched_name = "args"
    }, {
        HELP = ARG:boolopt("h", "Print this help"),
        VERSION = ARG:boolopt("v", "Print current version"),
        OUTPUT = ARG:stropt("o", "Output to specific file", "a.out"),
        DEBUG_LEVEL = ARG:enumopt(
            "debug", "Debug level",
            "0", {"0", "1", "2", "3"}
        ),
    }
)


function LLUAR:main()
    LLUAR_ARG:parse(arg)
    if LLUAR_ARG.HELP == true then
        Util:println(LLUAR_ARG:tostring())
        return
    elseif LLUAR_ARG.VERSION == true then
        local arr = { LLUAR.NAME, LLUAR.VERSION, LLUAR.INFO }
        local msg = table.concat(arr, " ")
        Util:println(msg)
        return
    end
end




LLUAR:main()

