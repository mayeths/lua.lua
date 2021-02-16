-- An instantiated function named "closure" in lua
-- https://www.lua.org/manual/5.3/manual.html#3.4.11
-- > Whenever Lua executes the function definition, the function is instantiated
-- > This function instance (or closure) is the final value of the expression
local TYPE = require("const/type")
local Closure = {
    t = TYPE.LUA_TFUNCTION,
    upvalues = nil,
    uvnum = nil,
    proto = nil,
    outerfn = nil
}


function Closure:new(proto, outerfn, uvnum)
    Closure.__index = Closure
    self = setmetatable({}, Closure)
    self.proto = proto
    self.outerfn = outerfn
    self.upvalues = {}
    self.uvnum = uvnum
    return self
end


function Closure:createUpvalue(i, stack, stkidx)
    self.upvalues[i] = { stk = stack, idx = stkidx }
end


function Closure:holdUpvalue(i, v)
    self.upvalues[i] = { val = v, idx = 0 }
end


return Closure
