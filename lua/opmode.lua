local OPMODE = {
    IABC   = 1, -- [  B:9  ][  C:9  ][ A:8  ][OP:6]
    IABx   = 2, -- [      Bx:18     ][ A:8  ][OP:6]
    IAsBx  = 3, -- [     sBx:18     ][ A:8  ][OP:6]
    IAx    = 4, -- [           Ax:26        ][OP:6]
}

return OPMODE
