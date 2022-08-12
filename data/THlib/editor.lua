_editor_class = {}

---32位整数的最大值
_infinite = 4294967296

local max = max
local int = int
local sin = sin
local cos = cos
local sqrt = sqrt

local task = task
local task_Do = task.Do
local Kill = Kill
local Del = Del
local misc = misc
local Color = Color
local New = New
local IsValid = IsValid
local SetV2 = SetV2
local Angle = Angle
local SetImgState = SetImgState
local DefaultRenderFunc = DefaultRenderFunc
local ParticleGetn = ParticleGetn
local PlaySound = PlaySound
local coroutine_yield = coroutine.yield
local rawget = rawget
local GetAttr = GetAttr
local SetAttr = SetAttr

function uvec(x,y)
    if y then
        return Vector(x,y)
    else
        return Vector(x.x, x.y)
    end
end
function getclass(c)
    return _editor_class[c] or _G[c] or c
end

---task._Wait(t)
---延时t帧（挂起协程t次）
function task._Wait(t)
    t = max(0, int(t or 0))
    for i = 1, t do
        coroutine_yield()
    end
end

local bullet = bullet
local bullet_frame = bullet.frame
local straight_495 = straight_495

---@class THlib._straight:THlib.bullet
_straight = zclass(bullet)
function _straight:init(imgclass, index, x, y, v, angle, aim, omiga,
                        stay, destroyable, time, _495, accel, accangle, maxv, through)
    self.x = x
    self.y = y
    time = time or 0
    self.rot = angle
    if aim then
        self.rot = self.rot + Angle(self, player)
    end
    self.omiga = omiga
    if accangle == 'original' then
        accangle = self.rot
    end
    bullet.init(self, imgclass, index, stay, destroyable)
    if time and time ~= 0 then
        New(tasker, function()
            task.Wait(time)
            if IsValid(self) then
                SetV2(self, v, self.rot, true, false)
                if accel then
                    SetA(self, accel, accangle, maxv, 0, 0, false)
                end
            end
        end)
    else
        SetV2(self, v, self.rot, true)
        if accel then
            SetA(self, accel, accangle, maxv, 0, 0, false)
        end
    end
    self._495 = _495
    self.through = through
    --self.hide = true
end

function _straight:frame()
    if rawget(self, 'through') then
        local world = lstg.world
        --穿屏一次
        local x, y = GetAttr(self, 'x'), GetAttr(self, 'y')
        if y > world.t then
            self.y = y - (world.t - world.b)
            self.through = nil
        end
        if y < world.b then
            self.y = y + (world.t - world.b)
            self.through = nil
        end
        if x > world.r then
            self.x = x - (world.r - world.l)
            self.through = nil
        end
        if x < world.l then
            self.x = x + (world.r - world.l)
            self.through = nil
        end
    end
    if rawget(self, '_495') and not rawget(self, 'reflected') then
        straight_495.frame(self)
    else
        bullet_frame(self)
    end
end

function _color(a,r,g,b)
    if type(a) ==  'userdata' then
        return a
    end
    return Color(a,r,g,b)
end
function _drop_item(itemclass, num, x, y)
    local switch = {
        [item_power]       = function()
            item.DropItem(x, y, { num, 0, 0 })
        end,
        [item_faith]       = function()
            item.DropItem(x, y, { 0, num, 0 })
        end,
        [item_point]       = function()
            item.DropItem(x, y, { 0, 0, num })
        end,
        [item_power_large] = function()
            for i = 1, num do
                local r2 = sqrt(ran:Float(1, 4)) * sqrt(num - 1) * 5
                local a = ran:Float(0, 360)
                --New(item_power_large, x + r2 * cos(a), y + r2 * sin(a))
            end
        end,
        [item_power_full]  = function()
            for i = 1, num do
                local r2 = sqrt(ran:Float(1, 4)) * sqrt(num - 1) * 5
                local a = ran:Float(0, 360)
                --New(item_power_full, x + r2 * cos(a), y + r2 * sin(a))
            end
        end,
        [item_faith_minor] = function()
            for i = 1, num do
                local r2 = sqrt(ran:Float(1, 4)) * sqrt(num - 1) * 5
                local a = ran:Float(0, 360)
                --New(item_faith_minor, x + r2 * cos(a), y + r2 * sin(a))
            end
        end,
        [item_extend]      = function()
            for i = 1, num do
                local r2 = sqrt(ran:Float(1, 4)) * sqrt(num - 1) * 5
                local a = ran:Float(0, 360)
                --New(item_extend, x + r2 * cos(a), y + r2 * sin(a))
            end
        end,
        [item_chip]        = function()
            for i = 1, num do
                local r2 = sqrt(ran:Float(1, 4)) * sqrt(num - 1) * 5
                local a = ran:Float(0, 360)
                --New(item_chip, x + r2 * cos(a), y + r2 * sin(a))
            end
        end,
        [item_bombchip]    = function()
            for i = 1, num do
                local r2 = sqrt(ran:Float(1, 4)) * sqrt(num - 1) * 5
                local a = ran:Float(0, 360)
                --New(item_bombchip, x + r2 * cos(a), y + r2 * sin(a))
            end
        end,
        [item_bomb]        = function()
            for i = 1, num do
                local r2 = sqrt(ran:Float(1, 4)) * sqrt(num - 1) * 5
                local a = ran:Float(0, 360)
                --New(item_bomb, x + r2 * cos(a), y + r2 * sin(a))
            end
        end
    }
    switch[itemclass]()
