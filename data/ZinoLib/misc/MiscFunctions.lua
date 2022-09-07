local Interpolate = math.lerp
local abs = math.abs
local clamp = math.clamp
function SetFieldInTime(tb,time,func,...)
    local args = {...}
    for k,v in ipairs(args) do
        v[0] = tb[v[1]]
    end
    func = func or Linear
    for i=0, 1, 1/time do
        local j = func(i)
        for k,v in ipairs(args) do
            --if v[0] == nil then lstg.MessageBox(tostring(v[1]), 'OOPS.') end
            tb[v[1]] = Interpolate(v[0], v[2], j)
        end
        coroutine.yield()
    end
    for k,v in ipairs(args) do
        tb[v[1]] = v[2]
    end
end

local lerp = math.lerp
---times, variables, function
---function = (var1, var2, var3, ..., index)
---variables = {type, args}
---
---incremental = {start, increment}
---linear = {from, to, precisely, tween}
---sinewave = {from, to, initial_angle, periodn, precisely}
---zigzag = {from, to, times, precisely, tween}
function AdvancedFor(times,...)
    local args = {...}
    local func = args[#args]
    table.remove(args)
    local variables = {}
    for k,v in ipairs(args) do
        if v[1] ~= 'sinewave' then
            variables[k] = v[2]
        else
            variables[k] = lerp(v[2],v[3],0.5 + 0.5 * sin(v[4]))
        end
    end
    for i=0, times-1 do
        for k,v in ipairs(args) do
            if v[1] == 'incremental' then
                variables[k] = variables[k] + v[3]
            elseif v[1] == 'linear' then
                variables[k] = lerp(v[2], v[3], v[4] and i/(times-1) or i/(times))
            elseif v[1] == 'zigzag' then
                local t = v[5] and i/(times-1) or i/(times)
                local maxt = t * (v[4]+1)
                local finalt
                if math.floor(maxt) % 2 == 1 then
                    local _, val = math.modf(maxt)
                    finalt = 1-val
                else
                    local _, val = math.modf(maxt)
                    finalt = val
                end
                variables[k] = lerp(v[2], v[3], finalt)
            elseif v[1] == 'sinewave' then
                variables[k] = lerp(v[2], v[3], 0.5 + 0.5 * sin(v[4] + v[6] and (360*v[5])/(times-2) or (360*v[5])/(times-1)))
            end
        end
        func(unpack(variables))
    end
end

function PrintTable(tb)
    local ret = ""
    for k,v in pairs(tb) do
        ret = ret .. string.format("Key: %s | Value: %s\n\n", k,tostring(v))
    end
    return ret
end
function PrintTableRecursive(tb,level)
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
function foreachRecursive(tb,f)
    for k,v in pairs(tb) do
        if type(v) ~= "table" then
            f(tb,k,v)
        else
            f(tb,k,v)
            foreachRecursive(v,f)
        end
    end
end

function FindKey(tb, value)
    for k,v in pairs(tb) do
        if v == value then
            return k
        end
    end
end
function InterpolateColor(a,b,t)
    return Color(
            Interpolate(a.a,b.a,t),
            Interpolate(a.r,b.r,t),
            Interpolate(a.g,b.g,t),
            Interpolate(a.b,b.b,t)
    )
end
local printCallClass = true
function CallClass(self, key, ...)
    if self[key] ~= nil then
        return self[key](self,...)
    elseif self.class then
        if self.class[key] ~= nil then
            return self.class[key](self,...)
        end
    end
    if not printCallClass then
        return
    end
    Print("CallClass: No function named: "..key)
end

function SizedTable(size)
    local ret = {}
    for i=1, size do
        ret[i] = i
    end
    return ret
end
function HSVToRGB( hue, saturation, value )
    -- Returns the RGB equivalent of the given HSV-defined color
    -- (adapted from some code found around the web)

    -- If it's achromatic, just return the value
    if saturation == 0 then
        return value,value,value;
    end;

    -- Get the hue sector
    local hue_sector = math.floor( hue / 60 );
    local hue_sector_offset = ( hue / 60 ) - hue_sector;

    local p = value * ( 1 - saturation );
    local q = value * ( 1 - saturation * hue_sector_offset );
    local t = value * ( 1 - saturation * ( 1 - hue_sector_offset ) );

    if hue_sector == 0 then
        return value, t, p;
    elseif hue_sector == 1 then
        return q, value, p;
    elseif hue_sector == 2 then
        return p, value, t;
    elseif hue_sector == 3 then
        return p, q, value;
    elseif hue_sector == 4 then
        return t, p, value;
    elseif hue_sector == 5 then
        return value*255, p*255, q*255;
    end;
end;
function AngleDifference(from,to)
    local delta = (to-from)%360
    return (delta > 180 and delta-360 or delta)
end
function InterpolateAngle(a,b,x)
    local delta = AngleDifference(a,b)
    return a + delta * x
end

function StorePosition(self,max)
    if not self.past_pos then
        self.past_pos = {}
    end
    table.insert(self.past_pos, Vector(self.x, self.y))
    if #self.past_pos > max then
        for i=max, #self.past_pos do
            self.past_pos[i] = nil
        end
    end
end
function LoopTable(tb,id)
    while true do
        if id > #tb then
            id = id - #tb
        else
            break
        end
    end
    if id < 1 then
        id = #tb
    end
    return tb[id]
end
function LoopTableK(tb,id)
    while true do
        if id > #tb then
            id = id - #tb
        else
            break
        end
    end
    if id < 1 then
        id = #tb
    end
    return id
end
---@~english Collision check for circle and parameter. Uses Cocos2D positions for operations. Code by Texel (Texel#4217)
function CircleToCapsule(cP, cR, pA, pB, pR)
    local h = clamp( ((cP - pA) % (pB - pA))/((pB - pA) % (pB - pA)), 0, 1)
    local l2 = (cP-pA-(pB-pA)*h).length2
    return l2 < (cR + pR)*(cR + pR)
end
function CircleToCapsuleUnPen(cP, cR, pA, pB, pR)
    local h = clamp( ((cP - pA) % (pB - pA))/((pB - pA) % (pB - pA)), 0, 1)
    local l2 = (cP-pA-(pB-pA)*h).length2
    return l2 < (cR + pR)*(cR + pR), h
end

function SnapLerp(a,b,x,y)
    y = y or 0.01
    if abs(a-b) < y then
        return b
    else
        return lerp(a,b,x)
    end

end

function MultiplyTable(tb)
    local ret = 1
    for k,v in pairs(tb) do
        ret = ret * v
    end
    return ret
end

function ColorHSV(a,h,s,v)
    local r,g,b = color.fromHSV({h = h / 57.296, s = s/100, v = v/100})
    return Color(a, r*255, g*255, b*255)
end

function ColorHSVF(a,c)
    local r,g,b = color.fromHSV(c)
    return Color(a, r*255, g*255, b*255)
end

local cInt = InterpolateColor
local Lin = math.tween.linear
function Interpolate_ElementColor(arr, t, func)
    local src = arr[int(t)] --get the first value for lerp
    local did = int(t + 1) > #arr and int(t + 1 - #arr) or int(t + 1)
    local dest = arr[did] --get the second index for lerp
    local _t = t - int(t)
    func = func or Lin
    return cInt(src,dest,func(_t))
end
local Int = math.lerp
local Lin = math.tween.linear
function Interpolate_Element(arr, t, func)
    local src = arr[int(t)] --get the first value for lerp
    local did = LoopTableK(arr,int(t+1))
    local dest = arr[did] --get the second index for lerp
    local _t = t - int(t)
    func = func or Lin
    return Int(src,dest,func(_t))
end

function UpdateObject(obj)
    if not IsValid(obj) then return end
    obj.timer = obj.timer + 1
    obj.class.frame(obj,true)
    obj.x, obj.y = obj.x + obj.vx, obj.y + obj.vy
    obj.rot = obj.rot + obj.omiga
    obj.vx, obj.vy = obj.vx + obj.ax, obj.vy + obj.ay
end

function Collide(objc,objr)
    return objr.class.colli(objr,objc)
end

function eval(str)
    return loadstring("return " .. str)()
end
function SplitString(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end
function StringToColor(str)
    if str:sub(1,1) == "#" then
        return Color(255,tonumber(str:sub(2,3),16),tonumber(str:sub(4,5),16),tonumber(str:sub(6,7),16))
    end
end
function Rotate2D(x,y,ang)
    local _cos = cos(ang)
    local _sin = sin(ang)
    return x * _cos - y * _sin, x * _sin + y * _cos
end