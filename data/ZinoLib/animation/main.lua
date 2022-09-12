local M = class() --the global namespace
ZAnim = M
local path = GetCurrentScriptDirectory()
local min = math.min
local max = math.max
function M:new(side)
    self.anims = {}
    self.cos = {}
    self.data = {}
    self.standardID = "stand"
    self.currentID = self.standardID
    self.anim_timer = 0
    self.side_animated = side
    self.side_deadzone = 0.5
    self.side_frame_max = 15
    self.lr = 0
    self.pause = false
    return self
end
function M:attachObj(obj)
    local copy = self
    copy.obj = obj
    obj.animManager = copy
    return copy
end
function M:update()
    if self.pause then
        return
    end
    local curid = self.currentID
    if coroutine.status(self.cos[curid]) ~= "dead" then
        local C, E = coroutine.resume(self.cos[curid], self.anims[curid], self)
        self.anim_timer = self.anim_timer + 1
        if(not C)then
            error(E)
        end
    else
        self:playAnim(self.standardID,_infinite)
    end
    if self.side_animated then
        self:sideAnim()
    end
end
function M:render(obj)
    self.anims[self.currentID]:render(obj,self)
end
function M:getImage(obj)
    return self.anims[self.currentID].img
end
function M:sideAnim()
    local dx = self.obj._dx or self.obj.dx
    local lr = self.lr
    local back_speed = 1
    if dx > self.side_deadzone then
        self.lr = min(self.lr + 1,self.side_frame_max)
    elseif dx < -self.side_deadzone then
        self.lr = max(self.lr - 1,-self.side_frame_max)
    else
        if self.lr < back_speed or self.lr > -back_speed then
            self.lr = self.lr - sign(self.lr)*back_speed
        else
            self.lr = 0
        end
    end
    if self.lr > 0 then
        if self.currentID == self.standardID or self.currentID == "left" then
            self:playAnim("right", 1)
        end
    elseif self.lr < 0 then
        if self.currentID == self.standardID or self.currentID == "right" then
            self:playAnim("left", -1)
        end
    end
end
local function deepcopy(tb,id)
    local ret = {}
    for k,v in pairs(tb) do
        if type(v) ~= "table" then
            ret[k] = v
        else
            ret[k] = deepcopy(v,id)
        end
    end
    return setmetatable(ret,getmetatable(tb))
end
function M:addAnimation(anim,name)
    return self:addAnimationNC(deepcopy(anim),name)
end
function M:addAnimationNC(anim,name)
    self.anims[name] = anim
    self.data[name] = {}
    self.anims[name]:init(self,name)
    self:createAnimCO(name)
end
function M:createAnimCO(name)
    self.cos[name] = coroutine.create(self.anims[name].co)
end
function M:playAnim(name,...)
    self:createAnimCO(name)
    self.anim_timer = 0
    self.anims[self.currentID]:finish(self,...)
    self.currentID = name
    --start = self,manager,...
    self.anims[name]:start(self,...)
end
function M:copy()
    local ret = M()
    ret.cos = deepcopy(self.cos)
    ret.data = deepcopy(self.data)
    for k,v in pairs(self.anims) do
        ret:addAnimationNC(v,k)
    end
    return ret
end
frame_anim = Include(path.."frame.lua")
side_anim = Include(path.."side.lua")
--- functions to be defined:
---new
---start
---init
---render
---co
---finish
return M