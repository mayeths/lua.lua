Upvalue = {
    Instack = nil,
    Idx = nil,
}


function Upvalue:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.Instack = o.Instack or 0
    self.Idx = o.Idx or 0
    return o
end


return Upvalue
