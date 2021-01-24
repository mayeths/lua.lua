local Locvar = {
    VarName = nil,
    StartPC = nil,
    EndPC = nil,
}


function Locvar:new(varname, startPC, endPC)
    Locvar.__index = Locvar
    self = setmetatable({}, Locvar)
    self.VarName = varname or ""
    self.StartPC = startPC or 0
    self.EndPC = endPC or 0
    return self
end

return Locvar
