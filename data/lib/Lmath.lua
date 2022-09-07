---=====================================
---luastg math
---=====================================

----------------------------------------
---常量

PI = math.pi
PIx2 = math.pi * 2
PI_2 = math.pi * 0.5
PI_4 = math.pi * 0.25
SQRT2 = math.sqrt(2)
SQRT3 = math.sqrt(3)
SQRT2_2 = math.sqrt(0.5)
GOLD = 360 * (math.sqrt(5) - 1) / 2

math.tween = lstg.DoFile("lib/tween.lua")

----------------------------------------
---数学函数

int = math.floor
abs = math.abs
max = math.max
min = math.min
rnd = math.random
sqrt = math.sqrt

if not math.mod then
    --坑爹新luajit没了mod函数
    math.mod = function(a, b)
        return a % b
    end
end
mod = math.mod

---获得数字的符号(1/-1/0)
function sign(x)
    if x > 0 then
        return 1
    elseif x < 0 then
        return -1
    else
        return 0
    end
end

---获得(x,y)向量的模长
function hypot(x, y)
    return sqrt(x * x + y * y)
end

---阶乘，目前用于组合数和贝塞尔曲线
local fac = {}
function Factorial(num)
    if num < 0 then
        error("Can't get factorial of a minus number.")
    end
    if num < 2 then
        return 1
    end
    num = int(num)
    if fac[num] then
        return fac[num]
    end
    local result = 1
    for i = 1, num do
        if fac[i] then
            result = fac[i]
        else
            result = result * i
            fac[i] = result
        end
    end
    return result
end

---组合数，目前用于贝塞尔曲线
function combinNum(ord, sum)
    if sum < 0 or ord < 0 then
        error("Can't get combinatorial of minus numbers.")
    end
    ord = int(ord)
    sum = int(sum)
    return Factorial(sum) / (Factorial(ord) * Factorial(sum - ord))
end

--------------------------------------------------------------------------------
--- 弹幕逻辑随机数发生器，用于支持 replay 系统

if true then
    -- 2006 年的 WELL512 随机数发生器
    ran = {}
    local ranx = lstg.Rand()
    ---@param a number
    ---@param b number
    ---@return number
    function ran:Int(a, b)
        if a > b then
            return ranx:Int(b, a)
        else
            return ranx:Int(a, b)
        end
    end
    ---@param a number
    ---@param b number
    ---@return number
    function ran:Float(a, b)
        return ranx:Float(a, b)
    end
    ---@return number
    function ran:Sign()
        return ranx:Sign()
    end
    ---@param v number
    function ran:Seed(v)
        ranx:Seed(v)
    end
    ---@return number
    function ran:GetSeed()
        return ranx:GetSeed()
    end
    pran = {}
    local pranx = lstg.Rand()
    ---@param a number
    ---@param b number
    ---@return number
    function pran:Int(a, b)
        if a > b then
            return pranx:Int(b, a)
        else
            return pranx:Int(a, b)
        end
    end
    ---@param a number
    ---@param b number
    ---@return number
    function pran:Float(a, b)
        return pranx:Float(a, b)
    end
    ---@return number
    function pran:Sign()
        return pranx:Sign()
    end
    ---@param v number
    function pran:Seed(v)
        pranx:Seed(v)
    end
    ---@return number
    function pran:GetSeed()
        return pranx:GetSeed()
    end
else
    -- 2019 年的新一代 xoshiro256** 随机数发生器
    local random = require("random")
    ran = random.xoshiro512ss()
end
