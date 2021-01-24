Opcode = {
    testFlag = nil,
    setAFlag = nil,
    argBMode = nil,
    argCMode = nil,
    opMode   = nil,
    name     = nil,
}

function Opcode:new(testFlag, setAFlag, argBMode, argCMode, opMode, name)
    Opcode.__index = Opcode
    self = setmetatable({}, Opcode)
    self.testFlag = testFlag
    self.setAFlag = setAFlag
    self.argBMode = argBMode
    self.argCMode = argCMode
    self.opMode = opMode
    self.name = name
    return self
end


OPMODE = {
    IABC   = 1, -- [  B:9  ][  C:9  ][ A:8  ][OP:6]
    IABx   = 2, -- [      Bx:18     ][ A:8  ][OP:6]
    IAsBx  = 3, -- [     sBx:18     ][ A:8  ][OP:6]
    IAx    = 4, -- [           Ax:26        ][OP:6]
}


OPARGMASK = {
    OpArgN = 1, -- argument is not used
    OpArgU = 2, -- argument is used
    OpArgR = 3, -- argument is a register or a jump offset
    OpArgK = 4, -- argument is a constant or register/constant
}


OPCODE = {
    OP_MOVE     = 1,
    OP_LOADK    = 2,
    OP_LOADKX   = 3,
    OP_LOADBOOL = 4,
    OP_LOADNIL  = 5,
    OP_GETUPVAL = 6,
    OP_GETTABUP = 7,
    OP_GETTABLE = 8,
    OP_SETTABUP = 9,
    OP_SETUPVAL = 10,
    OP_SETTABLE = 11,
    OP_NEWTABLE = 12,
    OP_SELF     = 13,
    OP_ADD      = 14,
    OP_SUB      = 15,
    OP_MUL      = 16,
    OP_MOD      = 17,
    OP_POW      = 18,
    OP_DIV      = 19,
    OP_IDIV     = 20,
    OP_BAND     = 21,
    OP_BOR      = 22,
    OP_BXOR     = 23,
    OP_SHL      = 24,
    OP_SHR      = 25,
    OP_UNM      = 26,
    OP_BNOT     = 27,
    OP_NOT      = 28,
    OP_LEN      = 29,
    OP_CONCAT   = 30,
    OP_JMP      = 31,
    OP_EQ       = 32,
    OP_LT       = 33,
    OP_LE       = 34,
    OP_TEST     = 35,
    OP_TESTSET  = 36,
    OP_CALL     = 37,
    OP_TAILCALL = 38,
    OP_RETURN   = 39,
    OP_FORLOOP  = 40,
    OP_FORPREP  = 41,
    OP_TFORCALL = 42,
    OP_TFORLOOP = 43,
    OP_SETLIST  = 44,
    OP_CLOSURE  = 45,
    OP_VARARG   = 46,
    OP_EXTRAARG = 47,
}


