local OPARGMASK = {
    OpArgN = 1, -- argument is not used
    OpArgU = 2, -- argument is used
    OpArgR = 3, -- argument is a register or a jump offset
    OpArgK = 4, -- argument is a constant or register/constant
}

return OPARGMASK
