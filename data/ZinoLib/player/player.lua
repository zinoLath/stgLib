local clamp = math.clamp
local event = lstg.eventDispatcher
local lerp = math.lerp
local path = GetCurrentScriptDirectory()
LoadImageFromFile("hitbox_player", path.."hitbox.png")
LoadImageFromFile("protect_circle", path.."protect_circle.png")
LoadImageFromFile("red_player_mask", path.."red_player_mask.png")
player_class = Class(xobject)
function player_class:init()
    if not CheckRes("img", "player_placeholder") then
        CopyImage('player_placeholder', 'white')
        CopyImage('option_placeholder', 'white')
    end
    self.x, self.y = 0,-175
    self.img = 'player_placeholder'
    --self.omiga = 3
    self.uspeed = 5
    self.fspeed = 2
    self.bound = false
    self.layer = LAYER_PLAYER
    self.slow = 0
    self.slowf = 0
    self.grazer = New(zino_grazer,self)
    self.group = GROUP_PLAYER
    self.protect = 0
    self.nextshoot = 0
    self.nextspell = 0
    self.nextspecial = 0
    self.hyper = 0
    self.dmgratio = 1
    self.shooting = 0
    player = self
    lstg.player = self
    self.deathbombtimer = 30
end
function player_class:colli(other)
    if not self.is_dying and not self.dialog and not cheat and other.playercolli ~= false then
        event:dispatchEvent("onPlayerColli", other)
        if self.protect == 0 and not self.is_dying then
            event:dispatchEvent("onPlayerHit", other)
        end
        if other.group == GROUP_ENEMY_BULLET and self.protect ~= 0 then
            event:dispatchEvent("onPlayerInvulHit", other)
        end
    end
end
event:addListener('onPlayerHit', function()
    local self = player
    self.is_dying = true
    task.New(self, function()
        for i=1, self.deathbombtimer do
            if not self.is_bombing then
                self.is_dying = true
                task.Wait(1)
            else
                self.is_dying = false
                event:dispatchEvent('onPlayerDeathbomb')
                return
            end
        end
        event:dispatchEvent('onPlayerDeath')
        self.is_dying = false
    end, 0, 'PlayerDeathbombCheck')
end)
event:addListener('onPlayerDeath', function()
    item.PlayerMiss()
end,-1,'ItemMiss')

function player_class:frame()
    --if self.pause then return end
    lstg.var.pointrate = item.PointRateFunc(lstg.var)
    player_class.findtarget(self)
    task.Do(self)
    self.class.update_focus(self)
    if not self.is_dying and not self.lock then
        self.class.move(self)
    end
    if not self.dialog then
        self.class.update_var(self)
        self.class.do_input(self)
    end
    self.R = 255-clamp(self.protect/120,0,1)*255
end
function player_class:move()
    local dx, dy = 0,0
    local w = lstg.world
    local speed = self.uspeed
    if self.slow == 1 then
        speed = self.fspeed
    end
    if KeyIsDown('right') then
        dx = dx + 1
    end
    if KeyIsDown('left') then
        dx = dx - 1
    end
    if KeyIsDown('up') then
        dy = dy + 1
    end
    if KeyIsDown('down') then
        dy = dy - 1
    end
    if dx ~= 0 and dy ~= 0 then
        dx = dx * SQRT2_2
        dy = dy * SQRT2_2
    end
    self._dx = dx
    self.x, self.y = clamp(self.x+dx*speed,w.pl,w.pr), clamp(self.y+dy*speed,w.pb,w.pt)
end
function player_class:update_focus()
    self.slow = 0
    if (KeyIsDown('slow') or self.slowlock) and not self.slowoff then
        self.slow = 1
    end
    if self.slow == 0 then
        self.slowf = clamp(self.slowf - 1/6,0,1)
    end
    if self.slow == 1 then
        self.slowf = clamp(self.slowf + 1/6,0,1)
    end
end
function player_class:update_var()
    if self.protect > 0 then
        self.protect = self.protect - 1
    end
    if self.nextshoot > 0 then
        self.nextshoot = self.nextshoot - 1
    end
    if self.nextspell > 0 then
        self.nextspell = self.nextspell - 1
    end
    if self.nextspecial > 0 then
        self.nextspecial = self.nextspecial - 1
    end
    do return end
    if self.hyper == 1 then
        local func = self.class.hyperOff or voidfunc
        func(self)
        for k,v in ipairs(self.options) do
            local func = v.class.onHyperEnd or voidfunc
            func(v)
        end
        for k,v in ipairs(self.hoptions) do
            local func = v.class.onHyperEnd or voidfunc
            func(v)
        end
    end
    if self.hyper > 0 then
        self.hyper = self.hyper - 1
    end
