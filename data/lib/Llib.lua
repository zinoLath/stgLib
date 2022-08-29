---TABLE
function deepcopy(tb)
    if type(tb) == "table" then
        local ret = setmetatable({  }, getmetatable(tb))
        for k,v in pairs(tb) do
            if type(v) ~= "table" then
                ret[k] = v
            else
                ret[k] = deepcopy(v)
            end
        end
        return ret
    else
        return tb
    end
end

function softcopy(tb)
    local ret = {}
    for k,v in pairs(tb) do
        ret[k] = v
    end
    return ret
end

function table.deploy(dst,src)
    for k,v in pairs(src) do
        dst[k] = v
    end
    return ret
end

function table.clear(dst)
    for k,v in pairs(dst) do
        dst[k] = nil
    end
    return dst
end
local function PrintTableRecursive(tb,level)
    if type(tb) ~= "table" then
        return tb
    end
    local ret = ""
    level = level or 0
    local i = 0
    local levelstr = ""
    if level > 0 then
        for i=1, level do
            levelstr = levelstr .. "\t"
        end
    end
    for k,v in pairs(tb) do
        i = i+1
        if type(v) ~= "table" then
            ret = ret .. string.format("%sKey: %s | Value: %s\n",levelstr,k,tostring(v))
        else
            local str, _i = PrintTableRecursive(v,level+1)
            ret = ret .. string.format("%sKey: %s | Value:{\n%s\n%s}\n",levelstr,k,str,levelstr)
            i = i + _i
        end
    end
    return ret,i
end

function Print(str)
    lstg.Log(2,PrintTableRecursive(str))
end

---MATH
local min, max = math.min, math.max
function math.clamp(v,hi,lo)
    return max(hi,min(lo,v))
end
function math.lerp(a,b,t)
    return a + (b-a) * t
end

voidfunc = function()  end
