local Color = require("common/color")
local Throw = {
    mode = "release",
}


function Throw:error(fmt, ...)
    if type(fmt) ~= "string" then
        error("arg fmt is not string type")
    end
    if #{...} ~= 0 then
        fmt = string.format(fmt, ...)
    end
    if self.mode == "release" then
        fmt = Color:red("ERROR ")..fmt.."\n"
        io.stderr:write(fmt)
        os.exit(1)
    elseif self.mode == "debug" then
        error(fmt, 2)
    else
        error("Unknown throw mode "..self.mode)
    end
end


function Throw:setReleaseMode()
    self.mode = "release"
end


function Throw:setDebugMode()
    self.mode = "debug"
end


return Throw

