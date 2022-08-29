--TODO: PORT TO BMFONT ONLY

local path = GetCurrentScriptDirectory()
LoadImageFromFile("spellnamebg", path.."spellnamebg.png")
local w,h = GetTextureSize('spellnamebg')
local cx, cy = 460, 85
SetImageCenter("spellnamebg",cx,cy)
local cutin_font_default = BMF:loadFont("philosopher",font_path)
local history_font_default = BMF:loadFont("square",font_path)
local timer_font = BMF:loadFont("chaney",font_path)
timer_font:setMonospace(80,{",",".",":"})
--local timer_state = BMF:createState("timer_state")
local namestate = {
    font = cutin_font_default,
    scale = 0.3,
    border_color = Color(255,0,0,0),
    border_size = 3,
    color_top = Color(255,255,255,255),
    color_bot = Color(255,200,200,200)
}
local historystate = {
    font = history_font_default,
    scale = 0.15,
    border_color = Color(255,0,0,0),
    border_size = 3,
    color_top = Color(255,255,255,255),
    color_bot = Color(255,200,200,200)
}
cutin_obj = zclass(object)
function cutin_obj:init(card, boss)
    self.spellfont = cutin_font_default
    self.historyfont = history_font_default
    self.name = card.name
    self.x = lstg.world.pr-16
    self.y1 = lstg.world.pt+32
    self.y2 = lstg.world.pt-32
    self.y = self.y1
    self.alpha = 0
    self.alpha2 = 1
    self.hscale, self.vscale = 1,1
    self.layer = LAYER_UI+50
    self.bound = false
    self.boss = boss
    local cardhistory = scoredata.SpellHistory[card.name]
    self.namestate = softcopy(namestate)
    self.historystate = softcopy(historystate)
    self.namepool = BMF:pool(self.name,self.namestate,99999)
    self.namepoolw = BMF:getPoolWidth(self.namepool)
    self.history_text = string.format("HISTORY: %02d/%02d", cardhistory[3], cardhistory[4])
    self.historypool = BMF:pool(self.history_text,self.historystate,99999)
    self.historypoolw = BMF:getPoolWidth(self.historypool)
    task.New(self,function()
        --SetFieldInTime(self,45,math.tween.sineOut,{'hscale', 1}, {'vscale', 1}, {'alpha', 1})
        --task.Wait(30)
        SetFieldInTime(self,120,math.tween.cubicInOut,{"y",self.y2}, {'alpha', 1})
    end)
end
function cutin_obj:frame()
    task.Do(self)
    if player.y > 100 then
        self.alpha2 = math.lerp(self.alpha2,0.2,0.2)
    else
        self.alpha2 = math.lerp(self.alpha2,1,0.2)
    end
end
function cutin_obj:render()
    local alpha = 255 * self.alpha * self.alpha2
    self.namepool.stateList[1].color_top = Color(255 * self.alpha * self.alpha2,255,255,255)
    self.namepool.stateList[1].color_bot = Color(255 * self.alpha * self.alpha2,200,200,200)
    self.namepool.stateList[1].border_color = Color(255 * self.alpha * self.alpha2,0,0,0)
    self.historypool.stateList[1].color_top = Color(255 * self.alpha * self.alpha2,255,255,255)
    self.historypool.stateList[1].color_bot = Color(255 * self.alpha * self.alpha2,200,200,200)
    self.historypool.stateList[1].border_color = Color(255 * self.alpha * self.alpha2,0,0,0)
    SetImageState("spellnamebg", "", Color(255 * self.alpha * self.alpha2,255,255,255))
    Render("spellnamebg",self.x,self.y-10,0,self.hscale, self.vscale)
    BMF:renderPool(self.namepool,self.x-self.namepoolw,self.y+4,self.hscale,nil,self.timer,2.25)
    BMF:renderPool(self.historypool,self.x-self.historypoolw,self.y-15,self.hscale,nil,self.timer,2.25)
end
function cutin_obj:kill()
    PreserveObject(self)
    task.Clear(self)
    task.New(self,function()
        SetFieldInTime(self, 30, math.tween.cubicIn, {'alpha', 0}, {'hscale', 0})
    end)
end

