-- LAST UPDATED: 9/25/18
-- added Vector.getCeil and v.ceil
-- added Vector.clamp
-- changed float to double as per Mike Pall's advice
-- added Vector.floor
-- added fallback to table if luajit ffi is not detected (used for unit tests)

--[[
BrineVector: a luajit ffi-accelerated vector library
Copyright 2018 Brian Sarfati
Permission is hereby granted, free of charge, to any person obtaining a copy of this software
and associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE
AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--]]
local ffi
local VECTORTYPE = "cdata"
local lerp = math.lerp
local pi2 = math.pi * 2
local math_cos, math_sin = math.cos, math.sin
local cos, sin = cos, sin
local int = math.floor

if jit and jit.status() then
    ffi = require "ffi"
    ffi.cdef[[
  typedef struct {
    double x;
    double y;
  } brinevector;
  ]]
else
    VECTORTYPE = "table"
end

local Vector = {}
setmetatable(Vector,Vector)

local special_properties = {
    length = "getLength",
    normalized = "getNormalized",
    angle = "getAngle",
    length2 = "getLengthSquared",
    copy = "getCopy",
    inverse = "getInverse",
    floor = "getFloor",
    ceil = "getCeil",
}

function Vector.__index(t, k)
    if special_properties[k] then
        return Vector[special_properties[k]](t)
    end
    return rawget(Vector,k)
end

function Vector.getLength(v)
    return math.sqrt(v.x * v.x + v.y * v.y)
end

function Vector.getLengthSquared(v)
    return v.x*v.x + v.y*v.y
end

function Vector.getNormalized(v)
    local length = v.length
    if length == 0 then return Vector(0,0) end
    return Vector(v.x / length, v.y / length)
end

function Vector.getAngle(v)
    return atan2(v.y, v.x)
end

function Vector.getCopy(v)
    return Vector(v.x,v.y)
end

function Vector.getInverse(v)
    return Vector(1 / v.x, 1 / v.y)
end

function Vector.getFloor(v)
    return Vector(math.floor(v.x), math.floor(v.y))
end

function Vector.getCeil(v)
    return Vector(math.ceil(v.x), math.ceil(v.y))
end

function Vector.__newindex(t,k,v)
    if k == "length" then
        local res = t.normalized * v
        t.x = res.x
        t.y = res.y
        return
    end
    if k == "angle" then
        local res = t:angled(v)
        t.x = res.x
        t.y = res.y
        return
    end
    if t == Vector then
        rawset(t,k,v)
    else
        error("Cannot assign a new property '" .. k .. "' to a Vector", 2)
    end
end

function Vector.angled(v, angle)
    local length = v.length
    return Vector(cos(angle) * length, sin(angle) * length)
end

function Vector.trim(v,mag)
    if v.length < mag then return v end
    return v.normalized * mag
end

function Vector.split(v)
    return v.x, v.y
end
Vector.unpack = Vector.split

function Vector.lerp(v1,v2,a)
    return v1 + (v2 - v1) * a
end

local function clamp(x, min, max)
    -- because Mike Pall says math.min and math.max are JIT-optimized
    return math.min(math.max(min, x), max)
end

function Vector.clamp(v, topleft, bottomright)
    -- clamps a vector to a certain bounding box about the origin
    return Vector(
            clamp(v.x, topleft.x, bottomright.x),
            clamp(v.y, topleft.y, bottomright.y)
    )
end

function Vector.hadamard(v1, v2) -- also known as "Componentwise multiplication"
    return Vector(v1.x * v2.x, v1.y * v2.y)
end

function Vector.rotated(v, angle)
    local cos = cos(angle)
    local sin = sin(angle)
    return Vector(v.x * cos - v.y * sin, v.x * sin + v.y * cos)
end
function Vector.rotate(v, angle)
    local cos = cos(angle)
    local sin = sin(angle)
    local px = v.x
    v.x = px * cos - v.y * sin
    v.y = px * sin + v.y * cos
    return v
end

function Vector.rotatecs(v, cos, sin)
    local px = v.x
    v.x = px * cos - v.y * sin
    v.y = px * sin + v.y * cos
    return v
end
local iteraxes_lookup = {
    xy = {"x","y"},
    yx = {"y","x"}
}
local function iteraxes(ordertable, i)
    i = i + 1
    if i > 2 then return nil end
    return i, ordertable[i]
end

function Vector.axes(order)
    return iteraxes, iteraxes_lookup[order or "yx"], 0
