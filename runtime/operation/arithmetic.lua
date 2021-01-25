local Arith = {}


function Arith:isinf(num, sign)
    return num == (sign / 0)
end


function Arith:imod(a, b)
    return a % b
end


function Arith:fmod(a, b)
    return a % b
end


function Arith:ifloordiv(a, b)
    return a // b
end


function Arith:ffloordiv(a, b)
    return a // b
end

return Arith