Opcodes = {
--                  T, A, argBMode,         argCMode,         opMode,       name
    Opcode:new(0, 1, OPARGMASK.OpArgR, OPARGMASK.OpArgN, OPMODE.IABC,  "MOVE    "), -- R(A) := R(B)
    Opcode:new(0, 1, OPARGMASK.OpArgK, OPARGMASK.OpArgN, OPMODE.IABx,  "LOADK   "), -- R(A) := Kst(Bx)
    Opcode:new(0, 1, OPARGMASK.OpArgN, OPARGMASK.OpArgN, OPMODE.IABx,  "LOADKX  "), -- R(A) := Kst(extra arg)
    Opcode:new(0, 1, OPARGMASK.OpArgU, OPARGMASK.OpArgU, OPMODE.IABC,  "LOADBOOL"), -- R(A) := (bool)B; if (C) pc++
    Opcode:new(0, 1, OPARGMASK.OpArgU, OPARGMASK.OpArgN, OPMODE.IABC,  "LOADNIL "), -- R(A), R(A+1), ..., R(A+B) := nil
    Opcode:new(0, 1, OPARGMASK.OpArgU, OPARGMASK.OpArgN, OPMODE.IABC,  "GETUPVAL"), -- R(A) := UpValue[B]
    Opcode:new(0, 1, OPARGMASK.OpArgU, OPARGMASK.OpArgK, OPMODE.IABC,  "GETTABUP"), -- R(A) := UpValue[B][RK(C)]
    Opcode:new(0, 1, OPARGMASK.OpArgR, OPARGMASK.OpArgK, OPMODE.IABC,  "GETTABLE"), -- R(A) := R(B)[RK(C)]
    Opcode:new(0, 0, OPARGMASK.OpArgK, OPARGMASK.OpArgK, OPMODE.IABC,  "SETTABUP"), -- UpValue[A][RK(B)] := RK(C)
    Opcode:new(0, 0, OPARGMASK.OpArgU, OPARGMASK.OpArgN, OPMODE.IABC,  "SETUPVAL"), -- UpValue[B] := R(A)
    Opcode:new(0, 0, OPARGMASK.OpArgK, OPARGMASK.OpArgK, OPMODE.IABC,  "SETTABLE"), -- R(A)[RK(B)] := RK(C)
    Opcode:new(0, 1, OPARGMASK.OpArgU, OPARGMASK.OpArgU, OPMODE.IABC,  "NEWTABLE"), -- R(A) := {} (size = B,C)
    Opcode:new(0, 1, OPARGMASK.OpArgR, OPARGMASK.OpArgK, OPMODE.IABC,  "SELF    "), -- R(A+1) := R(B); R(A) := R(B)[RK(C)]
    Opcode:new(0, 1, OPARGMASK.OpArgK, OPARGMASK.OpArgK, OPMODE.IABC,  "ADD     "), -- R(A) := RK(B) + RK(C)
    Opcode:new(0, 1, OPARGMASK.OpArgK, OPARGMASK.OpArgK, OPMODE.IABC,  "SUB     "), -- R(A) := RK(B) - RK(C)
    Opcode:new(0, 1, OPARGMASK.OpArgK, OPARGMASK.OpArgK, OPMODE.IABC,  "MUL     "), -- R(A) := RK(B) * RK(C)
    Opcode:new(0, 1, OPARGMASK.OpArgK, OPARGMASK.OpArgK, OPMODE.IABC,  "MOD     "), -- R(A) := RK(B) % RK(C)
    Opcode:new(0, 1, OPARGMASK.OpArgK, OPARGMASK.OpArgK, OPMODE.IABC,  "POW     "), -- R(A) := RK(B) ^ RK(C)
    Opcode:new(0, 1, OPARGMASK.OpArgK, OPARGMASK.OpArgK, OPMODE.IABC,  "DIV     "), -- R(A) := RK(B) / RK(C)
    Opcode:new(0, 1, OPARGMASK.OpArgK, OPARGMASK.OpArgK, OPMODE.IABC,  "IDIV    "), -- R(A) := RK(B) // RK(C)
    Opcode:new(0, 1, OPARGMASK.OpArgK, OPARGMASK.OpArgK, OPMODE.IABC,  "BAND    "), -- R(A) := RK(B) & RK(C)
    Opcode:new(0, 1, OPARGMASK.OpArgK, OPARGMASK.OpArgK, OPMODE.IABC,  "BOR     "), -- R(A) := RK(B) | RK(C)
    Opcode:new(0, 1, OPARGMASK.OpArgK, OPARGMASK.OpArgK, OPMODE.IABC,  "BXOR    "), -- R(A) := RK(B) ~ RK(C)
    Opcode:new(0, 1, OPARGMASK.OpArgK, OPARGMASK.OpArgK, OPMODE.IABC,  "SHL     "), -- R(A) := RK(B) << RK(C)
    Opcode:new(0, 1, OPARGMASK.OpArgK, OPARGMASK.OpArgK, OPMODE.IABC,  "SHR     "), -- R(A) := RK(B) >> RK(C)
    Opcode:new(0, 1, OPARGMASK.OpArgR, OPARGMASK.OpArgN, OPMODE.IABC,  "UNM     "), -- R(A) := -R(B)
    Opcode:new(0, 1, OPARGMASK.OpArgR, OPARGMASK.OpArgN, OPMODE.IABC,  "BNOT    "), -- R(A) := ~R(B)
    Opcode:new(0, 1, OPARGMASK.OpArgR, OPARGMASK.OpArgN, OPMODE.IABC,  "NOT     "), -- R(A) := not R(B)
    Opcode:new(0, 1, OPARGMASK.OpArgR, OPARGMASK.OpArgN, OPMODE.IABC,  "LEN     "), -- R(A) := length of R(B)
    Opcode:new(0, 1, OPARGMASK.OpArgR, OPARGMASK.OpArgR, OPMODE.IABC,  "CONCAT  "), -- R(A) := R(B).. ... ..R(C)
    Opcode:new(0, 0, OPARGMASK.OpArgR, OPARGMASK.OpArgN, OPMODE.IAsBx, "JMP     "), -- pc+=sBx; if (A) close all upvalues >= R(A - 1)
    Opcode:new(1, 0, OPARGMASK.OpArgK, OPARGMASK.OpArgK, OPMODE.IABC,  "EQ      "), -- if ((RK(B) == RK(C)) ~= A) then pc++
    Opcode:new(1, 0, OPARGMASK.OpArgK, OPARGMASK.OpArgK, OPMODE.IABC,  "LT      "), -- if ((RK(B) <  RK(C)) ~= A) then pc++
    Opcode:new(1, 0, OPARGMASK.OpArgK, OPARGMASK.OpArgK, OPMODE.IABC,  "LE      "), -- if ((RK(B) <= RK(C)) ~= A) then pc++
    Opcode:new(1, 0, OPARGMASK.OpArgN, OPARGMASK.OpArgU, OPMODE.IABC,  "TEST    "), -- if not (R(A) <=> C) then pc++
    Opcode:new(1, 1, OPARGMASK.OpArgR, OPARGMASK.OpArgU, OPMODE.IABC,  "TESTSET "), -- if (R(B) <=> C) then R(A) := R(B) else pc++
    Opcode:new(0, 1, OPARGMASK.OpArgU, OPARGMASK.OpArgU, OPMODE.IABC,  "CALL    "), -- R(A), ... ,R(A+C-2) := R(A)(R(A+1), ... ,R(A+B-1))
    Opcode:new(0, 1, OPARGMASK.OpArgU, OPARGMASK.OpArgU, OPMODE.IABC,  "TAILCALL"), -- return R(A)(R(A+1), ... ,R(A+B-1))
    Opcode:new(0, 0, OPARGMASK.OpArgU, OPARGMASK.OpArgN, OPMODE.IABC,  "RETURN  "), -- return R(A), ... ,R(A+B-2)
    Opcode:new(0, 1, OPARGMASK.OpArgR, OPARGMASK.OpArgN, OPMODE.IAsBx, "FORLOOP "), -- R(A)+=R(A+2); if R(A) <?= R(A+1) then { pc+=sBx; R(A+3)=R(A) }
    Opcode:new(0, 1, OPARGMASK.OpArgR, OPARGMASK.OpArgN, OPMODE.IAsBx, "FORPREP "), -- R(A)-=R(A+2); pc+=sBx
    Opcode:new(0, 0, OPARGMASK.OpArgN, OPARGMASK.OpArgU, OPMODE.IABC,  "TFORCALL"), -- R(A+3), ... ,R(A+2+C) := R(A)(R(A+1), R(A+2));
    Opcode:new(0, 1, OPARGMASK.OpArgR, OPARGMASK.OpArgN, OPMODE.IAsBx, "TFORLOOP"), -- if R(A+1) ~= nil then { R(A)=R(A+1); pc += sBx }
    Opcode:new(0, 0, OPARGMASK.OpArgU, OPARGMASK.OpArgU, OPMODE.IABC,  "SETLIST "), -- R(A)[(C-1)*FPF+i] := R(A+i), 1 <= i <= B
    Opcode:new(0, 1, OPARGMASK.OpArgU, OPARGMASK.OpArgN, OPMODE.IABx,  "CLOSURE "), -- R(A) := closure(KPROTO[Bx])
    Opcode:new(0, 1, OPARGMASK.OpArgU, OPARGMASK.OpArgN, OPMODE.IABC,  "VARARG  "), -- R(A), R(A+1), ..., R(A+B-2) = vararg
    Opcode:new(0, 0, OPARGMASK.OpArgU, OPARGMASK.OpArgU, OPMODE.IAx,   "EXTRAARG"), -- extra (larger) argument for previous opcode
}