end
function player_class:do_input()
    if KeyIsPressed('special') and self.nextspecial <= 0 then
        self.class.special(self)
    end
    do return end
    self.shooting = 0
    if KeyIsDown('shoot') then
        self.shooting = 1
        self.class.shoot(self)
    end
    if KeyIsPressed('spell') and self.nextspell <= 0 and lstg.var.bomb > 0 then
        local ret = self.class.spell(self)
        if ret == false then
            PlaySound('cancel00',0.5)
        else
            self.is_bombing = true
            task.New(self, function()
                task.Wait(1)
                self.is_bombing = false  end)
            item.PlayerSpell()
        end
    end
end
function player_class:shoot()
    Print('shooting')
    self.nextshoot = 10
end
function player_class:spell()
    Print('bomb')
    self.nextspell = 60
    lstg.var.bomb = lstg.var.bomb - 1
end
function player_class:special()
    Print('special')
    self.nextspecial = 15
end
function player_class:findtarget()
    self.target = nil
    local maxpri = -1
    for i, o in ObjList(GROUP_ENEMY) do
        if o.colli then
            local dx = self.x - o.x
            local dy = self.y - o.y
            local pri = abs(dy) / (abs(dx) + 0.01)
            if pri > maxpri then
                maxpri = pri
                self.target = o
            end
        end
    end
end
function player_class:setActive()
    self.active = true
end
function player_class:setInactive()
    self.active = false
end

player_class.option = Class(object)
function player_class.option:init(player,id)
    self.player = player
    self.id = id
    self.layer = LAYER_PLAYER+1
    self.group = GROUP_GHOST
    self.bound = false
    self.img = player.class.optionimg or 'option_placeholder'
    self.prev_on = false
    self.on = true
    self.omiga = 3
    self._x, self._y = player.x, player.y
end
function player_class.option:frame()
    task.Do(self)
    local player = self.player
    self.class.process_movement(self)
    self.prev_on = self.on
    if self.on and not self.prev_on then
        task.New(self,function() self.class.enter(self) end)
    end
    if not self.on and self.prev_on then
        task.New(self,function() self.class.out(self) end)
    end
end
function player_class.option:process_movement()
    local player = self.player
    local t = 0.4
    self._x = lerp(self._x, player.x, t)
    self._y = lerp(self._y, player.y, t)
    self.offset = player.optionpos[player.slowf][self.id]
    self.x = self._x + self.offset.x
    self.y = self._y + self.offset.y
end
function player_class.option:enter()
    SetFieldInTime(self,20,math.tween.cubicInOut,{'hscale',1}, {'vscale',1})
end
function player_class.option:out()
    SetFieldInTime(self,20,math.tween.cubicInOut,{'hscale',0}, {'vscale',0})
end
function player_class.option:onHyper()
    task.New(self, function()
        SetFieldInTime(self,20,math.tween.cubicInOut,{'hscale',0}, {'vscale',0})
    end)
end
function player_class.option:onHyperEnd()
    task.New(self, function()
        SetFieldInTime(self,20,math.tween.cubicInOut,{'hscale',1}, {'vscale',1})
    end)
end


zino_grazer = Class(object)
function zino_grazer:init(obj)
    self.img = "hitbox_player"
    self.obj = obj
    self.a, self.b = 24,24
    self.bound = false
    self.group = GROUP_PLAYER
    self.layer = LAYER_TOP
    self.f = 0
    self.p = 0
    self.last_ang = 0
end
function zino_grazer:frame()
    self.x, self.y = self.obj.x, self.obj.y
    if self.grazed then
        PlaySound('graze', 0.3, self.x / 200)
        self.grazed = false
    end
    if KeyIsDown("slow") then
        self.f = SnapLerp(self.f,1,0.3)
    else
        self.f = SnapLerp(self.f,0,0.3)
    end
    if self.obj.protect > 5 then
        self.p = SnapLerp(self.p,1,0.1)
    else
        self.p = SnapLerp(self.p,0,0.1)
    end
    local scale = lerp(2,1,self.f)
    self.hscale, self.vscale = scale,scale
    self.A = lerp(0,255,self.f)
    if self.obj.dx ~= 0 or self.obj.dy ~= 0 then
        self.last_ang = Angle(0,0,self.obj.dx,self.obj.dy)
    end
    self.rot = InterpolateAngle(self.rot,self.last_ang,0.05)
