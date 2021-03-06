local Opcodes = require("runtime/vm/opcodes")

local Instruction = {
    value = nil,
    MAXARG_Bx = (1 << 18) - 1,         -- 262143
    MAXARG_sBx = ((1 << 18) - 1) >> 1, -- 131071
}

--[[
 31       22       13       5    0
  +-------+^------+-^-----+-^-----
  |b=9bits |c=9bits |a=8bits|op=6|
  +-------+^------+-^-----+-^-----
  |    bx=18bits    |a=8bits|op=6|
  +-------+^------+-^-----+-^-----
  |   sbx=18bits    |a=8bits|op=6|
  +-------+^------+-^-----+-^-----
  |    ax=26bits            |op=6|
  +-------+^------+-^-----+-^-----
 31      23      15       7      0
]]

function Instruction:new(value)
    Instruction.__index = Instruction
    self = setmetatable({}, Instruction)
    self.value = value or 0
    return self
end


function Instruction:Opcode()
    return (self.value & 0x3F)
end


function Instruction:ABC()
    local a = (self.value >> 6) & 0xFF
    local c = (self.value >> 14) & 0x1FF
    local b = (self.value >> 23) & 0x1FF
    return a, b, c
end


function Instruction:ABx()
    local a = (self.value >> 6) & 0xFF
    local bx = (self.value >> 14)
    return a, bx
end


function Instruction:AsBx()
    local a, bx = self:ABx()
    return a, bx - Instruction.MAXARG_sBx
end


function Instruction:Ax()
    return (self.value >> 6)
end


function Instruction:OpName()
    return Opcodes[self:Opcode() + 1].name
end


function Instruction:OpMode()
    return Opcodes[self:Opcode() + 1].opMode
end


function Instruction:BMode()
    return Opcodes[self:Opcode() + 1].argBMode
end


function Instruction:CMode()
    return Opcodes[self:Opcode() + 1].argCMode
end


return Instruction
