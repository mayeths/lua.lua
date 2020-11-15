Env = {}

function Env:updateSearchPath(pattern)
    local command = "pwd"
    if package.config:sub(1,1) == "\\" then
        command = "cd"
    end
    local cdHandle = io.popen(command)
    local runPath = cdHandle:read("*a"):sub(1, -2)
    local srcDir = string.format("%s/%s", runPath, pattern)
    package.path = string.format("%s;%s", srcDir, package.path)
    cdHandle:close()
end

return Env
