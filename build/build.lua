local Os = require("build/os")
local Flatten = require("build/flatten")
BUILD = {
    default_cmd = "gcc -o @out @in @lib -I @inc -O2 -Wall -lm -ldl",
    help_msg = [=[
Usage: lua build/build.lua <in> <out> <lib> <inc> <"command">
       <"command"> is string containing @in, @out, @lib and @inc.
       ------
       @in: input lua script
       @out: output executable file
       @lib: lua 5.3.3 static library (liblua53.a)
       @inc: lua 5.3.3 include directory (include/)
       ------
       Default command is "%s".
       We will replace @in with your <in> and so on.
Example:
       lua build/build.lua llua.lua llua path_to_lib path_to_inc \
       "%s"
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
  @cee_here
  lua_close(L);
  return @pcall_status_here;
}
]],
}


function BUILD:main()
    if #arg < 2 then
        self:help()
    end
    if #arg >= 6 then
        io.stderr:write("Error: too many arguments."
        .." Maybe you forget to use quotes(\") with command?\n\n")
        self:help()
    end

    local in_file = arg[1]
    local out_file = arg[2]
    local lib_file = arg[3]
    local inc_dir = arg[4]
    local cmd = arg[5] or self.default_cmd

    local flatten_file = in_file..".flatten"
    local cee_file = in_file..".cee"
    local c_file = in_file..".c"
    self:flatten(in_file, flatten_file)
    self:convert(flatten_file, cee_file)
    self:generate(cee_file, c_file)

    cmd = string.gsub(cmd, "@inc", inc_dir)
    cmd = string.gsub(cmd, "@lib", lib_file)
    cmd = string.gsub(cmd, "@in", c_file)
    cmd = string.gsub(cmd, "@out", out_file)
    Os:recognize()
    Os:run(cmd)
    Os:rm(flatten_file)
    Os:rm(cee_file)
    Os:rm(c_file)
end


function BUILD:help()
    io.stderr:write(string.format(self.help_msg, self.default_cmd, self.default_cmd))
    os.exit(1)
end


function BUILD:flatten(file, flatten_file)
    Flatten:flatten(file, flatten_file)
end


function BUILD:convert(file, cee_file)
    io.output(cee_file)
    arg = { "+"..file, self.pcall_status }
    dofile("build/bin2cee.lua")
    io.output():close()
    io.output(io.stdout)
end


function BUILD:generate(cee_file, c_file)
    local ceefd, ceeerr = io.open(cee_file, "r")
    if not ceefd then
        error(ceeerr)
    end
    local cee = ceefd:read("*all")
    ceefd:close()

    local out = self.c_template
    out = string.gsub(out, "@cee_here", cee)
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
