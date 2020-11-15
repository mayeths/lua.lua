Prototype = {
    Source = nil,
    LineDefined = nil,
    LastLineDefined = nil,
    NumParams = nil,
    IsVararg = nil,
    MaxStackSize = nil,
    Code = nil,
    Constants = nil,
    Upvalues = nil,
    Protos = nil,
    LineInfo = nil,
    LocVars = nil,
    UpvalueNames = nil,
}


function Prototype:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.Source = o.Source or ""
    self.LineDefined = o.LineDefined or 0
    self.LastLineDefined = o.LastLineDefined or 0
    self.NumParams = o.NumParams or 0
    self.IsVararg = o.IsVararg or false
    self.MaxStackSize = o.MaxStackSize or 0
    self.Code = o.Code or {}
    self.Constants = o.Constants or {}
    self.Upvalues = o.Upvalues or {}
    self.Protos = o.Protos or {}
    self.LineInfo = o.LineInfo or {}
    self.LocVars = o.LocVars or {}
    self.UpvalueNames = o.UpvalueNames or {}
    return o
end


return Prototype
