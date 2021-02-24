local TOKEN = require("compiler/lexer/token")
local Throw = require("util/throw")

local Lexer = {
    chunk = nil,
    chunkName = nil,
    line = nil,
    nextToken = nil,
    nextTokenKind = nil,
    nextTokenLine = nil,
}


local REDecNumber = "^([.]?%d+)([eE]?)([+-]?)(%d+)"
local REHexNumber = "^(0[xX]%x+)([pP]?)([+-]?)(%d+)"
local REIdentifier = "^[_%w]+"
local RELongStringPrefix = "^%[=*%["


function Lexer:new(chunk, name)
    Lexer.__index = Lexer
    self = setmetatable({}, Lexer)
    self.chunk = chunk
    self.chunkName = name
    return self
end


function Lexer:LookAhead()
    if self.nextTokenLine > 0 then
        return self.nextTokenKind
    end
    local currline = self.line
    local line, kind, token = self:NextToken()
    self.line = currline
    self.nextTokenLine = line
    self.nextTokenKind = kind
    self.nextToken = token
    return kind
end


function Lexer:NextIdentifier()
    return self:NextTokenOfKind(TOKEN.IDENTIFIER)
end


function Lexer:NextTokenOfKind(expectKind)
    local l, kind, t = self:NextToken()
    if kind ~= expectKind then
        self:throwLexerError("syntax error near '%s'", t)
    end
    return l, t
end


function Lexer:NextToken()
    if self.nextTokenLine > 0 then
        local l = self.nextTokenLine
        local k = self.nextTokenKind
        local t = self.nextToken
        self.line = self.nextTokenLine
        self.nextTokenLine = 0
        return l, k, t
    end

    self:skipWhiteSpace()
    if #self.chunk == 0 then
        return self.line, TOKEN.EOF, "EOF"
    end

    -- Tokens have ASCII value
    local ahead = string.sub(self.chunk, 1, 1)
    if ahead == "#" then
        self:next(1)
        return self.line, TOKEN.LEN, "#"
    elseif ahead == "%" then
        self:next(1)
        return self.line, TOKEN.MOD, "%"
    elseif ahead == "&" then
        self:next(1)
        return self.line, TOKEN.BAND, "&"
    elseif ahead == "(" then
        self:next(1)
        return self.line, TOKEN.LPAREN, "("
    elseif ahead == ")" then
        self:next(1)
        return self.line, TOKEN.RPAREN, ")"
    elseif ahead == "*" then
        self:next(1)
        return self.line, TOKEN.MUL, "*"
    elseif ahead == "+" then
        self:next(1)
        return self.line, TOKEN.PLUS, "+"
    elseif ahead == "," then
        self:next(1)
        return self.line, TOKEN.COMMA, ","
    elseif ahead == "-" then
        self:next(1)
        return self.line, TOKEN.MINUS, "-"
    elseif ahead == "." then
        if self:test("...") then
            self:next(3)
            return self.line, TOKEN.VARARG, "..."
        elseif self:test("..") then
            self:next(2)
            return self.line, TOKEN.CONCAT, ".."
        elseif #self.chunk == 1 then
            self:next(1)
            return self.line, TOKEN.DOT, "."
        elseif tonumber(string.sub(self.chunk, 2, 2)) == nil then
            self:next(1)
            return self.line, TOKEN.DOT, "."
        end
    elseif ahead == "/" then
        if self:test("//") then
            self:next(2)
            return self.line, TOKEN.IDIV, "//"
        else
            self:next(1)
            return self.line, TOKEN.DIV, "/"
        end
    elseif ahead == ":" then
        if self:test("::") then
            self:next(2)
            return self.line, TOKEN.LABEL, "::"
        else
            self:next(1)
            return self.line, TOKEN.COLON, ":"
        end
    elseif ahead == ";" then
        self:next(1)
        return self.line, TOKEN.SEMI, ";"
    elseif ahead == "<" then
        if self:test("<<") then
            self:next(2)
            return self.line, TOKEN.SHL, "<<"
        elseif self:test("<=") then
            self:next(2)
            return self.line, TOKEN.LE, "<="
        else
            self:next(1)
            return self.line, TOKEN.LT, "<"
        end
    elseif ahead == "=" then
        if self:test("==") then
            self:next(2)
            return self.line, TOKEN.EQ, "=="
        else
            self:next(1)
            return self.line, TOKEN.ASSIGN, "="
        end
    elseif ahead == ">" then
        if self:test(">>") then
            self:next(2)
            return self.line, TOKEN.SHR, ">>"
        elseif self:test(">=") then
            self:next(2)
            return self.line, TOKEN.GE, ">="
        else
            self:next(1)
            return self.line, TOKEN.GT, ">"
        end
    elseif ahead == "[" then
        if self:test("[[") or self:test("[=") then
            return self.line, TOKEN.STRING, self:consumeLongString()
        else
            self:next(1)
            return self.line, TOKEN.LBRACKET, "["
        end
    elseif ahead == "]" then
        self:next(1)
        return self.line, TOKEN.RBRACKET, "]"
    elseif ahead == "^" then
        self:next(1)
        return self.line, TOKEN.POW, "^"
    elseif ahead == "{" then
        self:next(1)
        return self.line, TOKEN.LBRACE, "{"
    elseif ahead == "|" then
        self:next(1)
        return self.line, TOKEN.BOR, "|"
    elseif ahead == "}" then
        self:next(1)
        return self.line, TOKEN.RBRACE, "}"
    elseif ahead == "~" then
        if self:test("~=") then
            self:next(2)
            return self.line, TOKEN.NE, "~="
        else
            self:next(1)
            return self.ASSIGN, TOKEN.WAVE, "~"
        end
    end

    local isShortString = ahead == "'" or ahead == '"'
    if isShortString then
        return self.line, TOKEN.STRING, self:consumeShortString()
    end

    local isNumber = ahead == "." or
        tonumber(string.sub(self.chunk, 2, 2)) ~= nil
    if isNumber then
        return self.line, TOKEN.NUMBER, self:consumeNumber()
    end

    local isIdentifier = ahead == "_"
        or ahead >= "A" and ahead <= "Z"
        or ahead >= "a" and ahead <= "z"
    if isIdentifier then
        local token = self:consumeIdentifier()
        local reservedKind = self:mapReservedWord(token)
        if reservedKind ~= nil then
            return self.line, reservedKind, token
        else
            return self.line, TOKEN.IDENTIFIER, token
        end
    end

    self:throwLexerError("Unexpected symbol near %s", ahead)
