--- WARNING! DEPRECATED IN FAVOR OF lstg.Mesh
---
--- Ok so the idea of this is to basically serve as a handler for dnh-like multivertex stuff.
--- It's a makeshift triangle handler because the actual triangle handler doesn't work the way i need
--- it's actually also rather performant compared to the standard use of rendertextures, since there's no per-frame
--- table creation which is quite expensive.
---
--- the data structure is like, a vertex table that contains all the vertexes, and an indice field,
--- that contains all the indices also its quads only
--- REMINDER: X Y Z U V COLOR
local M = {}
ZQuads = M
local mt = {}

function M.new(vcount,icount)
    local ret = setmetatable({ vertex = {}, index = {}}, mt)
    return ret:setVertexCount(vcount):setIndexCount(icount)
end
function M:setVertexCount(num)
    for i=1, num do
        self.vertex[i] = self.vertex[i] or {0,0,0,0,0,color.White}
    end
    return self
end
function M:setIndexCount(num)
    for i=1, num do
        self.index[i] = self.index[i] or {}
    end
    return self
end

function M:setVertexPosition(id,pos)
    self.vertex[id][1] = pos.x
    self.vertex[id][2] = pos.y
    return self
end
function M:setVertexPosition3D(id,pos)
    self.vertex[id][1] = pos.x
    self.vertex[id][2] = pos.y
    self.vertex[id][3] = pos.z
    return self
end
function M:setVertexUV(id,uv)
    self.vertex[id][4] = uv.x
    self.vertex[id][5] = uv.y
    return self
end
function M:setVertexColor(id,color)
    self.vertex[id][6] = color
    return self
end
function M:setIndex(id,i)
    self.index[id] = i
    return self
end
function M:setIndexFromTable(tb)
    for k,v in pairs(tb) do
        self.index[k] = tb[v]
    end
    return self
end
function M:render(texture, blend)
    local sind = self.index
    local sver = self.vertex
    for i=1, int(#sind/4)*4,4 do
        RenderTexture(texture,blend,sver[sind[i]],sver[sind[i+1]],sver[sind[i+2]],sver[sind[i+3]])
    end
    return self
end

mt.__index = M
mt.__call = M.new
return M