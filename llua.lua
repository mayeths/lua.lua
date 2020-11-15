require("env")
Env:updateSearchPath("src/?.lua")
require("binaryChunk/binaryChunk")
require("util/util")


Main = {}


function Main:main()
    if #arg < 1 then
        Util:panic("[Main ERROR] Running LLUA require a bytecode file")
    end
    local fd = io.open(arg[1], "rb")
    local data = fd:read("*all")
    fd:close()
    local proto = BinaryChunk:Undump(data)
    Main:displayProtoInfo(proto)
end


function Main:displayProtoInfo(proto)
    Main:printProtoHeader(proto)
    Main:printProtoCode(proto)
    Main:printProtoDetail(proto)
    Main:printProtoFooter(proto)
end


function Main:printProtoHeader(proto)
    local protoType = "main"
    local varargFlag = ""
    if proto.LineDefined > 0 then
        protoType = "function"
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


function Main:printProtoCode(proto)
    Util:println("body (%d):", #proto.Code)
    for i, code in ipairs(proto.Code) do
        local line = "-"
        if #proto.LineInfo > 0 then
            line = string.format("%d", proto.LineInfo[i])
        end
        Util:println("\t%d\t[%s]\t0x%08X", i, line, code)
    end
end


function Main:printProtoDetail(proto)
    Util:println("constants (%d):", #proto.Constants)
    for i, const in ipairs(proto.Constants) do
        Util:println("\t%d\t%s", i, Main:constantToString(const))
    end

    Util:println("locals (%d):", #proto.LocVars)
    for i, locvar in ipairs(proto.LocVars) do
        Util:println("\t%d\t%s\t%d\t%d",
            i, locvar.VarName, locvar.StartPC, locvar.EndPC
        )
    end

    Util:println("upvalues (%d):", #proto.Upvalues)
    for i, upval in ipairs(proto.Upvalues) do
        local upvalName = "-"
        if #proto.UpvalueNames > 0 then
            upvalName = proto.UpvalueNames[i]
        end
        Util:println("\t%d\t%s\t%d\t%d",
            i, upvalName, upval.Instack, upval.Idx
        )
    end
end


function Main:printProtoFooter(proto)
    Util:println("------")
end



function Main:constantToString(const)
    if type(const) == "string" then
        return '"'..const..'"'
    else
        return tostring(const)
    end
end


Main:main()
