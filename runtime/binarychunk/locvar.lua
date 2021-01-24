LocVar = {
    VarName = nil,
    StartPC = nil,
    EndPC = nil,
}


function LocVar:new(varname, startPC, endPC)
    LocVar.__index = LocVar
    self = setmetatable({}, LocVar)
    self.VarName = varname or ""
    self.StartPC = startPC or 0
    self.EndPC = endPC or 0
    return self
end

