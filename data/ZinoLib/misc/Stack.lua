stack = setmetatable({}, {
    __call = function()
        local t = {}
        setmetatable(t, stack)
        return t
    end}
)
lstg.stack = stack

function stack.__index(t,k)
    if type(k) == "string" then
        return rawget(stack,k)
    end
    if k <= 0 then
        k = #t + (k)
    end
    return rawget(t,k)
end
function stack:push(...)
    local args = {...}
    for _, v in ipairs(args) do
        table.insert(self,v)
    end
end
function stack:pop(n)
    n = n or 1
    local pops = {}

    for i = 1, n do
        -- get last entry
        if #self ~= 0 then
            table.insert(pops, self[#self])
            -- remove last value
            table.remove(self)
        else
            break
        end
    end
    return unpack(pops)
end