end


function Lexer:next(proccessedNum)
    self.chunk = string.sub(self.chunk, proccessedNum + 1)
end


function Lexer:test(str)
    return string.find(self.chunk, str) == 1
end


function Lexer:throwLexerError(fmt, ...)
    Throw:error(fmt, ...)
end


function Lexer:skipWhiteSpace()
    while #self.chunk > 0 do
        if self:test("--") then
            self:next(2)

            if self:test("[") then
                if string.find(self.chunk, RELongStringPrefix) then
                    self:consumeLongString()
                end
            else
                while #self.chunk > 0 do
                    local c = string.sub(self.chunk, 1, 1)
                    if c == "\n" or c == "\r" then
                        break
                    else
                        self:next(1)
                    end
                end
            end
        elseif self:test("\n\r") or self:test("\r\n")then
            self:next(2)
            self.line = self.line + 1
        else
            local c = string.sub(self.chunk, 1, 1)
            if c == "\n" or c == "\r" then
                self:next(1)
                self.line = self.line + 1
            elseif c == " " or c == "\t"
                or c == "\v" or c == "\f" then
                self:next(1)
            else
                return
            end
        end
    end
end


function Lexer:consumeNumber()
    local re = { REDecNumber, REHexNumber }
    for i = 1, #re do
        local val, exp, expSign, expVal = string.match(self.chunk, re[i])
        if val then
            local token = val
            if exp then -- has optional exponent (E or P)
                token = token..exp
                if expSign then
                    token = token..expSign
                end
                if expVal then
                    token = token..expVal
                end
            end
            self:next(#token)
            return token
        end
    end
    self:throwLexerError("Cannot convert to number")
end


function Lexer:consumeIdentifier()
    local token = string.match(self.chunk, REIdentifier)
    if token then
        self:next(#token)
        return token
    end
    self:throwLexerError("Cannot convert to identifier")
end


function Lexer:consumeLongString()
    local left = string.match(self.chunk, RELongStringPrefix)
    if not left then
        self:throwLexerError("Invalid long string or comment")
    end
    local right = string.gsub(self.chunk, "%[", "]")
    local ridx1, ridx2 = string.find(self.chunk, right)
    if not ridx1 then
        self:throwLexerError("Unfinished long string or comment")
    end
    local tokenidx1 = #left + 1
    local tokenidx2 = ridx1 - 1
    local token = string.sub(self.chunk, tokenidx1, tokenidx2)
    self:next(ridx2)
    local _, count = string.gsub(token, "\n", "\n")
    self.line = self.line + count
    token = string.gsub(token, "^\n", "")
    return token
end


function Lexer:consumeShortString()
    local quote = string.sub(self.chunk, 1, 1)
    if quote ~= '"' and quote ~= "'" then
        self:throwLexerError("Invalid short string")
    end
    local re = "[^\\]"..quote
    local lastCharIndex = string.find(self.chunk, re, 2)
    if not lastCharIndex then
        self:throwLexerError("Unfinished short string")
    end
    local token = string.sub(self.chunk, 2, lastCharIndex)
    self:next(#token + 2)
    if string.find(token, "\\") then
        local _, count = string.gsub(token, "\n", "\n")
        self.line = self.line + count
        token = self:escape(token)
    end
    return token
end


function Lexer:escape(str)
    local result = ""
    local lastCharIndex = #str
    local i = 1
    while i <= lastCharIndex do
        local c = string.sub(str, i, i)
        if c ~= "\\" then
            result = result..c
            i = i + 1
        else
            local esc = string.sub(str, i + 1, i + 1)
            if esc == "a" then
                result = result.."\a"
                i = i + 2
            elseif esc == "b" then
                result = result.."\b"
                i = i + 2
            elseif esc == "f" then
                result = result.."\f"
                i = i + 2
            elseif esc == "n" then
                result = result.."\n"
                i = i + 2
            elseif esc == "r" then
                result = result.."\r"
                i = i + 2
            elseif esc == "t" then
                result = result.."\t"
                i = i + 2
            elseif esc == "v" then
                result = result.."\v"
                i = i + 2
            elseif esc == "'" then
                result = result.."'"
                i = i + 2
            elseif esc == '"' then
                result = result..'"'
                i = i + 2
            elseif esc == "\\" then
                result = result.."\\"
                i = i + 2
            elseif esc >= "0" and esc <= "9" then -- \ddd
                local s = string.match(str, "^%d%d?%d?", i + 1)
                if not s then
                    self:throwLexerError("Invalid escape \\ddd")
                end
                local num = tonumber(s)
                if not num or num > 255 then
                    self:throwLexerError("Escape \\ddd overflowing (%d)", num)
                end
                result = result..string.pack("B", num)
                i = i + 1 + #s
            elseif esc == "x" then -- \xXX
                local s = string.match(str, "^%x%x", i + 2)
                if not s then
                    self:throwLexerError("Invalid escape \\xXX")
                end
                local num = tonumber("0x"..s)
                if num > 255 then
                    self:throwLexerError("Escape \\xXX overflowing (%d)", num)
                end
                result = result..string.pack("B", num)
                i = i + 4
            elseif esc == "u" then -- \u{X} to \u{XXXX}
                local s = string.match(str, "^%x%x?%x?%x?%x?%x?", i + 3)
                if not s then
                    self:throwLexerError("Invalid escape \\u{XXXX}")
                end
                local num = tonumber("0x"..s)
                if num > 0x10FFFF then
                    self:throwLexerError("Escape \\u{XXXX} overflowing (%d)", num)
                end
                result = result..utf8.char(num)
                i = i + 4 + #s
            elseif esc == "z" then
                Throw:error("Not implemented escape \\z in string")
            end
            self:throwLexerError("Invalid escape \\%s", esc)
        end
    end
    return result
end


function Lexer:mapReservedWord(str)
    if str == "and" then
        return TOKEN.AND
    elseif str == "break" then
        return TOKEN.BREAK
    elseif str == "do" then
        return TOKEN.DO
    elseif str == "else" then
        return TOKEN.ELSE
    elseif str == "elseif" then
        return TOKEN.ELSEIF
    elseif str == "end" then
        return TOKEN.END
    elseif str == "false" then
        return TOKEN.FALSE
    elseif str == "for" then
        return TOKEN.FOR
    elseif str == "function" then
        return TOKEN.FUNCTION
    elseif str == "goto" then
        return TOKEN.GOTO
    elseif str == "if" then
        return TOKEN.IF
    elseif str == "in" then
        return TOKEN.IN
    elseif str == "local" then
        return TOKEN.LOCAL
    elseif str == "nil" then
        return TOKEN.NIL
    elseif str == "not" then
        return TOKEN.NOT
    elseif str == "or" then
        return TOKEN.OR
    elseif str == "repeat" then
        return TOKEN.REPEAT
    elseif str == "return" then
        return TOKEN.RETURN
    elseif str == "then" then
        return TOKEN.THEN
    elseif str == "true" then
        return TOKEN.TRUE
    elseif str == "until" then
        return TOKEN.UNTIL
    elseif str == "while" then
        return TOKEN.WHILE
    else
        return nil
    end
end
