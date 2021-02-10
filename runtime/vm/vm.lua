local Opcodes = require("runtime/vm/opcodes")
local Throw = require("util/throw")

local VM = {}


function VM.Execute(inst, state)
    local action = Opcodes[inst:Opcode() + 1].action
    if action ~= nil then
        action(inst, state)
    else
        Throw:error(inst:OpName().." is not implemented.")
    end
end


return VM
