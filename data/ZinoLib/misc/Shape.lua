shape = {}
local S = shape
shape.__index = shape

shape.functions = {
    circle = function(self,ang)
        return Vector(1,0):rotated(ang)
    end,
    polygon = function(self,ang)
        return Vector.fromPolygon(self.sides,(ang - self.angle)/360 * self.sides):rotated(self.angle)
    end,
    ellipse = function(self,ang)
        return (self.ratiovec * Vector.fromAngle(ang)):rotated(self.angle)
    end
}

function S.new(type, args)
    local ret = {}
    ret.dist = S.functions[type]
    if args then
        for k,v in pairs(args) do
            ret[k] = v
        end
    end
    return ret
end
return S