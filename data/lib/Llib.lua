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

---MATH
local min, max = math.min, math.max
function math.clamp(v,hi,lo)
    return max(hi,min(lo,v))
end
function math.lerp(a,b,t)
    return a + (b-a) * t
end

voidfunc = function()  end