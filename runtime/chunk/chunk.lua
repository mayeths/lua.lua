local Reader = require("runtime/chunk/reader")


local Chunk = {
    header = nil,
    sizeUpvalues = nil,
    mainFunc = nil,
}


function Chunk:Undump(data)
    local reader = Reader:new(data)
    reader:checkHeader()
    reader:readByte() -- size_upvalues
    return reader:readProto("")
end

return Chunk
