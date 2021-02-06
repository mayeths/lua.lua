local Header = require("runtime/chunk/header")
local Prototype = require("runtime/chunk/prototype")
local Tag = require("runtime/chunk/tag")
local Locvar = require("runtime/chunk/locvar")
local Upvalue = require("runtime/chunk/upvalue")
local Util = require("common/util")
local Throw = require("common/throw")


local Reader = {
    data = "",
}


function Reader:new(data)
    Reader.__index = Reader
    self = setmetatable({}, Reader)
    self.data = data
    return self
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
    local lineDefined = self:readUint32()
    local lastLineDefined = self:readUint32()
    local numParams = self:readByte()
    local isVararg = self:readByte()
    local maxStackSize = self:readByte()
    local code = self:readCode()
    local constants = self:readConstants()
    local upvalues = self:readUpvalues()
    local protos = self:readProtos(source)
    local lineInfo = self:readLineInfo()
    local locVars = self:readLocVars()
    local upvalueNames = self:readUpvalueNames()
    return Prototype:new(
        source, lineDefined, lastLineDefined,
        numParams, isVararg, maxStackSize,
        code, constants, upvalues, protos,
        lineInfo, locVars, upvalueNames)
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
        upvalues[i] = Upvalue:new(
            self:readByte(),
            self:readByte()
        )
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
        local varname = self:readString()
        local startPC = self:readUint32()
        local endPC = self:readUint32()
        locVars[i] = Locvar:new(varname, startPC, endPC)
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
    if self:readBytes(4) ~= Header.LUA_SIGNATURE then
        Throw:error("[Reader:checkHeader ERROR] Lua signature mismatch!")
    end
    if self:readByte() ~= Header.LUAC_VERSION then
        Throw:error("[Reader:checkHeader ERROR] Luac version mismatch!")
    end
    if self:readByte() ~= Header.LUAC_FORMAT then
        Throw:error("[Reader:checkHeader ERROR] Luac format mismatch!")
    end
    if self:readBytes(6) ~= Header.LUAC_DATA then
        Throw:error("[Reader:checkHeader ERROR] Luac data mismatch!")
    end
    if self:readByte() ~= Header.CINT_SIZE then
        Throw:error("[Reader:checkHeader ERROR] C int size mismatch!")
    end
    if self:readByte() ~= Header.CSIZET_SIZE then
        Throw:error("[Reader:checkHeader ERROR] C size_t size mismatch!")
    end
    if self:readByte() ~= Header.INSTRUCTION_SIZE then
        Throw:error("[Reader:checkHeader ERROR] Instruction size mismatch!")
    end
    if self:readByte() ~= Header.LUA_INTEGER_SIZE then
        Throw:error("[Reader:checkHeader ERROR] Lua integer size mismatch!")
    end
    if self:readByte() ~= Header.LUA_NUMBER_SIZE then
        Throw:error("[Reader:checkHeader ERROR] Lua number size mismatch!")
    end
    if self:readLuaInteger() ~= Header.LUAC_INT then
        Throw:error("[Reader:checkHeader ERROR] Endianness mismatch!")
    end
    if self:readLuaNumber() ~= Header.LUAC_NUM then
        Throw:error("[Reader:checkHeader ERROR] Float format mismatch!")
    end
end

return Reader
