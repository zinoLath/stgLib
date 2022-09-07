local M = zclass(MenuSys.menu)
M.option = zclass(MenuSys.option)
M.key_events = deepcopy(M.key_events)
function M.key_events:menu()
    if self.timer > 1 then
        CallClass(self.manager,"go_back")
    end
end
function M:init(manager)
    local tb =  {
        { "Resume", "resume" },
        { "Return to Title", "quit" },
        { "Restart", "restart" }
    }
    self.option_def = {}
    for k,v in ipairs(tb) do
        self.option_def[k] = {M.option, v[1], function( )  pause_menu.executeEvent(self,v[2]) end}
    end
    MenuSys.menu.init(self,manager)
    for k,v in pairs(self.option_def) do
        self.options[k].onEnter = v[3]
    end
end
function M:ctor()

end
return M