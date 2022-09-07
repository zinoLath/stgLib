zparticle = {}
local M = zparticle
local ffi = require "ffi"
M._mt = {
    __index = M
}
ffi.cdef[[
typedef struct {
    double x;
    double y;
    double rot;
    double vx;
    double vy;
    double sx;
    double sy;
    int color;
    int timer;
    int initPtr;
    int framePtr;
    int delPtr;
    int imgPtr;
    int blendPtr;
    double extra1;
    double extra2;
    double extra3;
    bool active;
} zparticle;]]
function M:new(img,blend,onInit,onFrame,onDel,poolsize)
    local ret = {}
    poolsize = poolsize or 512
    ret.initList = {onInit or voidfunc}
    ret.frameList = {onFrame or voidfunc}
    ret.delList = {onDel or voidfunc}
    ret.imgList = {img or "white"}
    ret.blendList = {blend or ""}
    ret.plist = ffi.new("zparticle[?]", poolsize)
    ret.current_pool_id = 1
    for i=1, poolsize do
        ret.plist[i] = ffi.new("zparticle",0,0,0,0,0,0,0,0,0,1,1,1,1,1,0,0,0,false)
    end
    ret.poolsize = poolsize
    setmetatable(ret, M._mt)
    return ret
end
function M:newParticle(x,y,rot,vx,vy,sx,sy,color,init,frame,del,img,blend,extra1,extra2,extra3)
    local particle = self.plist[self.current_pool_id]
    particle.x = x or 0
    particle.y = y or 0
    particle.rot = rot or 0
    particle.vx = vx or 0
    particle.vy = vy or 0
    particle.sx = sx or 1
    particle.sy = sy or 1
    particle.color = color or 0
    particle.timer = 0
    particle.initPtr = init or 1
    particle.framePtr = frame or 1
    particle.delPtr = del or 1
    particle.imgPtr = img or 1
    particle.blendPtr = blend or 1
    particle.extra1 = extra1 or 0
    particle.extra2 = extra2 or 0
    particle.extra3 = extra3 or 0
    particle.active = true
    self.frameList[particle.initPtr](self,particle)
    self.current_pool_id = (self.current_pool_id) % (self.poolsize-1) + 1
end
function M:update()
    for i = 0, self.poolsize - 1 do
        if self.plist[i].active then
            self.frameList[self.plist[i].framePtr](self,self.plist[i])
            self.plist[i].x = self.plist[i].x + self.plist[i].vx
            self.plist[i].y = self.plist[i].y + self.plist[i].vy
            self.plist[i].timer = self.plist[i].timer + 1
        end
    end
end
function M:render()
    for i = 0, self.poolsize - 1 do
        if self.plist[i].active then
            -- local img = self.imgList[self.plist[i].imgPtr]
            -- SetImageState(img, self.blendList[v.blendPtr], v.color)
            lstg.Render("white", self.plist[i].x, self.plist[i].y, self.plist[i].rot, self.plist[i].sx, self.plist[i].sy)
        end
    end
end

return M