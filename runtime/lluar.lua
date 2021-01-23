require("common/arg")

LLUAR_ARG = ARG:new("lluar", "The runtime of lua.lua", "-",
    {
        param_name = "binarychunk",
        unmatched_name = "args"
    }, {
        HELP = ARG:boolopt("h", "Print usage"),
        VERSION = ARG:boolopt("v", "Print current version"),
        OUTPUT = ARG:stropt("o", "Output to specific file", "a.out"),
        DEBUG_LEVEL = ARG:enumopt(
            "debug", "Debug level",
            "0", {"0", "1", "2", "3"}
        ),
    }
)

LLUAR_ARG:parse(arg)
print(LLUAR_ARG:tostring())
