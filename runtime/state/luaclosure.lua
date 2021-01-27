local LuaClosure = {
    proto = nil
}


function LuaClosure:new(proto)
    LuaClosure.__index = LuaClosure
    self = setmetatable({}, LuaClosure)
    self.proto = proto
    return self
end


function LuaClosure:isClosure(val)
    if type(val) ~= "table" then
        return false
    end
    return not not val.proto
end


return LuaClosure
