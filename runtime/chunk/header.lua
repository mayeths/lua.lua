local Header = {
    LUA_SIGNATURE    = "\x1bLua",-- 1B4C7561
    LUAC_VERSION     = 0x53,
    LUAC_FORMAT      = 0,
    LUAC_DATA        = "\x19\x93\r\n\x1a\n",
    CINT_SIZE        = 4,
    CSIZET_SIZE      = 8,
    INSTRUCTION_SIZE = 4,
    LUA_INTEGER_SIZE = 8,
    LUA_NUMBER_SIZE  = 8,
    LUAC_INT         = 0x5678,
    LUAC_NUM         = 370.5,
}

return Header
