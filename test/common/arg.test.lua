require("common/arg")
require("test/catch")

SCENARIO("Testing common/arg basic function", function ()

    GIVEN("a simple argument constructor", function ()
        local name = nil
        local desc = nil
        local test_arg = nil

        SETUP(function ()
            name = "TEST"
            desc = "test arg function"
            test_arg = ARG:new(name, desc, "-", {
                HELP = ARG:boolopt("h", "Print usage"),
                DEPTH = ARG:numbopt("depth", "The depth of stack", 0),
                OUTPUT = ARG:stropt("o", "Redirect output to file", "a.txt"),
                OPTIMIZATION = ARG:enumopt(
                    "O", "Optimization level",
                    "2", {"0", "1", "2", "3"}
                ),
            })
        end)

        IT_SHOULD("return an arg object correctly", function ()
            EXPECT(test_arg.name).TOEQUAL(name)
            EXPECT(test_arg.desc).TOEQUAL(desc)
            EXPECT(test_arg:tostring()).TOBE("string")
        end)

        IT_SHOULD("accept empty argument table to use default values", function ()
            test_arg:parse({})
            EXPECT(test_arg.HELP).TOEQUAL(false)
            EXPECT(test_arg.DEPTH).TOEQUAL(0)
            EXPECT(test_arg.OUTPUT).TOEQUAL("a.txt")
            EXPECT(test_arg.OPTIMIZATION).TOEQUAL("2")
        end)

        IT_SHOULD("accept -h boolean argument", function ()
            test_arg:parse({"-h"})
            EXPECT(test_arg.HELP).TOEQUAL(true)
        end)

        IT_SHOULD("accept -depth integer argument", function ()
            test_arg:parse({"-depth", "6918207"})
            EXPECT(test_arg.DEPTH).TOEQUAL(6918207)
        end)

        IT_SHOULD("accept -o string argument", function ()
            test_arg:parse({"-o", "./abc.txt"})
            EXPECT(test_arg.OUTPUT).TOEQUAL("./abc.txt")
        end)

        IT_SHOULD("accept -O enum argument", function ()
            test_arg:parse({"-O", "3"})
            EXPECT(test_arg.OPTIMIZATION).TOEQUAL("3")
        end)

    end)

end)
