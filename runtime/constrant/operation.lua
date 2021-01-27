local Operation = {
    -- https://github.com/lua/lua/blob/master/lua.h#L205
    LUA_OPADD  = 0,
    LUA_OPSUB  = 1,
    LUA_OPMUL  = 2,
    LUA_OPMOD  = 3,
    LUA_OPPOW  = 4,
    LUA_OPDIV  = 5,
    LUA_OPIDIV = 6,
    LUA_OPBAND = 7,
    LUA_OPBOR  = 8,
    LUA_OPBXOR = 9,
    LUA_OPSHL  = 10,
    LUA_OPSHR  = 11,
    LUA_OPUNM  = 12,
    LUA_OPBNOT = 13,
    -- https://github.com/lua/lua/blob/master/lua.h#L222
    LUA_OPEQ = 0,
    LUA_OPLT = 1,
    LUA_OPLE = 2,
}

return Operation
