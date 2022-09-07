
----------------------------------------------------------------
-- TODO: optimize ObjList / make Dist accept group

local ObjList = ObjList
local Dist = Dist
local Kill = Kill

local ran = ran
local New = New
local Del = Del
local Color = Color
local GetAttr = GetAttr
local lerp = math.lerp
local EaseOutCubic = math.tween.cubicInOut
local LAYER_ENEMY_BULLET = LAYER_ENEMY_BULLET
local GROUP_ENEMY_BULLET = GROUP_ENEMY_BULLET
local SetV = SetV
local path = GetCurrentScriptDirectory()

local sheet_handler = Include(path .. "bullet_sheet.lua")
local shot_sheet = sheet_handler.parse()
sheet_handler.optimize_sheet(shot_sheet)

local centerDefaultColor = Color(255,0,255,255)
bullet = zclass(object)
bullet.default_function = 0x10
function bullet:init(img,color,subcolor,blend)
    local bullet_style = shot_sheet.shots[img]
    self.img = bullet_style[1]
    self.imgid = img
    self._color = color
    self._subcolor = subcolor or centerDefaultColor
    self._blend = blend
    self.layer = LAYER_ENEMY_BULLET
    self.group = GROUP_ENEMY_BULLET
end
function bullet:frame()
    task.Do(self)
    if self.timer < self.dt then
        local j = (self.timer-self.d_base)/(self.dt-self.d_base)
        local i = EaseOutCubic(j)
        local scale = lerp(3.5,1,i)*2.25
        self.hscale,self.vscale = scale, scale
        self._a = lerp(0,255 or self._alpha,i)
    end
end

function ChangeBulletImage(obj,img,color,subcolor,rm)
    obj.img = img
    obj._color = color
    obj._subcolor = subcolor
    obj._blend = rm or 'grad+alpha'
end

function bullet:kill()
    --New(item_faith_minor, self.x, self.y)
    SpawnPIV(self.x,self.y)
    New(BulletBreak, self.x, self.y, self._color)
end
function bullet:del()
    New(BulletBreak, self.x, self.y, self._color)
end
function bullet:delay(time)
    self.dt = time + self.timer
    self.d_base = self.timer
end
function bullet:setSize(size)
    local bullet_style = shot_sheet.shots[self.imgid]
    local _scale = (size or 64)/64
    self._scale = _scale
    self.a, self.b = bullet_style[2]*_scale, bullet_style[2]*_scale
    self.hscale, self.vscale = _scale*2.25, _scale*2.25
end

BulletBreak = zclass(object)
CopyImage("zbreak","white")
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
    self._color = color
end

function BulletBreak:frame()
    if GetAttr(self, 'timer') == 23 then
        Del(self)
    end
end
local default_sub = color.White
local default_delay = 13
local default_blend = "grad+alpha"
function CreateShotA(x,y,speed,angle,graphic,color,subcolor,blend,delay)
    subcolor = subcolor or default_sub
    delay = delay or default_delay
    blend = blend or default_blend
    return New(straight,graphic,color,subcolor,x,y,angle,speed,0,blend,delay)
end
straight = zclass(bullet)
function straight:init(type, color, subcolor, x, y, rot, speed, omiga, blend, delaytime, indes)
    bullet.init(self,type, color, subcolor, blend)
    bullet.delay(self, delaytime or 7)
    self.x, self.y = x,y
    SetV(self, speed, rot)
    self.rot = rot
    self.omiga = omiga or 0
    self.group = indes and GROUP_INDES or GROUP_ENEMY_BULLET
end

straight_pattern = zclass(bullet)
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
