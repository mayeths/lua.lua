local Color = require("common/color")
local Util = require("common/util")
local TESTS = {
    "test/common/argTEST",
    "test/runtime/state/stateTEST",
}

function TEST_MAIN()
    for _, path in ipairs(TESTS) do
        require(path)
    end
    Util:println(Color:green("SUCCESS").." All tests passed.")
end

TEST_MAIN()
