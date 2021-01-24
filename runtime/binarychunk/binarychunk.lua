require("runtime/binarychunk/reader")


local BinaryChunk = {
    header = nil,
    sizeUpvalues = nil,
    mainFunc = nil,
}


function BinaryChunk:Undump(data)
    local reader = Reader:new(data)
    reader:checkHeader()
    reader:readByte() -- size_upvalues
    return reader:readProto("")
end

return BinaryChunk
