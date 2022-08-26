ui = {}
local path = GetCurrentScriptDirectory()
LoadImageFromFile("HUD_image",path ..  "HUD.png",false,0,0)
function ui:DrawFrame()
    RenderRect("HUD_image", screen.dx, screen.width-screen.dx, screen.dy, screen.height-screen.dy)
end
function ui:DrawScore()

end