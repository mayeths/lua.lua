require("common/util")
ARG = {
    name = nil,
    desc = nil,
    prefix = nil,
    schemas = nil,
    param_name = nil,
    unmatched_name = nil,
    PARAM = nil,
    UNMATCHED = nil,
}
OPTION = {
    name = nil,
    desc = nil,
    typ = nil,
    defaultValue = nil,
    enumValues = nil,
}


function ARG:new(name, desc, prefix, config, schemas)
    ARG.__index = ARG
    self = setmetatable({}, ARG)
    self.name = name or "Unknown"
    self.desc = desc or "no description available"
    self.prefix = prefix or "-"
    self.schemas = schemas or {}
    self.param_name = config.param_name or ""
    self.unmatched_name = config.unmatched_name or ""
    self.PARAM = {}
    self.UNMATCHED = {}
    return self
end


function ARG:parse(cmdarg)
    if type(cmdarg) ~= "table" then
        Util:panic("Not valid cmdarg")
    end
    for key, opt in pairs(self.schemas) do
        self[key] = opt.defaultValue
    end
    local remainingIdx = {}
    for i = 1, #cmdarg do
        table.insert(remainingIdx, i)
    end

    for key, opt in pairs(self.schemas) do
        local i = 1
        while i <= #cmdarg do
            if string.sub(cmdarg[i], 1, 1) == self.prefix then
                if string.sub(cmdarg[i], 2) == opt.name then
                    if opt.typ == "boolean" then
                        self[key] = true
                        table.remove(remainingIdx, i)
                        i = i + 1
                    elseif opt.typ == "number" then
                        self[key] = tonumber(cmdarg[i + 1])
                        table.remove(remainingIdx, i)
                        table.remove(remainingIdx, i + 1)
                        i = i + 2
                    elseif opt.typ == "string" then
                        self[key] = tostring(cmdarg[i + 1])
                        table.remove(remainingIdx, i)
                        table.remove(remainingIdx, i + 1)
                        i = i + 2
                    elseif opt.typ == "enum" then
                        if not opt:isValidEnumVal(cmdarg[i + 1]) then
                            Util:throwError(
                                "Expect valid %s%s argument (valid: %s, default %s)",
                                self.prefix, opt.name,
                                table.concat(opt.enumValues, " "), opt.defaultValue
                            )
                        end
                        self[key] = cmdarg[i + 1]
                        table.remove(remainingIdx, i)
                        table.remove(remainingIdx, i + 1)
                        i = i + 2
                    else
                        Util:panic("Unknown option type"..type(opt.typ))
                    end
                end
            end
            i = i + 1
        end
    end

    self.PARAM = {}
    while #remainingIdx > 0 do
        local idx = table.remove(remainingIdx, 1)
        if string.sub(cmdarg[idx], 1, 1) == self.prefix then
            table.insert(self.UNMATCHED, cmdarg[idx])
        else
            table.insert(self.PARAM, cmdarg[idx])
        end
    end
end


function ARG:tostring()
    local msg = {
        string.format("%s -- %s", self.name, self.desc),
        string.format("Usage: %s [options] %s [%s]",
            self.name, self.param_name, self.unmatched_name
        ),
        "Available options are:",
    }
    local opts = {}
    local maxwidth = 0
    for _, opt in pairs(self.schemas) do
        opts[#opts + 1] = opt
        if #tostring(opt.name) > maxwidth then
            maxwidth = #tostring(opt.name)
        end
    end
    table.sort(opts, function (e1, e2)
        return e1.name < e2.name
    end)
    for _, opt in ipairs(opts) do
        local pad = string.rep(" ", maxwidth - #opt.name + 2)
        msg[#msg+1] = string.format("    %s%s%s%s",
            self.prefix, opt.name,
            pad, opt.desc
        )
        if opt.typ == "enum" then
            msg[#msg] = string.format(
                "%s (valid: %s, default %s)",
                msg[#msg], table.concat(opt.enumValues, " "),
                opt.defaultValue
            )
        end
    end
    return table.concat(msg, "\n")
end


function ARG:boolopt(name, desc)
    return OPTION:new(name, desc, "boolean", false, nil)
end


function ARG:numbopt(name, desc, defaultNumb)
    return OPTION:new(name, desc, "number", defaultNumb, nil)
end


function ARG:stropt(name, desc, defaultStr)
    return OPTION:new(name, desc, "string", defaultStr, nil)
end


function ARG:enumopt(name, desc, defaultValue, enumValues)
    return OPTION:new(name, desc, "enum", defaultValue, enumValues)
end


function OPTION:new(name, desc, typ, defaultValue, enumValues)
    OPTION.__index = OPTION
    self = setmetatable({}, OPTION)
    self.name = name or "unkownopt"
    self.desc = desc or "no description available"
    self.typ = typ
    if typ == "string" and type(defaultValue) ~= "string" then
        Util:panic("Not a valid default string value")
    elseif typ == "number" and type(defaultValue) ~= "number" then
        Util:panic("Not a valid default number value")
    elseif typ == "enum" and type(enumValues) ~= "table" then
        Util:panic("Not valid enum values")
    end
    self.defaultValue = defaultValue
    self.enumValues = enumValues
    return self
end


function OPTION:isValidEnumVal(a)
    if type(self.enumValues) ~= "table" then
        Util:panic("Not valid enumValues")
    end
    for i = 1, #self.enumValues do
        if a == self.enumValues[i] then
            return true
        end
    end
    return false
end
