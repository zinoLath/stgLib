haiji_player = zclass(player_class)
local path = GetCurrentScriptDirectory()

local haiji_sheet = LoadTexture("haiji_sheet", path.."haiji_sprite.png")
local haiji_std = LoadImageGroup("haiji_std", "haiji_sheet", 0, 0, 32, 48, 8, 1, 0.5, 0.5, false)
local haiji_left = LoadImageGroup("haiji_left", "haiji_sheet", 0, 48, 32, 48, 8, 1, 0.5, 0.5, false)
local haiji_right = LoadImageGroup("haiji_right", "haiji_sheet", 0, 96, 32, 48, 8, 1, 0.5, 0.5, false)

local haiji_left_anim = side_anim(haiji_left,SizedTable(8),5)
local haiji_right_anim = side_anim(haiji_right,{{1,2,3,4,5},{6,7,8},{4,2}},5)
local haiji_std_anim = frame_anim(haiji_std, SizedTable(8),5)
local haiji_manager = ZAnim(true)
Print(tostring(haiji_manager.addAnimation))
haiji_manager:addAnimation(haiji_left_anim,"left")
haiji_manager:addAnimation(haiji_right_anim,"right")
haiji_manager:addAnimation(haiji_std_anim,"stand")

haiji_player.init = MCDelegate.new()
haiji_player.init:addEvent(player_class.init, "player.init")
haiji_player.init:addEvent(function(self)
    haiji_manager:attachObj(self)
    self.uspeed = 4
    self.fspeed = 2
end, "haiji.init")
--haiji_player.init:addEvent(function() error("a")  end, "player.debug")