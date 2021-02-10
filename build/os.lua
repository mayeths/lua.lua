local Os = {
    current = "unknown",
}


function Os:recognize()
    local s = package.config:sub(1,1)
    if s == "/" then
        self.current = "unix-like"
    elseif s == "\\" then
        self.current = "windows"
    else
        self.current = "unknown"
    end
end


function Os:run(cmd)
    if self.current == "unix-like" then
        os.execute(cmd)
    elseif self.current == "windows" then
        os.execute(cmd)
    else
        error("No command \"rm\" is provided for system "..self.current)
    end
end


function Os:rm(file)
    local cmd
    if self.current == "unix-like" then
        cmd = "yes | rm %s 2>/dev/null"
    elseif self.current == "windows" then
        cmd = "del /f %s 2> nul"
    else
        error("No command \"rm\" is provided for system "..self.current)
    end
    cmd = string.format(cmd, file)
    os.execute(cmd)
end


return Os
