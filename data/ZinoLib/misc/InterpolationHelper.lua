---Interpolation Helper
---basically, make an interpolation function be a separate data structure so that it can be more easily integrated into
---other systems, like my pattern object system and movement functions
---
---structure:
--- elements: { {[numbers (usually just 1, but it can be more on beziers], t } }
--- tween: {function, per_value (if the tweening applies as a whole, or per each element)}
--- loop: bool (if the last element is the starting one)
--- (actually how do i even enforce this? do i replace the last element, or do i add a new one? but then how would it work with ts?)
--- (maybe have a special value thats automatically filled in??? like if you dont put shit it gets replaced instead of having a bool)
--- replace_first: bool (girlie i have no idea if this is even needed lmfao im taking this one OUT)/
---
--TODO: add curves (spline and bezier) (freya PLEASE release the spline video)
local M = {}
M.__index = M
IntHelp = M

function M:new(elements, tween, isint, ...)
    local ret = {}
    ret.__type = "lerper"
    ret.isint = isint
    ret.elements = {}
    for k,v in ipairs(elements) do
        if type(v) == "number" or type(v) == "userdata" then
            ret.elements[k] = {v, t = (k-1)/(#elements-1)}
        elseif type(v) == "table" then
            ret.elements[k] = v
        else
            ret.elements[k] = {nil, t = (k-1)/(#elements-1)}
        end
    end
    if type(tween) == "function" then
        ret.tween = {tween, false}
    else
        ret.tween = tween
    end
    ret.extra_data = {...}
    return ret
end
function M.boolerp(a,b,t)
    if t > 0.5 then
        return b
    else
        return a
    end
end
function M:lerp(t)
    if type(self) ~= "table" or self.__type ~= "lerper" then
        return self
    end
    local lerpf = math.lerp
    t = self.tween[1](t)
    local arrtype = type(self.elements[1][1])
    if arrtype == "userdata" then
        lerpf = Vector.lerp
    elseif arrtype == "boolean" then
        lerpf = M.boolerp
    end
    if t == 0 then
        return self.elements[1][1]
    end
    if t == 1 then
        return self.elements[#self.elements][1]
    end
    for i=1, #self.elements do
        local i2 = LoopTableK(self.elements, i+1)
        local t1 = i/#self.elements
        local t2 = i2/#self.elements
        if t >= t1 and t <= t2 then
            if t1 ~= t2 then
                local finalt = (t-t1)/(t2-t1)
                if self.isint then
                    finalt = int(finalt)
                end
                return lerpf(self.elements[i][1], self.elements[i2][1], finalt)
            else
                return self.elements[i2][1]
            end
        end
    end
end

return M