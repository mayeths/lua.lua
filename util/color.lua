local Color = {
    RED = "\27[31m",
    GREEN = "\27[32m",
    ORANGE = "\27[33m",
    BLUE = "\27[34m",
    PURPLE = "\27[35m",
    CYAN = "\27[36m",
    NC = "\27[0m",
}

function Color:red(str)
    return self.RED..str..self.NC
end

function Color:blue(str)
    return self.BLUE..str..self.NC
end

function Color:green(str)
    return self.GREEN..str..self.NC
end

return Color
