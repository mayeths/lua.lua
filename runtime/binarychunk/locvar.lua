LocVar = {
    VarName = nil,
    StartPC = nil,
    EndPC = nil,
}


function LocVar:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.VarName = o.VarName or ""
    self.StartPC = o.StartPC or 0
    self.EndPC = o.EndPC or 0
    return o
end

