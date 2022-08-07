zparticle = {}
local M = zparticle
local ffi = require "ffi"
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
    int rmPtr;
    double extra1;
    double extra2;
    double extra3;
} zparticle;]]
M.initList = {}
M.frameList = {}
M.delList = {}
M.imgList = {}
M.rmList = {}
M.spawner = { }
function M.spawner:new()
    self = deepcopy(M.spawner)
    self.plist = {}
    return self
end
function M.spawner:frame()
    task.Do(self)
    for k,v in ipairs(self.plist) do
        M.frameList[v.framePtr](v,k)
    end
end
function M.spawner:render()
    for k,v in ipairs(self.plist) do
        SetImageState(M.imgList[v.imgPtr], M.rmList[v.rmList], v.color)
        Render(M.imgList[v.imgPtr],v.x,v.y,v.rot,v.sx,v.sy)
    end
end
function M.spawner:del()

end