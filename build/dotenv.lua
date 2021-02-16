local fd, err = io.open(".env", "r")
if not fd then
    io.stderr:write(err.."\n")
    os.exit(1)
end

for line in fd:lines() do
    if string.sub(line, #line, #line) == "\r" then
        line = string.sub(line, 1, #line - 1)
    end
    local name, value = string.match(line, "^(%w[a-zA-Z0-9_]*)=(.*)")
    if name then
        _G[name] = value
    end
end
