local LuaState = require("runtime/state/luastate")
local LuaClosure = require("runtime/state/luaclosure")

function LuaState:PC()
    return self.stack.pc
end

function LuaState:AddPC(n)
    self.stack.pc = self.stack.pc + n
end


function LuaState:Fetch()
    self.stack.pc = self.stack.pc + 1
    local i = self.stack.closure.proto.Code[self.stack.pc]
    return i
end


function LuaState:GetConst(idx)
    local c = self.stack.closure.proto.Constants[idx + 1]
    self.stack:push(c)
end


function LuaState:GetRK(rk)
    if rk > 0xFF then
        self:GetConst(rk & 0xFF)
    else
        self:PushValue(rk + 1)
    end
end


function LuaState:RegisterCount()
    return self.stack.closure.proto.MaxStackSize
end


function LuaState:LoadVararg(n)
    if n < 0 then
        n = #self.stack.varargs
    end
    self.stack:ensure(n)
    self.stack:pushN(self.stack.varargs, n)
end


function LuaState:LoadProto(idx)
    local proto = self.stack.closure.proto.Protos[idx]
    local closure = LuaClosure:new(proto)
    self.stack:push(closure)
end

