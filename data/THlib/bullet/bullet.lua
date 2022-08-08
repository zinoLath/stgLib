
----------------------------------------------------------------
-- TODO: optimize ObjList / make Dist accept group

local ObjList = ObjList
local Dist = Dist
local Kill = Kill
--local GROUP_INDES = GROUP_INDES
--local GROUP_ENEMY_BULLET = GROUP_ENEMY_BULLET

local ran = ran
local New = New
local Del = Del
local Color = Color
local GetAttr = GetAttr
local lerp = math.lerp
local EaseOutCubic = math.tween.cubicInOut
local LAYER_ENEMY_BULLET = LAYER_ENEMY_BULLET
local GROUP_ENEMY_BULLET = GROUP_ENEMY_BULLET
local color_white = Color(255,255,255,255)
local SetV = SetV
local path = GetCurrentScriptDirectory()

-- TODO: use shader coded inside the engine
-- TODO: rewrite the bullet class

local sheet_handler = Include(path .. "bullet_sheet.lua")
local shot_sheet = sheet_handler.parse()
sheet_handler.optimize_sheet(shot_sheet)

bullet = Class(object)
function bullet:init(img,color)
    local bullet_style = shot_sheet.shots[img]
    local size = __size or 64
    self.res = bullet_style[1]
    self.imgid = img
    self.color = color 
    self.layer = LAYER_ENEMY_BULLET
    self.group = GROUP_ENEMY_BULLET
end
function bullet:frame()
    task.Do(self)
    if self.timer < self.dt then
        local j = (self.timer-self.d_base)/(self.dt-self.d_base)
        local i = EaseOutCubic(j)
        local scale = lerp(3.5,1,i)*2.25
        self.hscale,self.vscale = scale*self._scale, scale*self._scale
        self.A = lerp(0,255 or self._alpha,i)
    end
end

function ChangeBulletImage(obj,img,color,rm)
    obj.img = img
    obj.color = color
    obj.rm = rm or 'bul++'
end

function bullet:kill()
    --New(item_faith_minor, self.x, self.y)
    SpawnPIV(self.x,self.y)
    New(BulletBreak, self.x, self.y, self.color)
end
function bullet:del()
    New(BulletBreak, self.x, self.y, self.color)
end
function bullet:delay(time)
    self.dt = time + self.timer
    self.d_base = self.timer
end
function bullet:setSize(size)
    local bullet_style = bullet_styles[self.imgid]
    local _scale = (size or 64)/64
    self._scale = _scale
    self.a, self.b = bullet_style[2]*_scale, bullet_style[2]*_scale
    self.hscale, self.vscale = _scale*2.25, _scale*2.25
end

BulletBreak = Class(object)

---初始化消弹效果
---@param x number
---@param y number 位置
---@param index number 序号（颜色标识）
function BulletBreak:init(x, y, color)
    self.x = x
    self.y = y
    self.group = GROUP_GHOST
    self.layer = LAYER_ENEMY_BULLET - 50
    --随机缩放
    local s = ran:Float(0.5, 0.75)*2.25
    self.hscale = s
    self.vscale = s
    --随机旋转
    self.rot = ran:Float(0, 360)
    self.img = "zbreak"
    self.color = color
end

function BulletBreak:frame()
    if GetAttr(self, 'timer') == 23 then
        Del(self)
    end
end

straight = Class(bullet)
function straight:init(type, color, x, y, rot, speed, size, omiga, blend, delaytime, indes)
    bullet.init(self,type, color, blend, size)
    bullet.delay(self, delaytime or 7)
    self.x, self.y = x,y
    SetV(self, speed, rot)
    self.rot = rot
    self.omiga = omiga or 0
    --self.group = ternary(indes, GROUP_INDES, GROUP_ENEMY_BULLET)
    self.group = indes and GROUP_INDES or GROUP_ENEMY_BULLET
end

straight_pattern = Class(bullet)
function straight_pattern:init(pattern,params,l,tl,c)
    local p = params
    local stangle = p.angle
    if p.aim then
        stangle = Angle(params.master.x, params.master.y,player.x,player.y) + p.angle
    end
    local ang = stangle + (p.spread/p.count) * (c-p.count/2) + ran:Float(p.jitter/-2, p.jitter/2)
    local radVec = params.shape:dist(ang)
    local radVecL = radVec.length
    local radVecA = radVec.angle
    self.x, self.y = (Vector.getCopy(params.master) + params.offset + radVec * params.radius):unpack()
    SetV(self, radVecL*p.speed, radVecA)
    if p.accel ~= 0 or p.gravity ~= 0 then
        SetA(self, p.accel*radVecL, radVecA, p.maxv, 0, 0, false)
    end
    self.rot = radVecA
    self.angle = radVecA
    bullet.init(self,p.type, p.color, p.rm, p.size)
    bullet.delay(self, p.visual_delay)
    self.group = p.indes and GROUP_INDES or GROUP_ENEMY_BULLET
    self.omiga = p.omiga
