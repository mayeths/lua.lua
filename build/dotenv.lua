-- https://github.com/motdotla/dotenv#rules
local fd, err = io.open(".env", "r")
if not fd then
    io.stderr:write(err.."\n")
    os.exit(1)
end

local reCommentLine = "^(#)(.*)"
local reEmptyLine   = "^(%s*)"
local reEmptyStr    = "^(%w[a-zA-Z0-9_]*)=$"
local reSquoteStr   = ""
local reDquoteStr   = ""
local reNormalStr   = "^(%w[a-zA-Z0-9_]*)=(.*)"

for line in fd:lines() do
    if string.sub(line, #line, #line) == "\r" then
        line = string.sub(line, 1, #line - 1)
    end
    local name, value = string.match(line, reNormalStr)
    if name then
        _G[name] = value
    end
end

fd:close()