end

function _play_music(name)
    local _, bgm = EnumRes('bgm')
    for _, v in pairs(bgm) do
        StopMusic(v)
    end
    PlayMusic(name)
end
function _pause_music()
    local _, bgm = EnumRes('bgm')
    for _, v in pairs(bgm) do
        PauseMusic(v)
    end
end
function _resume_music()
    local _, bgm = EnumRes('bgm')
    for _, v in pairs(bgm) do
        ResumeMusic(v)
    end
end
function _stop_music()
    local _, bgm = EnumRes('bgm')
    for _, v in pairs(bgm) do
        StopMusic(v)
    end
end

---@class THlib.bubble3:object
bubble3 = Class(object)

function bubble3:init(img, x, y, rot, vx, vy, omiga, life_time, size1, size2, color1, color2, layer, blend)
    self.img = img
    self.x = x
    self.y = y
    self.rot = rot
    self.vx = vx
    self.vy = vy
    self.omiga = omiga
    self.group = GROUP_GHOST
    self.life_time = life_time
    self.size1 = size1
    self.size2 = size2
    self.color1 = color1
    self.color2 = color2
    self.layer = layer
    self.blend = blend or ''
end

function bubble3:render()
    local t = (self.life_time - self.timer) / self.life_time
    self.hscale = self.size1 * t + self.size2 * (1 - t)
    self.vscale = self.hscale
    local c = self.color1 * t + self.color2 * (1 - t)
    SetImgState(self, self.blend, c:ARGB())
    DefaultRenderFunc(self)
end

function bubble3:frame()
    if self.timer == self.life_time - 1 then
        Del(self)
    end
end

function _clear_bullet(convert, clear_indes)
    if convert then
        New(bullet_killer, lstg.player.x, lstg.player.y, clear_indes)
    else
        New(bullet_deleter, lstg.player.x, lstg.player.y, clear_indes)
    end
end

function _init_item(self)
    if lstg.var.is_practice then
        item.PlayerInit()
        if self.item_init then
            for k, v in pairs(self.item_init) do
                lstg.var[k] = v
            end
        end
    else
        if self.number == 1 then
            item.PlayerInit()
            if self.group.item_init then
                for k, v in pairs(self.group.item_init) do
                    lstg.var[k] = v
                end
            end
        end
    end
end

function _kill(unit, trigger)
    if trigger then
        Kill(unit)
    else
        RawKill(unit)
    end
end

function _del(unit, trigger)
    if trigger then
        Del(unit)
    else
        RawDel(unit)
    end
end

function ConnectObj(master, servant, dmg_transfer, con_death)
    if IsValid(master) and IsValid(servant) then
        if con_death then
            master._servants = master._servants or {}
            table.insert(master._servants, servant)
        end
        servant._master = master
        servant._dmg_transfer = dmg_transfer
    end
end
function SetRelativePos(servant, x, y, rot, follow_rot)
    if servant._master and IsValid(servant._master) then
        local master = servant._master
        if follow_rot then
            x, y = x * cos(master.rot) - y * sin(master.rot), x * sin(master.rot) + y * cos(master.rot)
            rot = rot + master.rot
        end
        servant.x = master.x + x
        servant.y = master.y + y
        servant.rot = rot
    end
end

---
--- 对_servants中所有对象执行Kill，清空_servants
function KillServants(master)
    for k, v in pairs(master._servants) do
        if IsValid(v) then
            Kill(v)
        end
    end
    master._servants = {}
end

---
--- 对_servants中所有对象执行Del，清空_servants
function DelServants(master)
    for k, v in pairs(master._servants) do
        if IsValid(v) then
            Del(v)
        end
    end
    master._servants = {}
end

_sc_table = {}

