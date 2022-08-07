--
local path = GetCurrentScriptDirectory()

local rawset = rawset
local rawget = rawget
local int = math.floor
local max = math.max
local min = math.min
local sqrt = sqrt
local ran = ran
local cos = cos
local sin = sin
local New = New
local Del = Del
local Render = Render
local Color = Color
local BoxCheck = BoxCheck
local lerp = math.lerp
local clamp = math.clamp

---@class THlib.item:object 道具类
---@field sc_bonus_max number
---@field sc_bonus_base number
item = {  }
local item = item

---
---产生道具掉落
---x,y：位置
function item.DropItem(x, y, drop)
    for i=1, drop.life do
        
    end
end

item.sc_bonus_max = 50000000
item.sc_bonus_base = 0

---重置碎片奖励标志
function item.StartChipBonus()
    lstg.var.chip_bonus = true
    lstg.var.bombchip_bonus = true
end

---
---碎片奖励结算（默认）
function item.EndChipBonus(x, y)
    if lstg.var.chip_bonus and lstg.var.bombchip_bonus then
        --同时奖励时并排分开
        --New(item_chip, x - 20, y)
        --New(item_bombchip, x + 20, y)
    else
        if lstg.var.chip_bonus then
            --New(item_chip, x, y)
        end
        if lstg.var.bombchip_bonus then
            --New(item_bombchip, x, y)
        end
    end
end

---初始化自机信息（道具相关）
function item.PlayerInit()
    lstg.var.power = 100
    lstg.var.collect_line = 130
    lstg.var.lifeleft = 2
    lstg.var.bomb = 3
    lstg.var.bonusflag = 0
    lstg.var.chip = 0
    lstg.var.faith = 0
    lstg.var.graze = 0
    lstg.var.score = 0
    lstg.var.bombchip = 0
    lstg.var.coun_num = 0
    lstg.var.pointrate = item.PointRateFunc(lstg.var)
    lstg.var.score_mul = {}
    lstg.var.piv_mul = {}
    lstg.var.block_spell = false
    lstg.var.chip_bonus = false
    lstg.var.bombchip_bonus = false
    lstg.var.init_player_data = true
    lstg.var.dfrag = 0
end
------------------------------------------

---重置部分自机信息（道具相关）
function item.PlayerReinit()
    lstg.var.power = 400
    lstg.var.lifeleft = 2
    lstg.var.chip = 0
    lstg.var.bomb = 2
    lstg.var.bomb_chip = 0
    lstg.var.block_spell = false
    lstg.var.init_player_data = true
    lstg.var.coun_num = min(9, lstg.var.coun_num + 1)
    lstg.var.score = lstg.var.coun_num
    lstg.var.dfrag = 0
    --if lstg.var.score % 10 ~= 9 then item.AddScore(1) end
end
------------------------------------------

---HZC的收点系统
function item.playercollect(z)

end
-----------------------------

---处理Miss（道具相关）
function item.PlayerMiss()
    lstg.var.chip_bonus = false
    if lstg.var.sc_bonus then
        lstg.var.sc_bonus = 0
    end
    player.protect = 360
    lstg.var.lifeleft = lstg.var.lifeleft - 1
    lstg.var.bomb = 3
end

---处理Bomb（道具相关）
function item.PlayerSpell()
    if lstg.var.sc_bonus then
        lstg.var.sc_bonus = 0
    end
    lstg.var.bomb = lstg.var.bomb -1
    lstg.var.bombchip_bonus = false
end

---处理擦弹（道具相关）
---擦弹数+1 分数+50
function item.PlayerGraze()
    lstg.var.graze = lstg.var.graze + 1
    lstg.var.score = lstg.var.score + 50
end

---计算最大得点
function item.PointRateFunc(var)
    local r = 100000 + int(var.faith*5 / 10) * 10
    return r
end
LoadImageFromFile("item_spawn_animation", path.."spawn.png")
LoadImageFromFile("item_bomb", path.."bomb.png")
LoadImageFromFile("item_point", path.."point.png")
LoadImageFromFile("item_life", path.."life.png")
LoadImageFromFile("item_piv1", path.."piv.png")
LoadImageFromFile("item_piv2", path.."piv_bomb.png")
local tweenk = math.tween.cubicInOut
item.spawn_obj = Class()
function item.spawn_obj:init(x,y,size)
    self.final_size = size/16
    self.img = "item_spawn_animation"
    self.x,self.y = x,y
    self.layer = LAYER_ITEM-30
    self.t = 30
    self.colli = false
    self.group = GROUP_GHOST
    self.hscale, self.vscale = 0,0
end
function item.spawn_obj:frame()
    if self.timer == self.t then
        Del(self)
    end
    self.hscale, self.vscale = (self.final_size*tweenk(self.timer/self.t))*self.final_size,
    (self.final_size*tweenk(self.timer/self.t))*self.final_size
    self.A = 255-255*tweenk(self.timer/self.t)
