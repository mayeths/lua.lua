require("runtime/state/luastack")
require("runtime/state/luatype")
LuaState = {
    stack = nil,
}


function LuaState:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.stack = o.stack or LuaStack:new({ capacity = 20 })
    return o
end

