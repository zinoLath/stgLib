local M = {}
Event = M

M.eventList = {}

function M:new(event,func,name)
    if self.eventList[event] == nil then
        self.eventList[event] = {
            name = event,
            events = {},
        }
    end
    local ret = {
        func = func,
        name = name
    }
    table.insert(self.eventList[event].events,ret)
    return ret
end
function M:call(event,...)
    local ev = self.eventList[event]
    for k,v in pairs(ev.events) do
        v.func(...)
    end
end