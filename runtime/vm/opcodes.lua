local Action = require("runtime/vm/action")
local OPCODE = require("lua/opcode")
local OPMODE = require("lua/opmode")
local OPARGMASK = require("lua/opargmask")

local Opcode = {
    testFlag = nil,
    setAFlag = nil,
    argBMode = nil,
    argCMode = nil,
    opMode   = nil,
    name     = nil,
    action   = nil,
}

function Opcode:new(testFlag, setAFlag, argBMode, argCMode, opMode, name, action)
    Opcode.__index = Opcode
    self = setmetatable({}, Opcode)
    self.testFlag = testFlag
    self.setAFlag = setAFlag
    self.argBMode = argBMode
    self.argCMode = argCMode
    self.opMode = opMode
    self.name = name
    self.action = action
    return self
end


local Opcodes = {
    --         T, A, argBMode,         argCMode,         opMode,       name        action
    Opcode:new(0, 1, OPARGMASK.OpArgR, OPARGMASK.OpArgN, OPMODE.IABC,  "MOVE    ", Action.move), -- R(A) := R(B)
    Opcode:new(0, 1, OPARGMASK.OpArgK, OPARGMASK.OpArgN, OPMODE.IABx,  "LOADK   ", Action.loadK), -- R(A) := Kst(Bx)
    Opcode:new(0, 1, OPARGMASK.OpArgN, OPARGMASK.OpArgN, OPMODE.IABx,  "LOADKX  ", Action.loadKx), -- R(A) := Kst(extra arg)
    Opcode:new(0, 1, OPARGMASK.OpArgU, OPARGMASK.OpArgU, OPMODE.IABC,  "LOADBOOL", Action.loadBool), -- R(A) := (bool)B; if (C) pc++
    Opcode:new(0, 1, OPARGMASK.OpArgU, OPARGMASK.OpArgN, OPMODE.IABC,  "LOADNIL ", Action.loadNil), -- R(A), R(A+1), ..., R(A+B) := nil
    Opcode:new(0, 1, OPARGMASK.OpArgU, OPARGMASK.OpArgN, OPMODE.IABC,  "GETUPVAL", nil), -- R(A) := UpValue[B]
    Opcode:new(0, 1, OPARGMASK.OpArgU, OPARGMASK.OpArgK, OPMODE.IABC,  "GETTABUP", nil), -- R(A) := UpValue[B][RK(C)]
    Opcode:new(0, 1, OPARGMASK.OpArgR, OPARGMASK.OpArgK, OPMODE.IABC,  "GETTABLE", Action.getTable), -- R(A) := R(B)[RK(C)]
    Opcode:new(0, 0, OPARGMASK.OpArgK, OPARGMASK.OpArgK, OPMODE.IABC,  "SETTABUP", nil), -- UpValue[A][RK(B)] := RK(C)
    Opcode:new(0, 0, OPARGMASK.OpArgU, OPARGMASK.OpArgN, OPMODE.IABC,  "SETUPVAL", nil), -- UpValue[B] := R(A)
    Opcode:new(0, 0, OPARGMASK.OpArgK, OPARGMASK.OpArgK, OPMODE.IABC,  "SETTABLE", Action.setTable), -- R(A)[RK(B)] := RK(C)
    Opcode:new(0, 1, OPARGMASK.OpArgU, OPARGMASK.OpArgU, OPMODE.IABC,  "NEWTABLE", Action.newTable), -- R(A) := {} (size = B,C)
    Opcode:new(0, 1, OPARGMASK.OpArgR, OPARGMASK.OpArgK, OPMODE.IABC,  "SELF    ", Action.self), -- R(A+1) := R(B); R(A) := R(B)[RK(C)]
    Opcode:new(0, 1, OPARGMASK.OpArgK, OPARGMASK.OpArgK, OPMODE.IABC,  "ADD     ", Action.add), -- R(A) := RK(B) + RK(C)
    Opcode:new(0, 1, OPARGMASK.OpArgK, OPARGMASK.OpArgK, OPMODE.IABC,  "SUB     ", Action.sub), -- R(A) := RK(B) - RK(C)
    Opcode:new(0, 1, OPARGMASK.OpArgK, OPARGMASK.OpArgK, OPMODE.IABC,  "MUL     ", Action.mul), -- R(A) := RK(B) * RK(C)
    Opcode:new(0, 1, OPARGMASK.OpArgK, OPARGMASK.OpArgK, OPMODE.IABC,  "MOD     ", Action.mod), -- R(A) := RK(B) % RK(C)
    Opcode:new(0, 1, OPARGMASK.OpArgK, OPARGMASK.OpArgK, OPMODE.IABC,  "POW     ", Action.pow), -- R(A) := RK(B) ^ RK(C)
    Opcode:new(0, 1, OPARGMASK.OpArgK, OPARGMASK.OpArgK, OPMODE.IABC,  "DIV     ", Action.div), -- R(A) := RK(B) / RK(C)
    Opcode:new(0, 1, OPARGMASK.OpArgK, OPARGMASK.OpArgK, OPMODE.IABC,  "IDIV    ", Action.idiv), -- R(A) := RK(B) // RK(C)
    Opcode:new(0, 1, OPARGMASK.OpArgK, OPARGMASK.OpArgK, OPMODE.IABC,  "BAND    ", Action.band), -- R(A) := RK(B) & RK(C)
    Opcode:new(0, 1, OPARGMASK.OpArgK, OPARGMASK.OpArgK, OPMODE.IABC,  "BOR     ", Action.bor), -- R(A) := RK(B) | RK(C)
    Opcode:new(0, 1, OPARGMASK.OpArgK, OPARGMASK.OpArgK, OPMODE.IABC,  "BXOR    ", Action.bxor), -- R(A) := RK(B) ~ RK(C)
    Opcode:new(0, 1, OPARGMASK.OpArgK, OPARGMASK.OpArgK, OPMODE.IABC,  "SHL     ", Action.shl), -- R(A) := RK(B) << RK(C)
    Opcode:new(0, 1, OPARGMASK.OpArgK, OPARGMASK.OpArgK, OPMODE.IABC,  "SHR     ", Action.shr), -- R(A) := RK(B) >> RK(C)
    Opcode:new(0, 1, OPARGMASK.OpArgR, OPARGMASK.OpArgN, OPMODE.IABC,  "UNM     ", Action.unm), -- R(A) := -R(B)
    Opcode:new(0, 1, OPARGMASK.OpArgR, OPARGMASK.OpArgN, OPMODE.IABC,  "BNOT    ", Action.bnot), -- R(A) := ~R(B)
    Opcode:new(0, 1, OPARGMASK.OpArgR, OPARGMASK.OpArgN, OPMODE.IABC,  "NOT     ", Action.no), -- R(A) := not R(B)
    Opcode:new(0, 1, OPARGMASK.OpArgR, OPARGMASK.OpArgN, OPMODE.IABC,  "LEN     ", Action.length), -- R(A) := length of R(B)
    Opcode:new(0, 1, OPARGMASK.OpArgR, OPARGMASK.OpArgR, OPMODE.IABC,  "CONCAT  ", Action.concat), -- R(A) := R(B).. ... ..R(C)
    Opcode:new(0, 0, OPARGMASK.OpArgR, OPARGMASK.OpArgN, OPMODE.IAsBx, "JMP     ", Action.jmp), -- pc+=sBx; if (A) close all upvalues >= R(A - 1)
    Opcode:new(1, 0, OPARGMASK.OpArgK, OPARGMASK.OpArgK, OPMODE.IABC,  "EQ      ", Action.eq), -- if ((RK(B) == RK(C)) ~= A) then pc++
    Opcode:new(1, 0, OPARGMASK.OpArgK, OPARGMASK.OpArgK, OPMODE.IABC,  "LT      ", Action.lt), -- if ((RK(B) <  RK(C)) ~= A) then pc++
    Opcode:new(1, 0, OPARGMASK.OpArgK, OPARGMASK.OpArgK, OPMODE.IABC,  "LE      ", Action.le), -- if ((RK(B) <= RK(C)) ~= A) then pc++
    Opcode:new(1, 0, OPARGMASK.OpArgN, OPARGMASK.OpArgU, OPMODE.IABC,  "TEST    ", Action.test), -- if not (R(A) <=> C) then pc++
    Opcode:new(1, 1, OPARGMASK.OpArgR, OPARGMASK.OpArgU, OPMODE.IABC,  "TESTSET ", Action.testSet), -- if (R(B) <=> C) then R(A) := R(B) else pc++
    Opcode:new(0, 1, OPARGMASK.OpArgU, OPARGMASK.OpArgU, OPMODE.IABC,  "CALL    ", Action.call), -- R(A), ... ,R(A+C-2) := R(A)(R(A+1), ... ,R(A+B-1))
    Opcode:new(0, 1, OPARGMASK.OpArgU, OPARGMASK.OpArgU, OPMODE.IABC,  "TAILCALL", Action.tailCall), -- return R(A)(R(A+1), ... ,R(A+B-1))
    Opcode:new(0, 0, OPARGMASK.OpArgU, OPARGMASK.OpArgN, OPMODE.IABC,  "RETURN  ", Action._return), -- return R(A), ... ,R(A+B-2)
    Opcode:new(0, 1, OPARGMASK.OpArgR, OPARGMASK.OpArgN, OPMODE.IAsBx, "FORLOOP ", Action.forLoop), -- R(A)+=R(A+2); if R(A) <?= R(A+1) then { pc+=sBx; R(A+3)=R(A) }
    Opcode:new(0, 1, OPARGMASK.OpArgR, OPARGMASK.OpArgN, OPMODE.IAsBx, "FORPREP ", Action.forPrep), -- R(A)-=R(A+2); pc+=sBx
    Opcode:new(0, 0, OPARGMASK.OpArgN, OPARGMASK.OpArgU, OPMODE.IABC,  "TFORCALL", nil), -- R(A+3), ... ,R(A+2+C) := R(A)(R(A+1), R(A+2));
    Opcode:new(0, 1, OPARGMASK.OpArgR, OPARGMASK.OpArgN, OPMODE.IAsBx, "TFORLOOP", nil), -- if R(A+1) ~= nil then { R(A)=R(A+1); pc += sBx }
    Opcode:new(0, 0, OPARGMASK.OpArgU, OPARGMASK.OpArgU, OPMODE.IABC,  "SETLIST ", Action.setList), -- R(A)[(C-1)*FPF+i] := R(A+i), 1 <= i <= B
    Opcode:new(0, 1, OPARGMASK.OpArgU, OPARGMASK.OpArgN, OPMODE.IABx,  "CLOSURE ", Action.closure), -- R(A) := closure(KPROTO[Bx])
    Opcode:new(0, 1, OPARGMASK.OpArgU, OPARGMASK.OpArgN, OPMODE.IABC,  "VARARG  ", Action.vararg), -- R(A), R(A+1), ..., R(A+B-2) = vararg
    Opcode:new(0, 0, OPARGMASK.OpArgU, OPARGMASK.OpArgU, OPMODE.IAx,   "EXTRAARG", nil), -- extra (larger) argument for previous opcode
}


return Opcodes, OPCODE, OPMODE, OPARGMASK