circular_hpbar = zclass(object)
CopyImage("hpbar_fill", "white")
CopyImage("hpbar_bg", "white")
function circular_hpbar:init(anchor,radius,width,outline,colorout,colorfill)
    radius,width,outline,colorout,colorfill =
    radius or 64, width or 4, outline or 2, colorout or color.Red,colorfill or color.White
    self.anchor = anchor
    self.radius = radius
    self.width = 0
    self.outline = 0
    self.__w = width
    self.__o = outline
    self.fill = 1
    self.colorout = colorout
    self.colorfill = colorfill
    self.imgfill = "hpbar_fill"
    self.imgout = "hpbar_bg"
    self.outrm = ""
    self.fillrm = ""
    self.seg = 128
    self.bound = false
    self.layer = LAYER_UI
    self.alpha = 1
end
function circular_hpbar:frame()
    task.Do(self)
    local anchor = self.anchor
    if not IsValid(anchor) then return end
    if anchor.colli and not self.dying then
        self.width = SnapLerp(self.width,self.__w,0.1)
        self.outline = SnapLerp(self.outline,self.__o,0.1)
    elseif not anchor.colli and not self.dying then
        self.width = SnapLerp(self.width,0,0.2)
        self.outline = SnapLerp(self.outline,0,0.2)
    end
    self.x, self.y = anchor.x, anchor.y
    if Dist(anchor,player) < self.radius*1.5 then
        self.alpha = SnapLerp(self.alpha,0.2,0.1)
    else
        self.alpha = SnapLerp(self.alpha,1,0.1)
    end
    if anchor.hp and anchor.maxhp then
        self.fill = SnapLerp(self.fill,anchor.hp/anchor.maxhp,0.3)
    else
        self.fill = 1
    end
end
function circular_hpbar:render()
    SetViewMode('world')
    SetImageState(self.imgout, self.outrm, Color(self.colorout.a*self.alpha,self.colorout.r,self.colorout.g,self.colorout.b))
    misc.RenderRing(self.imgout,self.x,self.y,-270,-270+360,
            self.radius-self.width/2-self.outline,self.radius+self.width/2+self.outline,self.seg)

    SetImageState(self.imgfill, self.fillrm, Color(self.colorfill.a*self.alpha,self.colorfill.r,self.colorfill.g,self.colorfill.b))
    misc.RenderRing(self.imgfill,self.x,self.y,-270,-270+360*self.fill,
            self.radius-self.width/2,self.radius+self.width/2,self.seg)
end
function circular_hpbar:kill()
    PreserveObject(self)
    self.dying = true
    task.New(self,function()
        SetFieldInTime(self,15,math.tween.cubicInOut,{'width', 0}, {'outline', 0})
        Del(self)
    end)
end

boss_timer = zclass(object)
function boss_timer:init(boss)
    self.font = timer_font
    self.boss = boss
    self.y1, self.y2 = screen.height, screen.height-100
    self.y = self.y1
    self.x = screen.width/2 - 320
    self.scale1 = 0.7
    self.scale2 = self.scale1 * 0.4
    self.bound = false
    self.layer = LAYER_UI+100
    self._a = 0
    task.New(self, function()
        SetFieldInTime(self,60,math.tween.quadOut,{'y',self.y2}, {"_a", 255})
    end)
    self.xoff = 3
end
function boss_timer:frame()
    task.Do(self)
    do return end
    if Dist(self,player) < 120 then
        self._a = math.lerp(self._a, 64,0.1)
    else
        self._a = math.lerp(self._a, 255,0.1)
    end
end
function boss_timer:render()
    SetViewMode("ui")
    local t1, t2 = math.modf(self.boss.ui_time or 0)
    self.font:renderOutline(string.format("%02d", t2*100),
            self.x+self.xoff, self.y+30,self.scale2,"left","vcenter", Color(self._a,255,255,255),nil,6,Color(255,0,0,0))
    self.font:renderOutline(string.format("%02d", t1),
            self.x-self.xoff, self.y,self.scale1,"right","vcenter", Color(self._a,255,255,255),nil,6,Color(255,0,0,0))
    SetViewMode("world")
end
function boss_timer:kill()
    PreserveObject(self)
    task.Clear(self)
    task.New(self, function()
        task.New(self, function()
            SetFieldInTime(self,30,math.tween.cubicInOut,{'y',self.y1})
        end)
    end)
end