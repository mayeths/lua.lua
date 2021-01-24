local Util = require("common/util")

function LuaState:PushNil()
    self.stack:push(nil)
end


function LuaState:PushBoolean(b)
    Util:assert(type(b), "boolean",
        "Pushing a non-boolean value by PushBoolean method"
    )
    self.stack:push(b)
end


function LuaState:PushInteger(n)
    Util:assert(math.type(n), "integer",
        "Pushing a non-integer value by PushInteger method"
    )
    self.stack:push(n)
end


function LuaState:PushNumber(n)
    self.stack:push(n)
end


function LuaState:PushString(s)
    self.stack:push(s)
end

