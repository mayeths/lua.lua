local TOKEN = {
    -- Tokens that have corresponding char in ASCII
    -- (Some chars are unused in lua like 33'!' 36'$')
    LEN      = 35,     -- #
    MOD      = 37,     -- %
    BAND     = 38,     -- &
    LPAREN   = 40,     -- (
    RPAREN   = 41,     -- )
    MUL      = 42,     -- *
    PLUS     = 43,     -- +
    COMMA    = 44,     -- ,
    MINUS    = 45,     -- -
    DOT      = 46,     -- .
    DIV      = 47,     -- /
    COLON    = 58,     -- :
    SEMI     = 59,     -- ;
    LT       = 60,     -- <
    ASSIGN   = 61,     -- =
    GT       = 62,     -- >
    LBRACKET = 91,     -- [
    RBRACKET = 93,     -- ]
    POW      = 94,     -- ^
    LBRACE   = 123,    -- {
    BOR      = 124,    -- |
    RBRACE   = 125,    -- }
    WAVE     = 126,    -- ~

    -- Other tokens (see enum RESERVED in lua/llex.h)
    -- Terminal symbols denoted by reserved words
    AND        = 257,    -- and
    BREAK      = 258,    -- break
    DO         = 259,    -- do
    ELSE       = 260,    -- else
    ELSEIF     = 261,    -- elseif
    END        = 262,    -- end
    FALSE      = 263,    -- false
    FOR        = 264,    -- for
    FUNCTION   = 265,    -- function
    GOTO       = 266,    -- goto
    IF         = 267,    -- if
    IN         = 268,    -- in
    LOCAL      = 269,    -- local
    NIL        = 270,    -- nil
    NOT        = 271,    -- not
    OR         = 272,    -- or
    REPEAT     = 273,    -- repeat
    RETURN     = 274,    -- return
    THEN       = 275,    -- then
    TRUE       = 276,    -- true
    UNTIL      = 277,    -- until
    WHILE      = 278,    -- while

    -- Other terminal symbols
    IDIV       = 279,    -- //
    CONCAT     = 280,    -- ..
    VARARG     = 281,    -- ...
    EQ         = 282,    -- ==
    GE         = 283,    -- >=
    LE         = 284,    -- <=
    NE         = 285,    -- ~=
    SHL        = 286,    -- <<
    SHR        = 287,    -- >>
    LABEL      = 288,    -- ::
    EOF        = 289,    -- <eof>
    NUMBER     = 290,    -- <number>
    INTEGER    = 291,    -- <integer>
    IDENTIFIER = 292,    -- <identifier>
    STRING     = 293,    -- <string>
}

return TOKEN

