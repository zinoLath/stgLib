haiji_player = zclass(player_class)
local path = GetCurrentScriptDirectory()

local haiji_sheet = LoadTexture("haiji_sheet", path.."haiji_sprite.png")
local haiji_std = LoadImageGroup("haiji_std", "haiji_sheet", 0, 0, 32, 48, 8, 1, 0.5, 0.5, false)
local haiji_left = LoadImageGroup("haiji_left", "haiji_sheet", 0, 48, 32, 48, 8, 1, 0.5, 0.5, false)
local haiji_right = LoadImageGroup("haiji_right", "haiji_sheet", 0, 96, 32, 48, 8, 1, 0.5, 0.5, false)

local haiji_left_anim = side_anim.new(haiji_left,SizedTable(8),5)
local haiji_right_anim = side_anim.new(haiji_right,SizedTable(8),5)
local haiji_std_anim = frame_anim.new(haiji_std, SizedTable(8),5)
local haiji_manager = ZAnim.new(true)
haiji_manager:addAnimation(haiji_left_anim,"left")
haiji_manager:addAnimation(haiji_right_anim,"right")
haiji_manager:addAnimation(haiji_std_anim,"stand")

haiji_player.init = MCDelegate.new()
haiji_player.init:addEvent(player_class.init, "player.init")
haiji_player.init:addEvent(function(self)
    haiji_manager:copy():attachObj(self)
    self.uspeed = 5
    self.fspeed = 2.5
end, "haiji.init")
--haiji_player.init:addEvent(function() error("a")  end, "player.debug")