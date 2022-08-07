local M = {}
local meta = {}

function M:call(...)
    local ret = {}
    for k,v in ipairs(self._events) do
        local mret = v(...)
        if mret ~= nil then
            table.insert(ret,mret)
        end
    end
    return unpack(ret)
end
function M:addEvent(func, tag)
    table.insert(self._events, func)
    self._map[tag] = #self._events
    return self
end
function M:removeEvent(tag)
    table.remove(self._events,self._map[tag])
    return self
end
meta.__call = M.call
meta.__index = M
function M.new()
    local del = setmetatable({}, meta)
    del._events = {}
    del._map = {}
    return del
end

MCDelegate = M
return M