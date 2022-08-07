local path = GetCurrentScriptDirectory()
LoadImageFromFile("spellnamebg", path.."spellnamebg.png")
local w,h = GetTextureSize('spellnamebg')
local cx, cy = 460, 85
SetImageCenter("spellnamebg",cx,cy)
local cutin_font_default = LoadTTF("cutin_font",path.."Philosopher-Bold.ttf",40)
cutin_font_default:setHAlign(2):setVAlign(1):enableOutline(color.Black,5)
local history_font_default = LoadTTF("history_font",path.."unispace.ttf",25)
history_font_default:setHAlign(2):setVAlign(0):enableOutline(color.Black,2.5)
local timer_font = BMF:loadFont("timer_font",font_path.."chaney_num.fnt",font_path.."chaney_num_0.png")
timer_font:setMonospace(60,{",",".",":"})
local timer_state = BMF:createState("timer_state")
cutin_obj = Class(object)
function cutin_obj:init(card, boss)
    self.spellfont = cutin_font_default
    self.historyfont = history_font_default
    self.name = card.name
    self.namesize = self.spellfont:calcSize(self.name)
    self.bgw = min((lstg.world.pr)*2*2.25 / self.spellfont:calcSize(self.name).x,1)
    self.x = lstg.world.r-16
    self.y1 = -100
    self.y2 = lstg.world.t-32
    self.y = self.y1
    self.alpha = 0
    self.alpha2 = 1
    self.hscale, self.vscale = 2,2
    self.layer = LAYER_UI+50
    self.bound = false
    self.boss = boss
    local cardhistory = scoredata.SpellHistory[card.name]
    self.history_text = string.format("HISTORY: %02d/%02d", cardhistory[3], cardhistory[4])
    task.New(self,function()
        SetFieldInTime(self,45,math.tween.sineOut,{'hscale', 1}, {'vscale', 1}, {'alpha', 1})
        task.Wait(30)
        SetFieldInTime(self,90,math.tween.cubicInOut,{"y",self.y2})
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
    SetImageState("spellnamebg", "", Color(255 * self.alpha * self.alpha2,255,255,255))
    self.spellfont:setColor(Color(255 * self.alpha * self.alpha2,255,255,255))
    self.historyfont:setColor(Color(255 * self.alpha * self.alpha2,255,255,255))
    self.spellfont:setOutlineColor(Color(255 * self.alpha * self.alpha2, 0, 0, 0))
    self.historyfont:setOutlineColor(Color(255 * self.alpha * self.alpha2, 0, 0, 0))

    Render("spellnamebg",self.x,self.y-self.namesize.y/5,0,self.hscale, self.vscale)
    self.spellfont:render(self.name, self.x, self.y, 5, 5, self.hscale*0.4 * self.bgw, self.vscale*0.4)

    local yoff = 15
    self.historyfont:render(string.format("BONUS: %07d", int(self.boss.bonus)),
            self.x-100, self.y-yoff, 5, 5, self.hscale*0.4, self.vscale*0.4)
    self.historyfont:render(self.history_text,
            self.x, self.y-yoff, 5, 5, self.hscale*0.4, self.vscale*0.4)
end
function cutin_obj:kill()
    PreserveObject(self)
    task.Clear(self)
    task.New(self,function()
        SetFieldInTime(self, 30, math.tween.cubicIn, {'alpha', 0}, {'hscale', 0})
    end)
end

circular_hpbar = Class(object)
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
    end
end
function circular_hpbar:render()
    SetViewMode('world')
    SetImageState(self.imgout, self.outrm, Color(self.colorout.a*self.alpha,self.colorout.r,self.colorout.g,self.colorout.b))
    RenderSector(self.imgout,self.x,self.y,-270,-270+360,
            self.radius-self.width/2-self.outline,self.radius+self.width/2+self.outline,self.seg)

    SetImageState(self.imgfill, self.fillrm, Color(self.colorfill.a*self.alpha,self.colorfill.r,self.colorfill.g,self.colorfill.b))
    RenderSector(self.imgfill,self.x,self.y,-270,-270+360*self.fill,
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

boss_timer = Class(object)
function boss_timer:init(boss)
    self.font = timer_font
    self.boss = boss
    self.y1, self.y2 = lstg.world.t+10, lstg.world.t-16
    self.y = self.y1
    self.scale1 = 1
    self.scale2 = self.scale1 * 0.5
    self.bound = false
    self.layer = LAYER_UI+100
    task.New(self, function()
        SetFieldInTime(self,30,math.tween.cubicInOut,{'y',self.y2})
    end)
    self.xoff = 5
end
function boss_timer:frame()
    task.Do(self)
    if Dist(self,player) < 120 then
        self.A = math.lerp(self.A, 64,0.1)
    else
        self.A = math.lerp(self.A, 255,0.1)
    end
end
function boss_timer:render()
    local _a = self.A
    self.A = 255
    timer_state:setColor("u_color",self.color)
    timer_state:setColor("u_gradient",InterpolateColor(self.color,color.Black,0.3))
    self.A = _a
    timer_state:setFloat("u_alpha",self.A/255)
    local t1, t2 = math.modf(self.boss.ui_time or 0)
    self.font:render(':',self.x+3, self.y+5,math.lerp(self.scale1,self.scale2,0.3),"right","bottom",timer_state)
    self.font:render(string.format("%02d", t1),self.x-self.xoff*0.8, self.y,self.scale1,"right","bottom",timer_state)
    self.font:render(string.format("%02d", t2*100),self.x+self.xoff, self.y,self.scale2,"left","bottom",timer_state)
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