end
function zino_grazer:colli(other)
    if other.group ~= GROUP_ENEMY and (not other._graze) then
        item.PlayerGraze()
        self.grazed = true
        other._graze = true
    end
end
function zino_grazer:render()
    DefaultRenderFunc(self)
    local scale = lerp(0,2,self.p)
    local alpha = lerp(0,255,self.p)
    SetImageState("protect_circle", "mul+add", Color(alpha,255,255,255))
    Render("protect_circle", self.x, self.y,self.timer,scale,scale)
end

player_bullet_straight = Class(object)

---@param img string
---@param x number
---@param y number
---@param v number
---@param angle number
---@param dmg number
function player_bullet_straight:init(img, x, y, v, angle, dmg)
    self.group = GROUP_PLAYER_BULLET
    self.layer = LAYER_PLAYER_BULLET
    self.img = img
    self.x = x
    self.y = y
    self.rot = angle
    self.vx = v * cos(angle)
    self.vy = v * sin(angle)
    self.dmg = dmg
    if self.a ~= self.b then
        self.rect = true
    end
end
function player_bullet_straight:frame()
    task.Do(self)
end

player_death_red = Class(object)
function player_death_red:init()
    self.img = "red_player_mask"
    self.color = color.Red
    self.A = 0
    self.layer = LAYER_MENU-200
    self.colli = false
    self.rm = "mul+mul"
    task.New(self,function()
        SetFieldInTime(self,player.deathbombtimer*0.3,math.tween.cubicIn,{"A",255})
        task.Wait(player.deathbombtimer*0.17)
        PlaySound('pldead00',1,self.x/610)
        task.Wait(player.deathbombtimer*0.17)
        SetFieldInTime(self,player.deathbombtimer*0.3,math.tween.cubicOut,{"A", 0})
    end)
end
player_death_red.frame = task.Do
function player_death_red:render()
    SetImageState(self.img,self.rm,self.color)
    RenderRect(self.img,lstg.world.l,lstg.world.r,lstg.world.b,lstg.world.t)
end
local EaseOutCubic = math.tween.cubicOut
player_showlives_death = Class(object)
function player_showlives_death:init()
    self.life_count = lstg.var.lifeleft - 1
    self.lastscale = 1
    self.scale = 0
    self.layer = LAYER_TOP
    task.New(self, function()
        SetFieldInTime(self,15,EaseOutCubic,{'scale', 1})
        task.Wait(30)
        SetFieldInTime(self,15,EaseOutCubic,{'lastscale', 0})
        task.Wait(30)
        SetFieldInTime(self,15,EaseOutCubic,{'scale', 0})
    end)
end
player_showlives_death.frame = task.Do
function player_showlives_death:render()
    local lifescale = 1*self.scale
    local base_ang = 90 * self.scale
    SetImageState("life_bg", "mul+add", Color(150,255,0,0))
    SetImageState("life_fill","",color.White)
    if self.life_count >= 0 then
        local da = 360/(self.life_count+1)
        for i=1, self.life_count do
            local pos = Vector(player.x,player.y) + (Vector.fromAngle(base_ang + i * da) * (64*self.scale))
            Render('life_bg', pos.x ,pos.y,0,lifescale,lifescale)
            Render('life_fill', pos.x ,pos.y,0,lifescale,lifescale)
        end
        local pos = Vector(player.x,player.y) + (Vector.fromAngle(base_ang) * (64*self.scale))
        Render('life_bg', pos.x ,pos.y,0,lifescale,lifescale)
        Render('life_fill', pos.x ,pos.y,0,lifescale * self.lastscale,lifescale * self.lastscale)
    end
end
event:addListener('onPlayerDeath', function()
    local self = player
    misc.ShakeScreen(10, 30)
    New(player_showlives_death)
end,1, 'DeathEffect')
event:addListener('onPlayerHit', function()
    New(player_death_red)
end,1,'HitEffect')
Include(path.."player_team.lua")
Include(path.."bawer_sora/main.lua")