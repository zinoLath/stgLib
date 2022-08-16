_author="LuaSTG User"
_mod_version=4096
_allow_practice=true
_allow_sc_practice=true
local path = GetCurrentScriptDirectory()
local str =
[[
Hi! My name is <border color="#00ff00"><shake><state color="#ffff00">Test 1,</state> and I'm shaking!</shake> I don't</border> know what else to say!
]]
hud_font = BMF:loadFont("Philosopher", path .. "font\\philosopher.fnt", path .. "font\\philosopher_0.png")
local hud_font = hud_font
local state = {
	font = hud_font,
	scale = 0.2,
	border_color = Color(255,255,0,0),
	border_size = 2
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
stage.group.New('menu',{},"Normal",{lifeleft=2,power=100,faith=50000,bomb=3},true,1)
stage.group.AddStage('Normal','Stage 1@Normal',{lifeleft=7,power=300,faith=50000,bomb=3},true)
stage.group.DefStageFunc('Stage 1@Normal','init',function(self)
	item.PlayerInit()
    difficulty=self.group.difficulty    --New(mask_fader,'open')
    --New(reimu_player)
	New(DEBUG_BG)
	New(player_class)
	New(test_text)
    task.New(self,function()
        do
            -- New(river_background)
            -- New(MyScene)
			-- New(G2048)
        end
		while true do task.Wait(100) end
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