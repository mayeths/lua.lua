local Upvalue = {
    Instack = nil,
    Idx = nil,
}


function Upvalue:new(instack, idx)
    Upvalue.__index = Upvalue
    self = setmetatable({}, Upvalue)
    self.Instack = instack or 0
    self.Idx = idx or 0
    return self
end

return Upvalue
