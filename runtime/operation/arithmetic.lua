local Arith = {}


function Arith:isinf(num, sign)
    return num == (sign / 0)
end


function Arith:imod(a, b)
    return a - Arith:ifloordiv(a, b) * b
end


function Arith:fmod(a, b)
    local infcheck1 = a > 0 and Arith:isinf(b, 1)
    local infcheck2 = a < 0 and Arith:isinf(b, -1)
    if infcheck1 or infcheck2 then
        return a
    end
    local infcheck3 = a > 0 and Arith:isinf(b, -1)
    local infcheck4 = a < 0 and Arith:isinf(b, 1)
    if infcheck3 or infcheck4 then
        return b
    end
    return a - math.floor(a / b) * b
end


function Arith:ifloordiv(a, b)
    local check1 = a > 0 and b > 0
    local check2 = a < 0 and b < 0
    local check3 = a % b == 0
    if check1 or check2 or check3 then
        return a / b
    else
        return a / b - 1
    end
end


function Arith:ffloordiv(a, b)
    return math.floor(a / b)
end

return Arith
