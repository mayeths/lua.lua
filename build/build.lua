local Os = require("build/os")
local Flatten = require("build/flatten")
BUILD = {
    help_msg = [=[
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
      lua build/build.lua llua.lua llua path_to_lib path_to_inc \
      "gcc -o @out @in @lib -I @inc -O2 -Wall -lm -ldl"
]=],
    pcall_status = "_ret_status",
    c_template = [[
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
]],
}


function BUILD:main()
    if #arg >= 6 then
        self:help("ERROR too many arguments."
        .." Maybe you forget to use quotes(\") with command?")
    end
    dofile("build/dotenv.lua")
    local in_file = self:parse("<in>", 1, "IN")
    local out_file = self:parse("<out>", 2, "OUT")
    local lib_file = self:parse("<lib>", 3, "LIB")
    local inc_dir = self:parse("<inc>", 4, "INC")
    local cmd = self:parse('<"command">', 5, "COMMAND")

    Os:recognize()
    Os:mkdir("dist/")
    local flatten_file = "dist/"..in_file..".flatten"
    local cee_file = "dist/"..in_file..".cee"
    local c_file = "dist/"..in_file..".c"
    local target = "dist/"..out_file
    self:flatten(in_file, flatten_file)
    self:convert(flatten_file, cee_file)
    self:generate(cee_file, c_file)

    cmd = string.gsub(cmd, "@inc", inc_dir)
    cmd = string.gsub(cmd, "@lib", lib_file)
    cmd = string.gsub(cmd, "@in", c_file)
    cmd = string.gsub(cmd, "@out", target)
    print(cmd)
    Os:run(cmd)
    Os:rm(flatten_file)
    Os:rm(cee_file)
    Os:rm(c_file)
end


function BUILD:parse(name, argidx, envname)
    if not arg[argidx] and not _G[envname] then
        self:help("ERROR cannot find "..name
        .." in arguments or "..envname.." in .env file.")
    end
    return arg[argidx] or _G[envname]
end


function BUILD:help(prefix)
    if prefix then
        io.stderr:write(prefix.."\n")
    end
    io.stderr:write(self.help_msg)
    os.exit(1)
end


function BUILD:flatten(file, flatten_file)
    Flatten:flatten(file, flatten_file)
end


function BUILD:convert(file, cee_file)
    local temp = arg
    arg = { "+"..file, self.pcall_status }
    io.output(cee_file)
    dofile("build/bin2cee.lua")
    io.output():close()
    io.output(io.stdout)
    arg = temp
end


function BUILD:generate(cee_file, c_file)
    local ceefd, ceeerr = io.open(cee_file, "r")
    if not ceefd then
        error(ceeerr)
    end
    local cee = ceefd:read("*all")
    ceefd:close()

    local out = self.c_template
    out = string.gsub(out, "@cee_section_here", cee)
    out = string.gsub(out, "@pcall_status_here", self.pcall_status)
    local outfd, outerr = io.open(c_file, "w")
    if not outfd then
        io.stderr:write(outerr.."\n")
        os.exit(1)
    end
    outfd:write(out)
    outfd:close()
end


BUILD:main()
