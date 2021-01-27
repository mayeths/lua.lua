-- Mount LuaState functions from following files
-- These api implement http://www.lua.org/manual/5.3/manual.html#4.8
require("runtime/state/APIOperateValue")
require("runtime/state/APIPushValue")
require("runtime/state/APIValueType")
require("runtime/state/APIVM")
require("runtime/state/APITable")
require("runtime/state/APICall")

return require("runtime/state/luastate")