end

---
---@class THlib.bullet_killer:object
bullet_killer = Class(object)
function bullet_killer:init(x, y, kill_indes)
    self.x = x
    self.y = y
    self.group = GROUP_GHOST
    self.hide = true
    self.kill_indes = kill_indes
end
function bullet_killer:frame()
    --kill范围为圆形逐渐增大
    if self.timer == 40 then
        Del(self)
    end
    local range = self.timer * 20
    for i, o in ObjList(GROUP_ENEMY_BULLET) do
        if Dist(self, o) < range then
            Kill(o)
        end
    end
    if self.kill_indes then
        for i, o in ObjList(GROUP_INDES) do
            if Dist(self, o) < range then
                Kill(o)
            end
        end
    end
end
----------------------------------------------------------------


---
---@class THlib.bullet_deleter:object
bullet_deleter = Class(object)
function bullet_deleter:init(x, y, kill_indes)
    self.x = x
    self.y = y
    self.group = GROUP_GHOST
    self.hide = true
    self.kill_indes = kill_indes
end
function bullet_deleter:frame()
    if self.timer == 60 then
        Del(self)
    end
    local range = self.timer * 20
    for i, o in ObjList(GROUP_ENEMY_BULLET) do
        if Dist(self, o) < range then
            Del(o)
        end
    end
    if self.kill_indes then
        for i, o in ObjList(GROUP_INDES) do
            if Dist(self, o) < range then
                Del(o)
            end
        end
    end
end
--------------------------------------------------------------


---
---@class THlib.bullet_killer_SP:object
bullet_killer_SP = Class(object)
function bullet_killer_SP:init(x, y, kill_indes)
    self.x = x
    self.y = y
    self.group = GROUP_GHOST
    self.hide = false
    self.kill_indes = kill_indes
    self.img = 'yubi'
end
function bullet_killer_SP:frame()
    self.rot = -6 * self.timer
    if self.timer == 60 then
        Del(self)
    end
    for i, o in ObjList(GROUP_ENEMY_BULLET) do
        if Dist(self, o) < 60 then
            Kill(o)
        end
    end
    if self.kill_indes then
        for i, o in ObjList(GROUP_INDES) do
            if Dist(self, o) < 60 then
                Kill(o)
            end
        end
    end
end
--------------------------------------------------------------


---
---@class THlib.bullet_deleter2:object
bullet_deleter2 = Class(object)
function bullet_deleter:init(x, y, kill_indes)
    self.x = player.x
    self.y = player.y
    self.group = GROUP_GHOST
    self.hide = true
    self.kill_indes = kill_indes
end
function bullet_deleter2:frame()
    self.x = player.x
    self.y = player.y
    if self.timer == 30 then
        Del(self)
    end
    local range = self.timer * 5
    for i, o in ObjList(GROUP_ENEMY_BULLET) do
        if Dist(self, o) < range then
            Del(o)
        end
    end
    if self.kill_indes then
        for i, o in ObjList(GROUP_INDES) do
            if Dist(self, o) < range then
                Del(o)
            end
        end
    end
end

--------------------------------------------------------------
--------------------------------------------------------------


---
---@class THlib.bomb_bullet_killer:object Bomb消弹
bomb_bullet_killer = Class(object)
function bomb_bullet_killer:init(x, y, a, b, kill_indes)
    self.x = x
    self.y = y
    self.a = a
    self.b = b
    --a不等于b则为矩形碰撞盒
    if a ~= b then
        self.rect = true
    end
    self.group = GROUP_PLAYER
    self.hide = true
    self.kill_indes = kill_indes
end
function bomb_bullet_killer:frame()
    --只存在1帧
    --if self.timer == 1 then
    Del(self)
    --end
end
function bomb_bullet_killer:colli(other)
    local group = GetAttr(other, 'group')
    if rawget(self, 'kill_indes') then
        if group == GROUP_INDES then
            Kill(other)
        end
    end
    if group == GROUP_ENEMY_BULLET then
        Kill(other)
    end
end
--------------------------------------------------------------
COLOR_DEEP_RED = 1
COLOR_RED = 2
COLOR_DEEP_PURPLE = 3
COLOR_PURPLE = 4
COLOR_DEEP_BLUE = 5
COLOR_BLUE = 6
COLOR_ROYAL_BLUE = 7
COLOR_CYAN = 8
COLOR_DEEP_GREEN = 9
COLOR_GREEN = 10
COLOR_CHARTREUSE = 11
COLOR_YELLOW = 12
COLOR_GOLDEN_YELLOW = 13
COLOR_ORANGE = 14
COLOR_DEEP_GRAY = 15
COLOR_GRAY = 16