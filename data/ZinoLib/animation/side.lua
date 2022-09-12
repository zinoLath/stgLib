local M = class()
local function loopTB(tb,id)
    while true do
        if id > #tb then
            id = id - #tb
        else
            break
        end
    end
    return tb[id]
end
local sTypes = {
    NO_LOOP = 0,
    LOOP_BODY = 1,
    LOOP_BODY_OUTRO = 2
}
--- indices can be:
--- a single table:
---     {1,2,3,4,5,6}
--- or a table divided in start, loop and end
---     {{1,2,3},{4,5,6},{3,1,2}}
--- let's say we run both for 2 loops
--- the first will run
---     1,2,3,4,5,6,1,2,3,4,5,6
--- while the second will run
---     1,2,3,4,5,6,4,5,6,3,1,2
--- the numbers basically mean the index of the image inside imgs
--- mmmmaybe allow for real-numbered loops (like, 1.2 loops)
function M:new(imgs,indices,interval)
    self.imgs = imgs --the image list
    self.ids = indices --the indices
    self.interval = interval --frames between each anim
    self.img = imgs[1]
    return self
end
function M.newFromGroup(name,indices,interval)
    local i = 1
    local ret = {}
    while true do
        local img = CheckRes("img", name .. i)
        i = i + 1
        if img then
            ret[i] = img
        else
            break
        end
    end
    return M(ret,indices,interval)
end
--when the animation is given to an object
function M:init(manager,name)
    self.name = name
    self.manager = manager
end
--when an animation starts playing
function M:start(manager,way)
    self.manager.data[self.name] = way
end
--when an animation stops playing
function M:finish()

end
local function lrcheck(mn)
    if mn.lr == 0 then
        return false
    else
        return true
    end
end
--the update coroutine
--ATTENTION: everything that's not the no_loop thing will either look horrible or be buggy as fuck so be warned!
function M:co(manager)
    local is_segmented = sTypes.NO_LOOP
    local way = self.manager.data[self.name]
    local Lmax = manager.side_frame_max
    if type(self.ids[1]) == "table" then
        if type(self.ids[3]) == "table" then
            is_segmented = sTypes.LOOP_BODY_OUTRO
        else
            is_segmented = sTypes.LOOP_BODY
        end
    end
    if is_segmented == sTypes.NO_LOOP then
        while lrcheck(manager) do
            local t = math.clamp((manager.lr*way)/Lmax,0,1)
            self.img = self.imgs[self.ids[int(math.lerp(1,#self.ids),t)]]
            task.Wait(self.interval)
        end
    elseif is_segmented == sTypes.LOOP_BODY then
        local i = 1
        while lrcheck(manager) do
            local t = math.clamp((manager.lr*way)/Lmax,0,1)
            if t~=1 then
                i = 1
                self.img = self.imgs[self.ids[1][int(math.lerp(1,#self.ids[1],t))]]
            else
                self.img = self.imgs[loopTB(self.ids[2],i)]
                i = i + 1
            end
            task.Wait(self.interval)
        end
        --[=[
    else
        local i = 1
        while lrcheck(manager) do
            local t = math.clamp((manager.lr*way)/Lmax,0,1)
            if t~=1 then
                i = 1
                self.img = self.imgs[self.ids[1][int(math.lerp(1,#self.ids[1],t))]]
            else
                self.img = self.imgs[loopTB(self.ids[2],i)]
                i = i + 1
            end
            task.Wait(self.interval)
        end
        --]=]
    end
end
--the render function
function M:render(obj,manager)
    local blend = obj._blend or ""
    local color = obj._color or Color(255,255,255,255)
    SetImageState(self.img,blend,color)
    Render(self.img,obj.x,obj.y,obj.rot,obj.hscale,obj.vscale)
end

return M