---
--- 设置加速度
---@param self object
---@param accel number
---@param angle number
---@param maxv number
---@param gravity number
---@param maxvy number
---@param navi boolean
function SetA(self, accel, angle, maxv, gravity, maxvy, navi)
    self.navi = navi
    if accel ~= 0 then
        self.ax, self.ay = accel * cos(angle),  accel * sin(angle)
    end
    if gravity ~= 0 then
        self.g = gravity
    end
    if maxv ~= 0 then
        self.maxv = maxv
    end
    if maxvy ~= 0 then
        self.maxvy = maxvy
    end
end

---@class THlib.bullet_cleaner:object
bullet_cleaner = Class(object)
function bullet_cleaner:init(x, y, radius, time, time2, into, indes, v)
    self.x = x
    self.y = y
    if time == 0 then
        self.radius = radius
    else
        self.radius = 0
        self.delta = radius / time
    end
    self.time = time
    self.time2 = time2
    self.into = into
    self.indes = indes
    self.bound = false
    self.group = GROUP_PLAYER
    self.a = self.radius
    self.b = self.radius
    self.vy = v or 0.2
end

function bullet_cleaner:frame()
    if self.timer < self.time then
        self.radius = self.radius + self.delta
        self.a = self.radius
        self.b = self.radius
    end
    if self.timer > self.time2 then
        RawDel(self)
    end
end

function bullet_cleaner:colli(other)
    if other.group == GROUP_ENEMY_BULLET or (self.indes and other.group == GROUP_INDES) then
        if self.into then
            Kill(other)
        else
            Del(other)
        end
    end
end

function MakeSmear(obj, length, interval, blend, color, size)
    if IsValid(obj) and ImageList[obj.img] then
        length = length or 10
        interval = interval or 1
        blend = blend or ''
        color = color or { 255, 255, 255, 255, 0, 255, 255, 255 }
        --size = size or {1,0}
        New(smear, obj, length, interval, blend, color, size)
    else
        error("Invalid object or not a object with image")
    end
end

---@class THlib.smear:object
smear = Class(object)
smear.cache = {}
smear.func = function(img)
    if not smear.cache[img] then
        smear.cache[img] = img .. "_smear_psi"
        --LoadPS(img.."_smear_psi","THlib\\smear.psi",img)
        LoadPS(img .. "_smear_psi", "THlib/smear.psi", img)
    end
    return smear.cache[img]
end
function smear:init(obj, interval)
    self.master = obj
    self.emission = 60 / (interval or 1)
    self.layer = obj.layer - 1
    self.bound = false
end

function smear:frame()
    if self.notframe then
        return
    end
    if not IsValid(self.master) then
        Kill(self)
        return
    end
    self.x = self.master.x
    self.y = self.master.y
    self.rot = self.master.rot
    if self.master.hide or not self.master.img then
        self.hide = true
    else
        self.hide = false
        self.img = smear.func(self.master.img)
        ParticleSetEmission(self, self.emission)
    end
end

function smear:kill()
    self.status = 'normal'
    self.notframe = true
    New(tasker, function()
        local m = ParticleGetEmission(self)
        while true do
            if m < 0 then
                break
            end
            ParticleSetEmission(self, m)
            m = m - 5
            task.Wait(1)
        end
        task.Wait(30)
        Del(self)
    end)
end

-- Include("THlib/Queue.lua")
-- Include("THlib/Heap.lua")
-- Include("THlib/List.lua")
-- Include("THlib/Array.lua")
-- Include("THlib/Class.lua")

---@class THlib.RenderObject:object
RenderObject = Class(object)

function RenderObject:init(parent, image, x, y, rot, h, v, layer, tf)
    self.img = image
    self.x, self.y = x, y
    self.rot = rot
    self.hscale, self.vscale = h, v
    self.task = {}
    self.master = parent
    self.layer = layer
    tf(self)
end

function RenderObject:frame()
    if not IsValid(self.master) and stage.current_stage ~= self.master then
        Del(self)
        return
    end
    task.Do(self)
end

function GetA(obj)
    local acc = {}
    if obj.acceleration then
        acc = obj.acceleration
    end
    return acc.ax or 0, acc.ay or 0
end

function GetG(obj)
    return obj.g
end

function GetFV(obj)
    local fv = {}
    return fv.v or 0, fv.vx or 0, fv.vy or 0
end

local musicrecording = {}

---保存音乐播放需要的参数
function MusicRecord(name, path, loopend, looplength)
    musicrecording[name] = { path, loopend, looplength }
end

---根据MusicRecord保存的参数播放音乐
function LoadMusicRecord(name)
    if type(musicrecording[name]) == "table" then
        LoadMusic(name, unpack(musicrecording[name]))
        --musicrecording[name] = name
    end
end
