Env = {}

function Env:updateSearchPath(pattern)
    local command = "pwd"
    local isWindows = package.config:sub(1,1) == "\\"
    if isWindows then
        command = "cd"
    end
    local cmdHandle = io.popen(command)
    local runPath = cmdHandle:read("*a"):sub(1, -2)
    local srcDir = string.format("%s/%s", runPath, pattern)
    package.path = string.format("%s;%s", srcDir, package.path)
    cmdHandle:close()
end

return Env
