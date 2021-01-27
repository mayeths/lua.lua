-- An instantiated function named "closure" in lua
-- https://www.lua.org/manual/5.3/manual.html#3.4.11
-- > Whenever Lua executes the function definition, the function is instantiated
-- > This function instance (or closure) is the final value of the expression

local Closure = {
    t = "function",
    proto = nil,
}


function Closure:new(proto)
    Closure.__index = Closure
    self = setmetatable({}, Closure)
    self.proto = proto
    return self
end


return Closure
