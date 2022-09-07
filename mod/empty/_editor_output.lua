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
	self.pmanager = zparticle:new("white_part",nil,nil,nil,nil,90000)
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
--[[

		task.Wait(120)
		task.New(self, function()
			while (true) do
				local base_ang = ran:Float(0,360)
				AdvancedFor(10,
						{"linear", base_ang-180, base_ang+180, false},
				function(ang)
					local last = New(straight,"star", color.Blue, Color(255,200,200,255), self.x, self.y, ang, 0.5, 1, "grad+alpha", 10)
					--last.layer = LAYER_ENEMY_BULLET + 5
					local last = New(straight,"star", color.Red, Color(255,255,200,200), self.x, self.y, ang+180/10, 0.45, -1, "grad+alpha", 10)
					--last.layer = LAYER_ENEMY_BULLET + 5
				end)
				task.Wait(120)
			end
		end)
		while(true) do
			local baseang = self.timer*0.5
			AdvancedFor(3,{"linear",baseang,baseang+360,false},
					function(_ang)
						local fanang = 10 + sin(5*self.timer) * 10
						AdvancedFor(13,
								{"linear", _ang-fanang, _ang+fanang,true},
								{"zigzag", 0.75, 15, 1, true},
								function(finalang, spd)
									New(straight,"ellipse", color.Red, color.White, self.x, self.y, finalang, spd, 0, "grad+alpha",15)
								end
						)
					end
			)
			task.Wait(5)
		end
--]]
--[[

		player.protect = 9999999
		while true do
			local range = 10 + 4 * sin(self.timer*0.5)
			local safe_ang = 270 + 30 * sin(self.timer)
			AdvancedFor(25,
					{"linear",0,360,false},
					function(ang)
						local off = sin(self.timer*2)*90

						local final_rot = ang + off
						local adiff = AngleDifference(final_rot,safe_ang)
						if not (adiff < range and adiff > -range) then
							New(straight,"square", Color(255,64,0,0), color.White, self.x, self.y, final_rot, 5, 6, "grad+add", 15)
						end
						local final_rot = ang - off*0.25
						local adiff = AngleDifference(final_rot,safe_ang)
						if not (adiff < range and adiff > -range) then
							New(straight,"square", Color(255,64,0,0), color.White, self.x, self.y, final_rot, 5, -6, "grad+add", 15)
						end
					end
			)
			New(straight,"square", Color(255,64,0,0), color.White, self.x, self.y, safe_ang + range, 5, -6, "grad+add", 15)
			New(straight,"square", Color(255,64,0,0), color.White, self.x, self.y, safe_ang - range, 5, -6, "grad+add", 15)
			task.Wait(2)
			end
--]]
local center = Vector(0,100)
local sc = boss.card:new("gtest", 60, 2, 2, 600, false)
function sc:before()
	self.x = lstg.world.pr + 64
	self.y = lstg.world.pt + 64
	SetFieldInTime(self,30,math.tween.quadOut,{"x",center.x}, {"y",center.y})
end
function sc:init()
	task.New(self, function()
		task.Wait(60)
		self.bulcolor = Color(255,255,0,0)
		self._dispang = -self.timer*0.5
		self._dispstr = 0
		do return end
		task.New(self,function()
			local time1 = 30
			local time2 = 90
			while(true) do
				for i=1,time1 do
					local t = i/time1
					self.bulcolor = InterpolateColor(Color(255,255,0,0),Color(255,0,255,0),t)
					task.Wait(1)
				end
				task.Wait(time2)
				for i=1,time1 do
					local t = i/time1
					self.bulcolor = InterpolateColor(Color(255,0,255,0),Color(255,0,0,255),t)
					task.Wait(1)
				end
				task.Wait(time2)
				for i=1,time1 do
					local t = i/time1
					self.bulcolor = InterpolateColor(Color(255,0,0,255),Color(255,255,0,0),t)
					task.Wait(1)
				end
				task.Wait(time2)
			end
		end)
		task.New(self,function()
			while(true) do
				AdvancedFor(5, {"linear",0,360,false},
						function(angle)
							local ret = CreateShotA(self.x,self.y,2,self.timer*5.4332+angle,"scale",self.bulcolor,
									InterpolateColor(self.bulcolor,color.White,0.9),"grad+add",20)
						end
				)
				task.Wait(5)
			end
		end)
		task.New(self, function()
			task.Wait(180)
			while(true) do
				AdvancedFor(3,{"linear",1.75,2},
						function(speed)
							AdvancedFor(60,{"linear",0,360,false},
									function(angle)
										local ret = CreateShotA(self.x,self.y,speed,self.timer*3+angle,"circle_border",self.bulcolor,
												InterpolateColor(self.bulcolor,color.White,0.9),"grad+add",15)
										ret.layer = LAYER_ENEMY_BULLET + 10
									end
							)
						end
				)
				task.Wait(60)
			end
		end)
		task.New(self,function()
			while(true) do
				local dispvec = Vector.fromAngle(180+self._dispang) * self._dispstr
				for i, o in ObjList(GROUP_ENEMY_BULLET) do
					o.x = o.x + dispvec.x
					o.y = o.y + dispvec.y
				end
				task.Wait(1)
			end
		end)
		task.New(self,function()
			task.Wait(60)
			for i=1,_infinite do
				local t = math.tween.cubicOut(math.min(i/(60*20),1))
				self._dispstr = t
				self._dispang = -self.timer*0.5
				self.x = center.x + 100 * t * cos(self._dispang)
				self.y = center.y + 50 * t * sin(self._dispang)
				task.Wait(1)
			end
		end)
	end)
end
sc.cutin_img = LoadImageFromFile("nicki_cutin",path.."cutin.png")
SetImageScale("nicki_cutin",1.2)
table.insert(test_boss.patterns, sc)
stage.group.New('menu',{},"Normal",{lifeleft=2,power=100,faith=50000,bomb=3},true,1)
stage.group.AddStage('Normal','Stage 1@Normal',{lifeleft=7,power=300,faith=50000,bomb=3},true)
stage.group.DefStageFunc('Stage 1@Normal','init',function(self)
	item.PlayerInit()
    difficulty=self.group.difficulty    --New(mask_fader,'open')
    --New(reimu_player)
	New(DEBUG_BG)
	New(haiji_player)
    task.New(self,function()
        do
            -- New(river_background)
            -- New(MyScene)
			-- New(G2048)
        end
		task.Wait(120)
		New(test_boss, test_boss.patterns)
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