local Color = require("common/color")
local Fmt = require("common/fmt")
local TESTS = {
    "unittest/common/argTEST",
    "unittest/runtime/state/stateTEST",
}

function TEST_MAIN()
    for _, path in ipairs(TESTS) do
        require(path)
    end
    Fmt:println(Color:green("SUCCESS").." All tests passed.")
end

TEST_MAIN()
