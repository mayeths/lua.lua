require("binaryChunk/header")
require("binaryChunk/prototype")
require("binaryChunk/tag")
require("binaryChunk/upvalue")
require("util/util")


Reader = {
    data = "",
}


function Reader:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.data = o.data or ""
    return o
end


function Reader:__readUnpack(fmt)
    local result, unread = string.unpack(fmt, self.data)
    self.data = string.sub(self.data, unread)
    return result
end


function Reader:readByte()
    return self:__readUnpack("b")
end


function Reader:readBytes(n)
    return self:__readUnpack("c"..n)
end


function Reader:readUint32()
    return self:__readUnpack("I4")
end


function Reader:readUint64()
    return self:__readUnpack("I8")
end


function Reader:readInt32()
    return self:__readUnpack("i4")
end


function Reader:readInt64()
    return self:__readUnpack("i8")
end


function Reader:readFloat32()
    return self:__readUnpack("f")
end


function Reader:readFloat64()
    return self:__readUnpack("d")
end


function Reader:readLuaInteger()
    return self:readInt64()
end


function Reader:readLuaNumber()
    return self:readFloat64()
end


function Reader:readString()
    local size = self:readByte()
    if size == 0 then
        return ""
    end
    if size == 0xff then
        size = self:readUint64()
    end
    local bytes = self:readBytes(size - 1)
    return bytes
end


function Reader:readProto(parentSource)
    local source = self:readString()
    if source == "" then
        source = parentSource
    end
    return Prototype:new({
        Source          = source,
        LineDefined     = self:readUint32(),
        LastLineDefined = self:readUint32(),
        NumParams       = self:readByte(),
        IsVararg        = self:readByte(),
        MaxStackSize    = self:readByte(),
        Code            = self:readCode(),
        Constants       = self:readConstants(),
        Upvalues        = self:readUpvalues(),
        Protos          = self:readProtos(source),
        LineInfo        = self:readLineInfo(),
        LocVars         = self:readLocVars(),
        UpvalueNames    = self:readUpvalueNames(),
    })
end


function Reader:readProtos(parentSource)
    local protonum = self:readUint32()
    local protos = {}
    for i = 1, protonum do
        protos[i] = self:readProto(parentSource)
    end
    return protos
end


function Reader:readCode()
    local codeNum = self:readUint32()
    local codes = {}
    for i = 1, codeNum do
        codes[i] = self:readUint32()
    end
    return codes
end


function Reader:readConstant()
    local constType = self:readByte()
    if constType == Tag.NIL then
        return nil
    elseif constType == Tag.BOOLEAN then
        return self:readByte() ~= 0
    elseif constType == Tag.INTEGER then
        return self:readLuaInteger()
    elseif constType == Tag.NUMBER then
        return self:readLuaNumber()
    elseif constType == Tag.SHORT_STR or constType == Tag.LONG_STR then
        return self:readString()
    else
        Util:panic("[Reader:readConstant ERROR] corrupted!")
    end
end

function Reader:readConstants()
    local constNum = self:readUint32()
    local constants = {}
    for i = 1, constNum do
        constants[i] = self:readConstant()
    end
    return constants
end


function Reader:readUpvalues()
    local upvalNum = self:readUint32()
    local upvalues = {}
    for i = 1, upvalNum do
        upvalues[i] = Upvalue:new({
            Instack = self:readByte(),
            Idx     = self:readByte(),
        })
    end
    return upvalues
end


function Reader:readLineInfo()
    local lineNum = self:readUint32()
    local lines = {}
    for i = 1, lineNum do
        lines[i] = self:readUint32()
    end
    return lines
end


function Reader:readLocVars()
    local locVarNum = self:readUint32()
    local locVars = {}
    for i = 1, locVarNum do
        locVars[i] = LocVar:new({
            VarName = self:readString(),
            StartPC = self:readUint32(),
            EndPC   = self:readUint32(),
        })
    end
    return locVars
end


function Reader:readUpvalueNames()
    local upvalNameNum = self:readUint32()
    local upvalNames = {}
    for i = 1, upvalNameNum do
        upvalNames[i] = self:readString()
    end
    return upvalNames
end


function Reader:checkHeader()
    Util:assert(self:readBytes(4),     Header.LUA_SIGNATURE,    "[Reader:checkHeader ERROR] Lua signature mismatch!")
    Util:assert(self:readByte(),       Header.LUAC_VERSION,     "[Reader:checkHeader ERROR] Luac version mismatch!")
    Util:assert(self:readByte(),       Header.LUAC_FORMAT,      "[Reader:checkHeader ERROR] Luac format mismatch!")
    Util:assert(self:readBytes(6),     Header.LUAC_DATA,        "[Reader:checkHeader ERROR] Luac data mismatch!")
    Util:assert(self:readByte(),       Header.CINT_SIZE,        "[Reader:checkHeader ERROR] C int size mismatch!")
    Util:assert(self:readByte(),       Header.CSIZET_SIZE,      "[Reader:checkHeader ERROR] C size_t size mismatch!")
    Util:assert(self:readByte(),       Header.INSTRUCTION_SIZE, "[Reader:checkHeader ERROR] Instruction size mismatch!")
    Util:assert(self:readByte(),       Header.LUA_INTEGER_SIZE, "[Reader:checkHeader ERROR] Lua integer size mismatch!")
    Util:assert(self:readByte(),       Header.LUA_NUMBER_SIZE,  "[Reader:checkHeader ERROR] Lua number size mismatch!")
    Util:assert(self:readLuaInteger(), Header.LUAC_INT,         "[Reader:checkHeader ERROR] Endianness mismatch!")
    Util:assert(self:readLuaNumber(),  Header.LUAC_NUM,         "[Reader:checkHeader ERROR] Float format mismatch!")
end


return Reader

