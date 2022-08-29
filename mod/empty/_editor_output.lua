_author="LuaSTG User"
_mod_version=4096
_allow_practice=true
_allow_sc_practice=true
local path = GetCurrentScriptDirectory()
local str =
[[
Hi! My name is Test 1, and I'm shaking! I don't know what else to say!
]]
hud_font = BMF:loadFont("philosopher", font_path)
local hud_font = hud_font
local state = {
	font = hud_font,
	scale = 0.2,
	border_color = Color(255,255,0,0),
	border_size = 3
}
local pool = BMF:pool(str,state,300)
test_text = Class(object)
test_text.render = {}
test_text.render[1] = function (self)
	SetViewMode("world")
	BMF:renderPool(pool,self.x-180,self.y,1,nil,self.timer,screen.scalefrom480)
end
test_text.render[2] = function (self)
	SetViewMode("world")
	BMF:renderPool(pool,self.x-180,self.y+40,0.2,nil,self.timer,screen.scalefrom480)
end
CopyImage("white_part", "white")
SetImageState("white_part","",Color(255,255,255,255))
test_particle = zclass(object)
function test_particle:init()
	self.layer = LAYER_TOP
	self.pmanager = zparticle:new("white_part",nil,nil,nil,nil,70000)
end
function test_particle:frame()
	local x,y = player.x, player.y
	for i=0, 360, 360/6000 do
		self.pmanager:newParticle(x,y,-self.timer,cos(self.timer*3+i)*10,sin(self.timer*3+i)*10)
	end
	self.pmanager:update()
end
function test_particle:render()
	--SetViewMode("ui")
	self.pmanager:render()
	--SetViewMode("world")
end

test_boss = zclass(boss)
function test_boss:init(cards)
	boss.init(self,cards)
	self.x = lstg.world.r + 100
	self.y = lstg.world.t + 200
end
local sc = boss.card:new("gtest", 60, 2, 2, 600, false)
function sc:init()
	task.New(self, function()
		--task.MoveTo(self,0,100,60,MOVE_ACC_DEC)
		self.x = 0
		self.y = 100
		while true do
			local last = New(straight,"arrow", Color(255,255,0,0), Color(255,255,200,200), self.x, self.y, self.timer*10, 3, 0, "grad+alpha", 7, false)
			task.Wait(1)
		end
	end)
end
table.insert(test_boss.patterns, sc)
stage.group.New('menu',{},"Normal",{lifeleft=2,power=100,faith=50000,bomb=3},true,1)
stage.group.AddStage('Normal','Stage 1@Normal',{lifeleft=7,power=300,faith=50000,bomb=3},true)
stage.group.DefStageFunc('Stage 1@Normal','init',function(self)
	item.PlayerInit()
    difficulty=self.group.difficulty    --New(mask_fader,'open')
    --New(reimu_player)
	New(DEBUG_BG)
	New(test_particle)
	New(haiji_player)
    task.New(self,function()
        do
            -- New(river_background)
            -- New(MyScene)
			-- New(G2048)
        end
		--New(test_boss, test_boss.patterns)
		while true do
			task.Wait(1)
		end
    end)

    task.New(self,function()
		while coroutine.status(self.task[1])~='dead' do task.Wait() end
		stage.group.FinishReplay()
		New(mask_fader,'close')
		task.New(self,function()
			local _,bgm=EnumRes('bgm')
			for i=1,30 do 
				for _,v in pairs(bgm) do
					if GetMusicState(v)=='playing' then
					SetBGMVolume(v,1-i/30) end
				end
				task.Wait()
		end end)
		task.Wait(30)
		stage.group.FinishStage()
	end)
end)

--do return end
stage_init = stage.New('init', true, true)
function stage_init:init()
	stage.group.Start(stage.groups["Normal"])
end