local M = {  }
pattern = M
M.__index = M

local default_circle = shape.new('circle')
M.lerp_functions = {}
function M.lerp_functions.default(a,t)
    if type(a) ~= "table" then
        return a
    else
        if type(a[1]) == 'userdata' then
            return Interpolate_ElementColor(a,(t*(#a-1))+1)
        else
            return Interpolate_Element(a,(t*(#a-1))+1)
        end
    end
end
M.lerp_functions.lerp = M.lerp_functions.default
function M.lerp_functions.lerpint(...)
    return int(M.lerp_functions.lerp(...))
end
function M.lerp_functions.vector(a,t)
    if a:isVector() then
        return a
    else
        return Vector.list_lerp(a,t/#a)
    end
end
function M.lerp_functions.decide(a,_,t)
    if type(a) ~= 'table' or (type(a) == 'table' and a[1] == nil) then
        return a
    else
        return wrap_table(a,t,true)
    end
end
function M.lerp_functions.nolerp(a,_,t)
    return a
end

M.arg_types = {
    type = "decide",
    count = "lerpint",
    indes = "decide",
    offset = "vector",
    rm = "decide",
    master = "nolerp",
    shape = "nolerp",
    class = "nolerp",
    callback = "nolerp",
    layer_callback = "nolerp",
    aim = "nolerp",
}
function M:new(params)
    local p = params
    local ret ={}
    ret.params = {
        master = Vector(0,0),         --object it will always spawn from
        radius = 0,           --spawn radius
        angle = 0,             --base angle
        spread = 360,         --how much it's spread out (centered)
        type = "scale",       --the shape of the bullet graphic (can be a table, doing so will loop through the shapes)
        color = color.Red,     --the color of the bullet (can be a table, doing so will loop through the colors)
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
    table.deploy(ret.params,params)
    ret.arg_types = p.arg_types or self.arg_types
    return setmetatable(ret, self)
end
function M:fire(func)
    local ret = {}
    local params = {}
    for l=0,math.round(self.params.layer)-1 do
        local tl = l/self.params.layer
        for k,v in pairs(self.params) do
            local funcname = self.arg_types[k] or "default"
            params[k] = self.lerp_functions[funcname](v,tl,l)
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
function M:fireAF()
    local ret = {}
    local params = {}
    AdvancedFor(self.params.layer,
            {"linear", 0, 1, false, math.tween.linear},
            function(tl,l)
                --l = l - 1
        for k,v in pairs(self.params) do
            local funcname = self.arg_types[k] or "default"
            params[k] = self.lerp_functions[funcname](v,tl,l)
        end
        for c = 1, params.count do
            local obj
            local _func = func or self.fireFunc
            if not _func then
                obj = New(params.class,self,params,l,tl,c)
            else
                obj = _func(self,params,l,tl,c)
            end
            if params.callback and obj then
                params.callback(obj, params, self)
            end
            if params.delay > 0 then
                task.Wait(int(params.delay+0.5))
            end
            table.insert(ret, obj)
        end
        params.layer_callback(self)
        if params.layer_delay > 0 then
            task.Wait(int(params.layer_delay+0.5))
        end
    end)
    return ret
end
function M:increaseValue(id,inc)
    local value = self.params[id]
    if type(value) == 'number' or (type(value) == 'table' and type(value.x) == 'number') then
        self.params[id] = self.params[id] + inc
    else
        for k,v in ipairs(self.params[id]) do
            self.params[id][k] = self.params[id][k] + inc
        end
    end
end
function M:multiplyValue(id,inc)
    local value = self.params[id]
    if type(value) == 'number' or (type(value) == 'table' and type(value.x) == 'number') then
        self.params[id] = self.params[id] * inc
    else
        for k,v in ipairs(self.params[id]) do
            self.params[id][k] = self.params[id][k] * inc
        end
    end
end
function M:getAverage(id)
    local value = self.params[id]
    if type(value) == 'number' then
        return value
    else
        return (math.max(unpack(value))+math.min(unpack(value)))/#value
    end
end
function M:setValue(id,val)
    self:increaseValue(id,val-self:getAverage(id))
end
function M:getValue(id)
    return self.params[id]
end
function M:copy()
    local ret = M(self)
    for k,v in pairs(self) do
        ret[k] = v
    end
    return ret
end
setmetatable(M, {__call = M.new})
return M