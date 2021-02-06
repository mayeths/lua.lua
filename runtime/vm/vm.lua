local Opcodes = require("runtime/vm/opcodes")
local Util = require("common/util")
local Throw = require("common/throw")

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
