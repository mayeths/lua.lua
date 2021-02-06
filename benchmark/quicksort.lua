function QuickSort(array, p, r)
    p = p or 1
    r = r or #array
    if p < r then
        q = Partition(array, p, r)
        QuickSort(array, p, q - 1)
        QuickSort(array, q + 1, r)
    end
end

function Partition(array, p, r)
    local x = array[r]
    local i = p - 1
    for j = p, r - 1 do
        if array[j] <= x then
            i = i + 1
            local temp = array[i]
            array[i] = array[j]
            array[j] = temp
        end
    end
    local temp = array[i + 1]
    array[i + 1] = array[r]
    array[r] = temp
    return i + 1
end


function Sum(array)
    local sum = 0
    for i = 1, #array do
        sum = sum + array[i]
    end
    return sum
end

local A = {8,7,1,9,4,2,6,5,3}
QuickSort(A)
