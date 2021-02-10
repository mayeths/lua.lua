Flatten = {}

local RErequire = "(require%s*%()(.*)(%s*%))"
local RErequireDep = "(require%s*%(%s*[\"\'])(.*)([\"\']%s*%))"
local REreturnDep = "^(return)(.*)"


function Flatten:flatten(infile, outfile)
    local inname = string.match(infile, "(.*)(%.lua)")
    if not inname then
        io.stderr:write(string.format("Not a valid lua script: %s\n", infile))
        os.exit(1)
    end
    local mod = self:createMod(inname)
    local arr = self:breaktree(mod)
    self:save(arr, outfile)
end


function Flatten:createMod(modname)
    local mod = { name = modname, deps = {} }
    local file, err = io.open(modname..".lua", "r")
    if not file then
        io.stderr:write(err)
        os.exit(1)
    end

    local buf = {}
    for line in file:lines() do
        local req, name = string.match(line, RErequire)
        if req then
            local _, depname = string.match(line, RErequireDep)
            if depname then
                buf[#buf + 1] = depname
            else
                local fmt = "Warning: found require() but modname is %s"
                io.stderr:write(fmt, name)
            end
        end
    end

    for i = 1, #buf do
        local depname = buf[i]
        mod.deps[#mod.deps + 1] = self:createMod(depname)
    end

    file:close()
    return mod
end


function Flatten:breaktree(mod)
    local deparrs = {}
    for i = 1, #mod.deps do
        local dep = mod.deps[i]
        deparrs[#deparrs + 1] = self:breaktree(dep)
    end

    local namearr = {}
    for i = 1, #deparrs do
        local deparr = deparrs[i]
        for j = 1, #deparr do
            local depname = deparr[j]
            if not self:exist(namearr, depname) then
                namearr[#namearr + 1] = depname
            end
        end
    end

    namearr[#namearr + 1] = mod.name
    return namearr
end


function Flatten:exist(arr, value)
    for i = 1, #arr do
        if arr[i] == value then
            return true
        end
    end
    return false
end


function Flatten:save(arr, tofile)
    local outfd, outerr = io.open(tofile, "w")
    if not outfd then
        io.stderr:write(outerr)
        os.exit(1)
    end
    for i = 1, #arr do
        local fname = arr[i]..".lua"
        local infd, inerr = io.open(fname, "r")
        if not infd then
            io.stderr:write(inerr)
            os.exit(1)
        end
        for line in infd:lines() do
            local isRequireMod = string.match(line, RErequireDep)
            local isReturnMod = string.match(line, REreturnDep)
            if not isRequireMod and not isReturnMod then
                outfd:write(line.."\n")
            end
        end
        infd:close()
    end
    outfd:close()
end


return Flatten
