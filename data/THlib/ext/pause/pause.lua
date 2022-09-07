local path = GetCurrentScriptDirectory()
local MenuSys = MenuSys
local M = {}
M.manager = zclass(MenuSys.manager)
M.manager.name = "PauseManager"
M.manager.intro_menu = "main"

local submenu_path = path.."submenu/"
local main = Include(submenu_path.."main.lua")
M.manager.menus = {
    {main, "main"}
}

function M.manager:init(opt_list)
    lstg.is_paused = true
    MenuSys.manager.init(self)
end
function M.manager:exit()
    task.New(self, function()
        local menu = self.stack[0]
        local menu_opts = menu.options
        CallClass(self,"kill")
        while true do
            local is_dead = false
            for k,v in ipairs(menu_opts) do
                is_dead = is_dead or v.status ~= "normal"
            end
            if is_dead then
                break
            end
            task.Wait(1)
        end
        RawKill(self)
        lstg.is_paused = false
    end)
end

Event:new("onStgFrame",function()
    if SysKeyIsPressed("menu") and not IsValid(lstg.tmpvar.pausemenu) then
        lstg.tmpvar.pausemenu = New(M.manager)
    end
end,"pauseGame")