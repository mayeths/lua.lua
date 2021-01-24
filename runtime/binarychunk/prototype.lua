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


function Prototype:new(source, lineDefined, lastLineDefined, numParams, isVararg, maxStackSize, code, constants, upvalues, protos, lineInfo, locVars, upvalueNames)
    Prototype.__index = Prototype
    self = setmetatable({}, Prototype)
    self.Source = source
    self.LineDefined = lineDefined
    self.LastLineDefined = lastLineDefined
    self.NumParams = numParams
    self.IsVararg = isVararg
    self.MaxStackSize = maxStackSize
    self.Code = code
    self.Constants = constants
    self.Upvalues = upvalues
    self.Protos = protos
    self.LineInfo = lineInfo
    self.LocVars = locVars
    self.UpvalueNames = upvalueNames
    return self
end

