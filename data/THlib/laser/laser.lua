-- updated to ex+0.80d
--do return end
local int = int
local abs = abs
local min = min
local max = max
local sin = sin
local cos = cos
local task = task
local Del = Del
local Color = Color
local New = New
local IsValid = IsValid
local PlaySound = PlaySound
local Render = Render
local CircleToCapsule = CircleToCapsule
local Render4V = Render4V
local Collide = Collide
local Vector = Vector
local lerp = math.lerp
local clamp = math.clamp
local path = GetCurrentScriptDirectory()

LoadImageGroupFromFile("laser", path.."laser.png",true,3,1)
---@class THlib.laser:object
laser = Class(object)
function laser:init(x,y,rot,len,width,ratioH,ratioB,ratioT,_color,img,rm)
    img = img or "laser"
    ratioH, ratioB, ratioT = ratioH or 0.2, ratioB or 3, ratioT or 0.2
    self.x, self.y = x,y
    self.rot = rot
    self.rm = rm or "bul++"
    self.color = _color or color.Red
    self.lastrot = rot
    self.dirvec = Vector.fromAngle(rot)
    self.tdvec = self.dirvec:perpendicular()
    self.l0 = len or 0
    self.w0 = width or 0
    self.l = self.l0
    self.w = self.w0
    local recip = 1/(ratioH+ratioB+ratioT)
    self.rh = ratioH*recip
    self.rb = ratioB*recip
    self.rt = ratioT*recip
    self.img1 = img .. "1"
    self.img2 = img .. "2"
    self.img3 = img .. "3"
    self.layer = LAYER_ENEMY_BULLET
    self.group = GROUP_ENEMY_BULLET
    self.item = 30
end
function laser:frame()
    task.Do(self)
    if self.lastrot ~= self.rot then
        self.dirvec = Vector.fromAngle(self.rot)
        self.tdvec = self.dirvec:perpendicular()
    end
    self.lastrot = self.rot
    if self.dying or not self.colli then return end
    for i, obj in ObjList(GROUP_PLAYER) do
        local cP, cR, pA, pB, pR = Vector.fromTable(obj),obj.a,
        Vector.fromTable(self)+self.dirvec*self.l*0.1,Vector.fromTable(self)+self.dirvec*self.l*0.9,self.w*0.45

        local h = clamp( ((cP - pA) % (pB - pA))/((pB - pA) % (pB - pA)), 0, 1)
        local l2 = (cP-pA-(pB-pA)*h).length2
        if h < self.rh then
            pR = lerp(0,pR,h/self.rh)
        elseif 1-h < self.rt then
            pR = lerp(0, pR, (1-h)/self.rt)
        end
        local final_r = cR + pR
        if l2 < final_r*final_r then
            Collide(self,obj)
        end
    end
    if self.timer % 4 == 0 then
        self._graze = false
    end
end
function laser:render()
    local _x, _y = self.x, self.y
    local dv, tv = self.dirvec*self.l, self.tdvec*-self.w
    local v0 = Vector.zero
    local v1 = dv * self.rh
    local v2 = dv * (self.rh + self.rb)
    SetImageState(self.img1,self.rm,self.color)
    SetImageState(self.img2,self.rm,self.color)
    SetImageState(self.img3,self.rm,self.color)
    Render4V(self.img2,
            _x+tv.x+v1.x, _y+tv.y+v1.y,0,
            _x+tv.x+v2.x, _y+tv.y+v2.y,0,
            _x-tv.x+v2.x, _y-tv.y+v2.y,0,
            _x-tv.x+v1.x, _y-tv.y+v1.y,0
    )
    Render4V(self.img1,
            _x+tv.x+v0.x, _y+tv.y+v0.y,0,
            _x+tv.x+v1.x, _y+tv.y+v1.y,0,
            _x-tv.x+v1.x, _y-tv.y+v1.y,0,
            _x-tv.x+v0.x, _y-tv.y+v0.y,0
    )
    Render4V(self.img3,
            _x+tv.x+v2.x, _y+tv.y+v2.y,0,
            _x+tv.x+dv.x, _y+tv.y+dv.y,0,
            _x-tv.x+dv.x, _y-tv.y+dv.y,0,
            _x-tv.x+v2.x, _y-tv.y+v2.y,0
    )
end
local tween = math.tween.cubicInOut
function laser:kill()
    PreserveObject(self)
    if self.dying then
        return
    end
    self.dying = true
    task.Clear(self)
    task.New(self, function()
        local w1 = self.w
        for i=0,1,1/10 do
            self.w = lerp(w1,0,tween(i))
            task.Wait(1)
        end
        if self.item then
            for i=0, self.l, self.item do
                local t = i/self.l
                SpawnPIV(self.x + self.dirvec.x*self.l*t,self.y + self.dirvec.y*self.l*t)
            end
        end
        RawKill(self)
    end)
end
function laser:del()
    PreserveObject(self)
    if self.dying then
        return
    end
    self.dying = true
    task.Clear(self)
    task.New(self, function()
        local w1 = self.w
        for i=0,1,1/10 do
            self.w = lerp(w1,0,tween(i))
            task.Wait(1)
        end
        RawDel(self)
    end)
end
do return end
Include("THlib\\laser\\bent laser.lua")
