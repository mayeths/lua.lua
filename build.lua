local Build = {
    platform = "unknown",
    RErequire = "(require%s*%()(.*)(%s*%))",
    RErequireDep = "(require%s*%(%s*[\"\'])(.*)([\"\']%s*%))",
    REreturnDep = "^(return)(.*)",
    REcommentLine = "^(#)(.*)",
    REemptyLine   = "^(%s*)",
    REemptyStr    = "^(%w[a-zA-Z0-9_]*)=$",
    REsquoteStr   = "",
    REdquoteStr   = "",
    REnormalStr   = "^(%w[a-zA-Z0-9_]*)=(.*)",
    pcall_status = "_ret_status",
    description = [=[
USAGE
    lua build/build.lua <in> <out> <lib> <inc> <"command">
    "command" is string containing @in, @out, @lib and @inc.
    We will replace @in with your <in> and so on.
    See template.env if dotenv is supported.
    ------
    @in: input lua script
    @out: output executable file
    @lib: lua 5.3.3 static library (liblua53.a)
    @inc: lua 5.3.3 include directory (include/)
    ------
EXAMPLE
    lua build.lua llua.lua llua path_to_lib path_to_inc \
    "gcc -o @out @in @lib -I @inc -O2 -Wall -lm -ldl"
]=],
}



function Build.main()
    if #arg >= 6 then
        Build.help("ERROR too many arguments."
        .." Maybe you forget to use quotes(\") with command?")
    end
    dofile("build/dotenv.lua")
    local in_file = Build.parse("<in>", 1, "IN")
    local out_file = Build.parse("<out>", 2, "OUT")
    local lib_file = Build.parse("<lib>", 3, "LIB")
    local inc_dir = Build.parse("<inc>", 4, "INC")
    local cmd = Build.parse('<"command">', 5, "COMMAND")

    Build.recognize()
    Build.mkdir("dist/")
    local flatten_file = "dist/"..in_file..".flatten"
    local cee_file = "dist/"..in_file..".cee"
    local c_file = "dist/"..in_file..".c"
    local target = "dist/"..out_file
    Build.flatten(in_file, flatten_file)
    Build.convert(flatten_file, cee_file)
    Build.generate(cee_file, c_file)

    cmd = string.gsub(cmd, "@inc", inc_dir)
    cmd = string.gsub(cmd, "@lib", lib_file)
    cmd = string.gsub(cmd, "@in", c_file)
    cmd = string.gsub(cmd, "@out", target)
    print(cmd)
    Build.run(cmd)
    Build.rm(flatten_file)
    Build.rm(cee_file)
    Build.rm(c_file)
end


function Build.parse(name, argidx, envname)
    if not arg[argidx] and not _G[envname] then
        Build.help("ERROR cannot find "..name
        .." in arguments or "..envname.." in .env file.")
    end
    return arg[argidx] or _G[envname]
end


function Build.help(prefix)
    if prefix then
        io.stderr:write(prefix.."\n")
    end
    io.stderr:write(Build.help_msg)
    os.exit(1)
end


function Build.convert(file, cee_file)
    local temp = arg
    arg = { "+"..file, Build.pcall_status }
    io.output(cee_file)
    dofile("build/bin2cee.lua")
    io.output():close()
    io.output(io.stdout)
    arg = temp
end


function Build.generate(cee_file, c_file)
    local ceefd, ceeerr = io.open(cee_file, "r")
    if not ceefd then
        error(ceeerr)
    end
    local cee = ceefd:read("*all")
    ceefd:close()

    local c_out = [[
        /* https://stackoverflow.com/a/1150047/11702338 */
        #include <stdlib.h>
        #include <stdio.h>
        #include "lua.h"
        #include "lauxlib.h"
        #include "lualib.h"
        
        int main(int argc, char *argv[]) {
          int i;
          lua_State *L = luaL_newstate();
          luaL_openlibs(L);
          lua_newtable(L);
          for (i = 1; i < argc; i++) {
            lua_pushnumber(L, i);
            lua_pushstring(L, argv[i]);
            lua_rawset(L, -3);
          }
          int @pcall_status_here;
          lua_setglobal(L, "arg");
          @cee_section_here
          lua_close(L);
          return @pcall_status_here;
        }
    ]]
    c_out = string.gsub(c_out, "@cee_section_here", cee)
    c_out = string.gsub(c_out, "@pcall_status_here", Build.pcall_status)
    local outfd, outerr = io.open(c_file, "w")
    if not outfd then
        io.stderr:write(outerr.."\n")
        os.exit(1)
    end
    outfd:write(c_out)
    outfd:close()
end


function Build.recognize()
    local s = package.config:sub(1,1)
    if s == "/" then
        Build.platform = "unix-like"
    elseif s == "\\" then
        Build.platform = "windows"
    else
        Build.platform = "unknown"
    end
end


function Build.run(cmd)
    if Build.platform == "unix-like" then
        os.execute(cmd)
    elseif Build.platform == "windows" then
        os.execute(cmd)
    else
        error("No command \"rm\" is provided for system "..Build.platform)
    end
end


