ui = Class(object)
local path = GetCurrentScriptDirectory()
LoadImageFromFile("HUD_image",path ..  "HUD.png",false,0,0)
LoadFont("menu",font_path.."menu.fnt")
function ui:init(stage)
    self.bound = false
    self.colli = false
    self.hide = false
    self.stage = stage
    self.group = GROUP_GHOST
    self.layer = LAYER_UI
end
function ui:render()
    SetViewMode 'ui'
    ui.DrawFrame(self)
    if lstg.var.init_player_data then
        ui.DrawScore(self)
    end
    SetViewMode 'world'
end
function ui:kill()
    PreserveObject(self)
end
function ui:del()
    if not self.deleted then
        PreserveObject(self)
    end
end
function ui:DrawFrame()
    RenderRect("HUD_image", screen.dx, screen.width-screen.dx, screen.dy, screen.height-screen.dy)
end
function ui:DrawScore()

end