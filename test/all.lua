local Color = require("util/color")
local Fmt = require("util/fmt")
local TESTS = {
    "test/util/argTEST",
    "test/runtime/state/stateTEST",
}

function TEST_MAIN()
    for _, path in ipairs(TESTS) do
        require(path)
    end
    Fmt:println(Color:green("SUCCESS").." All tests passed.")
end

TEST_MAIN()