end
local item_colli_size = 192
item.base_item = Class()
function item.base_item:init(x,y,v,vy_bonus,rot,img,size)
    self.spawn_size = self.spawn_size or size*2
    self.final_size = size/16
    New(item.spawn_obj,x,y,self.spawn_size)
    self.x, self.y = x,y
    self.group = GROUP_ITEM
    self.layer = LAYER_ITEM
    self.img = img
    self.mvy = sin(rot+180)*0.5 + 0.5
    self.vx, self.vy = v * cos(rot), v *sin(rot)
    self.vy = self.vy + vy_bonus
    self.rot = 2
    self.omiga = 5
    self.ay = -0.15
    self.t = 30
    self.come_speed = 6
    self.a, self.b = item_colli_size*self.final_size, item_colli_size*self.final_size
    self.hscale, self.vscale = 0,0
    self.A = 0
end
function item.base_item:frame()
    task.Do(self)
    if self.timer < self.t then
        self.hscale, self.vscale = (self.final_size*tweenk(self.timer/self.t)),(self.final_size*tweenk(self.timer/self.t))
        self.A = 255*tweenk(self.timer/self.t)
    end
    local dist_player = Dist(self,player)
    if (self.collect == nil or self.collect == false) and (player.y > lstg.var.collect_line or dist_player < 128) then
        self.collect = true
    end
    if self.collect == true then
        self.collect = player
    end
    if self.vy < -3*self.mvy-6 then
        self.vy = -3*self.mvy-6
    end
    if self.collect and self.timer > self.t then
        self.vx, self.vy, self.ay, self.ax = 0,0,0,0
        SetV(self,self.come_speed,Angle(self,self.collect))
    end
end
function item.base_item:colli(other)
    if other == player then
        self.class.collect(self)
        Kill(self)
    end
end
function item.base_item:collect()

end
function item.base_item:kill()
    PreserveObject(self)
    self.group = GROUP_GHOST
    task.New(self, function()
        local alpha = self.A
        local scalex, scaley = self.hscale, self.vscale
        for i=0, 1, 1/15 do
            self.A = lerp(alpha,0,tweenk(i))
            self.hscale = lerp(scalex,scalex*1.2,tweenk(clamp(i*6,0,1)))
            self.vscale = lerp(scaley,scaley*1.2,tweenk(clamp(i*6,0,1)))
            coroutine.yield()
        end
        Del(self)
    end)
end
item.point = Class(item.base_item)
function item.point:init(x,y,v,vy_bonus,rot,score)
    local size = lerp(8,16,math.clamp(score/1000000,0,1))
    self.spawn_size = size * 1
    self.score = score
    item.base_item.init(self,x,y,v,vy_bonus,rot,"item_point",size)
end
function item.point:collect()
    lstg.var.score = lstg.var.score + self.score
end
function GetResource(id,v,onget,mult)
    mult = mult or 1
    local prev = lstg.var[id]
    lstg.var[id] = lstg.var[id] + v
    if int(lstg.var[id]/mult) ~= int(prev/mult) then
        return onget(prev,id)
    end
end
function GetLife(v)
    return GetResource("lifeleft", v, function()
        PlaySound("extend", 1)
    end)
end
function GetBomb(v)
    return GetResource("bomb", v, function()
        PlaySound("powerup", 1)
    end)
end
function SpawnPIV(x,y)
    return New(item.piv,x,y,0,2,90,MultiplyTable(lstg.var.piv_mul)*(lstg.var.faith/1000))
end
item.life = Class(item.base_item)
function item.life:init(x,y,v,vy_bonus,rot,life)
    local size = lerp(8,32,math.clamp(life,0,1))
    self.spawn_size = size * 2
    self.life = life
    item.base_item.init(self,x,y,v,vy_bonus,rot,"item_life",size)
end
function item.life:collect()
    GetLife(self.life)
end
item.bomb = Class(item.base_item)
function item.bomb:init(x,y,v,vy_bonus,rot,life)
    local size = lerp(8,32,math.clamp(life,0,1))
    self.spawn_size = size * 2
    self.life = life
    item.base_item.init(self,x,y,v,vy_bonus,rot,"item_bomb",size)
end
function item.bomb:collect()
    GetBomb(self.life)
end
item.piv = Class(item.base_item)
function item.piv:init(x,y,v,vy_bonus,rot,value)
    local size = lerp(8,32,math.clamp(value/10000,0,1))
    self.spawn_size = size + 5
    self.value = value
    item.base_item.init(self,x,y,v,vy_bonus,rot,"item_piv1",size)
    self.t = 10
    self.come_speed = 12
    self.bombed = false
    self.ay = -0.05
end
function item.piv:frame()
    if self.bombed then
        self.img = "item_piv2"
        self.a, self.b = item_colli_size*self.final_size, item_colli_size*self.final_size
    end
    item.base_item.frame(self)
end
function item.piv:collect()
    lstg.var.faith = lstg.var.faith + self.value * (self.bombed and 2 or 1)
end