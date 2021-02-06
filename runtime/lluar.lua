local Fmt = require("common/fmt")
local Arg = require("common/arg")
LLUAR = {
    NAME = "Lua.lua runtime",
    VERSION = "0.1.0",
    INFO = "Copyright (C) 2021 Mayeths",
}
local lluar_arg = Arg:new("lluar", "The runtime of lua.lua", "-",
    {
        param_name = "chunk",
        unmatched_name = "args"
    }, {
        HELP = Arg:boolopt("h", "Print this help"),
        VERSION = Arg:boolopt("v", "Print current version"),
        FULLVERSION = Arg:boolopt("V", "Print current version (full)"),
        OUTPUT = Arg:stropt("o", "Output to specific file", "a.out"),
        DEBUG_LEVEL = Arg:enumopt(
            "-debug", "Debug level",
            "0", {"0", "1", "2", "3"}
        ),
    }
)


function LLUAR:main()
    lluar_arg:parse(arg)
    if lluar_arg.HELP == true then
        Fmt:println(lluar_arg:tostring())
        return
    elseif lluar_arg.VERSION == true then
        Fmt:println(LLUAR.VERSION)
        return
    elseif lluar_arg.FULLVERSION == true then
        local arr = { LLUAR.NAME, LLUAR.VERSION, LLUAR.INFO }
        local msg = table.concat(arr, " ")
        Fmt:println(msg)
        return
    end
end




LLUAR:main()