function Build.mkdir(path)
    local cmd
    if Build.platform == "unix-like" then
        cmd = "mkdir -p %s"
    elseif Build.platform == "windows" then
        cmd = "md %s"
    end
    cmd = string.format(cmd, path)
    os.execute(cmd)
end


function Build.rm(file)
    local cmd
    if Build.platform == "unix-like" then
        cmd = "yes | rm %s 2>/dev/null"
    elseif Build.platform == "windows" then
        cmd = "del /f %s 2> nul"
    else
        error("No command \"rm\" is provided for system "..Build.platform)
    end
    cmd = string.format(cmd, file)
    os.execute(cmd)
end


function Build.dotenv()
    -- https://github.com/motdotla/dotenv#rules
    local fd, err = io.open(".env", "r")
    if not fd then
        io.stderr:write(err.."\n")
        os.exit(1)
    end
    for line in fd:lines() do
        if string.sub(line, #line, #line) == "\r" then
            line = string.sub(line, 1, #line - 1)
        end
        local name, value = string.match(line, Build.REnormalStr)
        if name then
            _G[name] = value
        end
    end
    fd:close()
end


function Build.flatten(infile, outfile)
    local inname = string.match(infile, "(.*)(%.lua)")
    if not inname then
        io.stderr:write(string.format("Not a valid lua script: %s\n", infile))
        os.exit(1)
    end
    local mod = Build.createMod(inname)
    local arr = Build.breaktree(mod)
    Build.save(arr, outfile)
end


function Build.createMod(modname)
    local mod = { name = modname, deps = {} }
    local file, err = io.open(modname..".lua", "r")
    if not file then
        io.stderr:write(err)
        os.exit(1)
    end

    local buf = {}
    for line in file:lines() do
        local req, name = string.match(line, Build.RErequire)
        if req then
            local _, depname = string.match(line, Build.RErequireDep)
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
        mod.deps[#mod.deps + 1] = Build.createMod(depname)
    end

    file:close()
    return mod
end


function Build.breaktree(mod)
    local deparrs = {}
    for i = 1, #mod.deps do
        local dep = mod.deps[i]
        deparrs[#deparrs + 1] = Build.breaktree(dep)
    end

    local namearr = {}
    for i = 1, #deparrs do
        local deparr = deparrs[i]
        for j = 1, #deparr do
            local depname = deparr[j]
            if not Build.exist(namearr, depname) then
                namearr[#namearr + 1] = depname
            end
        end
    end

    namearr[#namearr + 1] = mod.name
    return namearr
end


function Build.exist(arr, value)
    for i = 1, #arr do
        if arr[i] == value then
            return true
        end
    end
    return false
end


function Build.save(arr, tofile)
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
            local isRequireMod = string.match(line, Build.RErequireDep)
            local isReturnMod = string.match(line, Build.REreturnDep)
            if not isRequireMod and not isReturnMod then
                outfd:write(line.."\n")
            end
        end
        infd:close()
    end
    outfd:close()
end


--[[
    http://lua-users.org/wiki/BinToCee
    bin2c is a utility that converts a binary file to a C char
    string that can be embedded in a C program via #include.
]]
function Build.bin2cee()
    local description = [=[
    Usage: lua bin2c.lua [+]filename [status]

    Write a C source file to standard output.  When this C source file is
    included in another C source file, it has the effect of loading and
    running the specified file at that point in the program.

    The file named by 'filename' contains either Lua byte code or Lua source.
    Its contents are used to generate the C output.  If + is used, then the
    contents of 'filename' are first compiled before being used to generate
    the C output.  If given, 'status' names a C variable used to store the
    return value of either luaL_loadbuffer() or lua_pcall().  Otherwise,
    the return values of these functions will be unavailable.

    This program is (overly) careful to generate output identical to the
    output generated by bin2c5.1 from LuaBinaries.

    http://lua-users.org/wiki/BinTwoCee

    Original author: Mark Edgar
    Licensed under the same terms as Lua (MIT license).
    ]=]

    if not arg or not arg[1] then
      io.stderr:write(description)
      return
    end

    local compile, filename = arg[1]:match"^(+?)(.*)"
    local status = arg[2]

    local content = compile=="+"
      and string.dump(assert(loadfile(filename)))
      or assert(io.open(filename,"rb")):read"*a"

    local function boilerplate(fmt)
      return string.format(fmt,
        status and "("..status.."=" or "",
        filename,
        status and ")" or "",
        status and status.."=" or "",
        filename)
    end

    local dump do
      local numtab={}; for i=0,255 do numtab[string.char(i)]=("%3d,"):format(i) end
      function dump(str)
        return (str:gsub(".", numtab):gsub(("."):rep(80), "%0\n"))
      end
    end

    io.write(boilerplate[=[
    /* code automatically generated by bin2c -- DO NOT EDIT */
    {
    /* #include'ing this file in a C program is equivalent to calling
      if (%sluaL_loadfile(L,%q)%s==0) %slua_pcall(L, 0, 0, 0); 
    */
    /* %s */
    static const unsigned char B1[]={
    ]=], dump(content), boilerplate[=[
    
    };
    
     if (%sluaL_loadbuffer(L,(const char*)B1,sizeof(B1),%q)%s==0) %slua_pcall(L, 0, 0, 0);
    }
    ]=])
end


Build.main()