end
Vector.clone = Vector.getCopy

local function iterpairs(vector, k)
    if k == nil then
        k = "x"
    elseif k == "x" then
        k = "y"
    else
        k = nil
    end
    return k, vector[k]
end

function Vector.__pairs(v)
    return iterpairs, v, nil
end

function Vector.fromAngle(ang)
    return Vector(cos(ang), sin(ang))
end
function Vector.fromPolygon(sides,t)
    local ft = (sides*t)-int(sides*t)
    local a1 = (pi2/int(sides))*int(t*sides)
    local a2 = (pi2/int(sides))*int(t*sides+1)
    return Vector(
            lerp(math_cos(a1),math_cos(a2),ft),
            lerp(math_sin(a1),math_sin(a2),ft))
end
function Vector.fromTable(tb)
    return Vector(tb.x,tb.y)
end
function Vector.fromVelocity(tb)
    return Vector(tb.vx,tb.vy)
end
--Clockwise
function Vector.perpendicularC(v)
    return Vector(v.y,-v.x)
end
--CounterClockwise
function Vector.perpendicularCC(v)
    return Vector(-v.y,v.x)
end
Vector.perpendicular = Vector.perpendicularC
function Vector.list_lerp(arr, t)
    local src = arr[int(t)] --get the first value for lerp
    local did = int(t + 1) > #arr and int(t + 1 - #arr) or int(t + 1)-- loops through the array
    local dest = arr[did] --get the second index for lerp
    local _t = t - int(t)
    return Vector.lerp(src,dest,_t)
end

if ffi then
    function Vector.isVector(arg)
        return ffi.istype("brinevector",arg)
    end
else
    function Vector.isVector(arg)
        return type(arg) == VECTORTYPE and arg.x and arg.y
    end
end

function Vector.isVectorLoose(arg)
    if not Vector.isVector(arg) and type(arg) ~= "table" then
        return false
    end
    return arg.x and arg.y
end

function Vector.toTable(v)
    return {x = v.x, y = v.y}
end

function Vector.__add(v1, v2)
    return Vector(v1.x + v2.x, v1.y + v2.y)
end

function Vector.__sub(v1, v2)
    return Vector(v1.x - v2.x, v1.y - v2.y)
end

function Vector.__mul(v1, op)
    -- acts as a hadamard multiplication if op is a vector
    -- if op is a scalar then works as usual
    if type(v1) == "number" then
        return Vector(op.x * v1, op.y * v1)
    end
    if type(op) == VECTORTYPE then
        return Vector(v1.x * op.x, v1.y * op.y)
    else
        return Vector(v1.x * op, v1.y * op)
    end
end

function Vector.__div(v1, op)
    if type(op) == "number" then
        if op == 0 then error("Vector NaN occured", 2) end
        return Vector(v1.x / op, v1.y / op)
    elseif type(op) == VECTORTYPE then
        if op.x * op.y == 0 then error("Vector NaN occured", 2) end
        return Vector(v1.x / op.x, v1.y / op.y)
    end
end

function Vector.__unm(v)
    return Vector(-v.x, -v.y)
end

function Vector.__eq(v1,v2)
    if (not Vector.isVector(v1)) or (not Vector.isVector(v2)) then return false end
    return v1.x == v2.x and v1.y == v2.y
end

function Vector.__mod(v1,v2)  -- ran out of symbols, so i chose % for the dot product
    return v1.x * v2.x + v1.y * v2.y
end

function Vector.__tostring(t)
    return string.format("Vector{%.4f, %.4f}",t.x,t.y)
end

function Vector.__concat(str, v)
    return tostring(str) .. tostring(v)
end

function Vector.__len(v)
    return math.sqrt(v.x * v.x + v.y * v.y)
end

if ffi then
    function Vector.__call(t,x,y)
        return ffi.new("brinevector",x or 0,y or 0)
    end
else
    function Vector.__call(t,x,y)
        return setmetatable({x = x or 0, y = y or 0}, Vector)
    end
end

local dirs = {
    up = Vector(0,-1),
    down = Vector(0,1),
    left = Vector(-1,0),
    right = Vector(1,0),
    top = Vector(0,-1),
    bottom = Vector(0,1)
}

function Vector.dir(dir)
    return dirs[dir] and dirs[dir].copy or Vector()
end


if ffi and not brinevector_loaded then
    ffi.metatype("brinevector",Vector)
end

brinevector_loaded = true

Vector.zero = Vector(0,0)
return Vector