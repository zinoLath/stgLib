local M = {}
local meta = {}

function M:call(...)
    local isret = self.isret
    local ret
    if isret then
        ret = {}
    end
    for k,v in ipairs(self._events) do
        local mret = v(...)
        if isret and mret ~= nil then
            table.insert(ret,mret)
        end
    end
    if isret then
        return unpack(ret)
    end
end
function M:tofunc()
    return function(...)
        self:call(...)
    end
end
function M:addEvent(func, tag)
    table.insert(self._events, func)
    self._map[tag] = #self._events
    return self
end
function M:removeEvent(tag)
    table.remove(self._events,self._map[tag])
    self._map[tag] = nil
    return self
end
meta.__call = M.call
meta.__index = M
function M.new()
    local del = setmetatable({}, meta)
    del._events = {}
    del._map = {}
    del.isret = true
    return del
end

MCDelegate = M
return M