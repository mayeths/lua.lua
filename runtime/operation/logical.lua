local Logical = {}

function Logical:shiftleft(a, n)
    if n >= 0 then
        return a << n
    else
        return a >> n
    end
end


function Logical:shiftright(a, n)
    if n >= 0 then
        return a >> n
    else
        return a << n
    end
end

return Logical
