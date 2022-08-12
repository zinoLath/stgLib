---
--- Requires: InterpolationHelper.lua, Shape.lua
---Stop blaming society for all of your problems
---
local path = GetCurrentScriptDirectory()
local ih = Include(path .. "InterpolationHelper.lua")
local shape = Include(path .. "Shape.lua")

local default_circle = shape.new('circle')

local M = {}
pattern = M
M.default_params = {
    master = Vector(0,0),         --object it will always spawn from
    radius = 0,           --spawn radius
    angle = 0,             --base angle
    spread = 360,         --how much it's spread out (centered)
    type = "scale",       --the shape of the bullet graphic (can be a table, doing so will loop through the shapes)
    color = Color(255,255,255,255),     --the color of the bullet (can be a table, doing so will loop through the colors)
    class = straight_pattern,      --the class of the bullet (for customised behavior)
    count = 5,             --how many bullets are shot per iteration
    speed = 1,             --the speed of each iteration (can be a table of 2 numbers, which then the final speed depends on the layer)
    layer = 1,             --how many bullets are shot per count
    accel = 0,             --acceleration of the bullets
    maxv = 1000,
    gravity = 0,         --gravity of the bullets
    maxvy = 1000,
    indes = false,         --if the bullet should be indestructible
    shape = default_circle,        --the shape of the iteration
    delay = 0,             --the delay per count
    layer_delay = 0, --the delay per layer
    jitter = 0,           --the angle rng per layer shot
    offset = Vector(0,0),
    callback = voidfunc,
    layer_callback = voidfunc,
    rm = "bul++",
    visual_delay = 7, --the cloud delay thing
    omiga = 0,
}
M.__index = M

function M:new(params)
    local p = params
    local ret ={}
    ret.params = deepcopy(M.default_params)
    table.deploy(ret.params,params)
    ret.arg_types = p.arg_types or self.arg_types
    return setmetatable(ret, self)
end
local pattern_buffer = {}
function M:fire(func)
    local ret = {}
    local params = table.clear(pattern_buffer)
    local rl = math.round(self.params.layer)
    for l=0, rl do
        local tl = l/rl
        for k,v in pairs(self.params) do
            params[k] = ih.lerp(v)
        end
        for c = 1, params.count do
            local obj
            local _func = func or self.fireFunc
            if not _func then
                obj = New(params.class,self,params,l,tl,c)
            else
                obj = _func(self,params,l,tl,c)
            end
            params.callback(obj, self)
            if params.delay > 0 then
                task.Wait(int(params.delay+0.5))
            end
            table.insert(ret, obj)
        end
        params.layer_callback(self)
        if params.layer_delay > 0 then
            task.Wait(int(params.layer_delay+0.5))
        end
    end
    return ret
end

function M:fireFromParams(sparams)
    local ret = {}
    local params = table.clear(pattern_buffer)
    local actparams = deepcopy(M.default_params)
    table.deploy(actparams,sparams)
    local rl = math.round(actparams.layer)
    for l=0, rl do
        local tl = l/rl
        for k,v in pairs(actparams) do
            params[k] = ih.lerp(v)
        end
        for c = 1, params.count do
            local obj
            local _func = func or self.fireFunc
            if not _func then
                obj = New(params.class,self,params,l,tl,c)
            else
                obj = _func(self,params,l,tl,c)
            end
            params.callback(obj, self)
            if params.delay > 0 then
                task.Wait(int(params.delay+0.5))
            end
            table.insert(ret, obj)
        end
        params.layer_callback(self)
        if params.layer_delay > 0 then
            task.Wait(int(params.layer_delay+0.5))
        end
    end
    return ret
end
