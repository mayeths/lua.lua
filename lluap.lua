require("runtime/binarychunk/binarychunk")
require("runtime/vm/instruction")
require("util/util")


LLUAP = {}


function LLUAP:main()
    if #arg < 1 then
        Util:panic("[LLUAP ERROR] Running LLUAP require a bytecode file")
    end
    local fd = io.open(arg[1], "rb")
    local data = fd:read("*all")
    fd:close()
    local proto = BinaryChunk:Undump(data)
    LLUAP:displayProtoInfo(proto, 1)
end


function LLUAP:displayProtoInfo(proto, depth)
    local queue = { proto }
    local candidate = {}
    while #queue ~= 0 and depth >= 1 do
        local curr = table.remove(queue, 1)
        candidate[#candidate+1] = curr
        for i = 1, #curr.Protos do
            queue[#queue + 1] = curr.Protos[i]
        end
        depth = depth - 1
    end
    for i = 1, #candidate do
        LLUAP:printProto(candidate[i])
    end
end


function LLUAP:printProto(proto)
    Util:println("")
    LLUAP:printProtoHeader(proto)
    LLUAP:printProtoCode(proto)
    LLUAP:printProtoDetail(proto)
    LLUAP:printProtoFooter()
    Util:println("")
end


function LLUAP:printProtoHeader(proto)
    local protoType = "Root"
    local varargFlag = ""
    if proto.LineDefined > 0 then
        protoType = "Function"
    end
    if proto.IsVararg > 0 then
        varargFlag = "+vararg"
    end
    Util:println("--- PROTO %s <%s:%d-%d> (%d instructions) ---",
        protoType, proto.Source, proto.LineDefined,
        proto.LastLineDefined, #proto.Code
    )
    Util:printf("%d%s params, %d slots, %d upvalues, ",
        proto.NumParams, varargFlag,
        proto.MaxStackSize, #proto.Upvalues
    )
    Util:println("%d constants, %d locals, %d functions",
        #proto.Constants, #proto.LocVars, #proto.Protos
    )
end


function LLUAP:printProtoCode(proto)
    Util:println("body (%d):", #proto.Code)
    Util:println("\tindex\tline\tinstruction\topname\t\toperand")
    for i, code in ipairs(proto.Code) do
        local line = "-"
        if #proto.LineInfo > 0 then
            line = string.format("%d", proto.LineInfo[i])
        end
        local inst = Instruction:new({value = code})
        Util:printf("\t%d\t[%s]\t0x%08X\t%s\t", i, line, code, inst:OpName())
        LLUAP:printOperands(inst)
        Util:println("")
    end
end


function LLUAP:printOperands(inst)
    local mode = inst:OpMode()
    if mode == OPMODE.IABC then
        local a, b, c = inst:ABC()
        Util:printf("%d", a)
        if inst:BMode() ~= OPARGMASK.OpArgN then
            if b > 0xFF then
                Util:printf(" %d", -1-(b&0xFF))
            else
                Util:printf(" %d", b)
            end
        end
        if inst:CMode() ~= OPARGMASK.OpArgN then
            if c > 0xFF then
                Util:printf(" %d", -1-(c&0xFF))
            else
                Util:printf(" %d", c)
            end
        end
    elseif mode == OPMODE.IABx then
        local a, bx = inst:ABx()
        Util:printf("%d", a)
        if inst:BMode() == OPARGMASK.OpArgK then
            Util:printf(" %d", -1-bx)
        elseif inst:BMode() == OPARGMASK.OpArgU then
            Util:printf(" %d", bx)
        end
    elseif mode == OPMODE.IAsBx then
        local a, sbx = inst:AsBx()
        Util:printf("%d %d", a, sbx)
    elseif mode == OPMODE.IAx then
        local ax = inst:Ax()
        Util:printf("%d", -1-ax)
    end
end


function LLUAP:printProtoDetail(proto)
    Util:println("constants (%d):", #proto.Constants)
    for i = 1, #proto.Constants do
        local const = proto.Constants[i]
        Util:println("\t%d\t%s", i, LLUAP:constantToString(const))
    end

    Util:println("locals (%d):", #proto.LocVars)
    for i = 1, #proto.LocVars do
        local locvar = proto.LocVars[i]
        Util:println("\t%d\t%s\t%d\t%d",
            i, locvar.VarName, locvar.StartPC, locvar.EndPC
        )
    end

    Util:println("upvalues (%d):", #proto.Upvalues)
    for i = 1, #proto.Upvalues do
        local upval = proto.Upvalues[i]
        local upvalName = "-"
        if #proto.UpvalueNames > 0 then
            upvalName = proto.UpvalueNames[i]
        end
        Util:println("\t%d\t%s\t%d\t%d",
            i, upvalName, upval.Instack, upval.Idx
        )
    end
end


function LLUAP:printProtoFooter()
    Util:println("------")
end



function LLUAP:constantToString(const)
    if type(const) == "string" then
        return '"'..const..'"'
    else
        return tostring(const)
    end
end


LLUAP:main()
