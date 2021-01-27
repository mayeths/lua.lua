local Table = {
    t = "table",
    table = nil,
}


function Table:new()
    Table.__index = Table
    self = setmetatable({}, Table)
    self.table = {}
    return self
end


return Table
