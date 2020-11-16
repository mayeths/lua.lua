function LuaState:PushNil()
    self.stack:push(nil)
end


function LuaState:PushBoolean(b)
    self.stack:push(b)
end


function LuaState:PushInteger(n)
    self.stack:push(n)
end


function LuaState:PushNumber(n)
    self.stack:push(n)
end


function LuaState:PushString(s)
    self.stack:push(s)
end

