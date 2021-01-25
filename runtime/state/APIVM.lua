local LuaState = require("runtime/state/luastate")

function LuaState:PC()
    return self.pc
end

function LuaState:AddPC(n)
    self.pc = self.pc + n
end


function LuaState:Fetch()
    local i = self.proto.Code[self.pc]
    self.pc = self.pc + 1
    return i
end


function LuaState:GetConst(idx)
    local c = self.proto.Constants[idx + 1]
    self.stack:push(c)
end


function LuaState:GetRK(rk)
    if rk > 0xFF then
        self:GetConst(rk & 0xFF)
    else
        self:PushValue(rk + 1)
    end
end

