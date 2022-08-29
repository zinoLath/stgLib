--shotdata reader lol
local M = {}
local _path = GetCurrentScriptDirectory()
M.default_path = _path .. "shotdata.json"

function M.evalrect(string)
    return loadstring('return function(M) return M.rect(' .. string .. ') end')()(M)
end
function M.loadstr(string)
    return loadstring('return function(M) ' .. string .. ' end')()(M)
end
function M.rect(l,t,r,b)
    if not tonumber(l) then
        return l, t, r, b
    end
    return {l = tonumber(l), t = tonumber(t), r = tonumber(r), b = tonumber(b)}
end
function M.rectXY(x,y,w,h)
    return M.rect(tonumber(x), tonumber(y), tonumber(x) + tonumber(w), tonumber(y) + tonumber(h))
end

function M.parse(string, path, ret)
    ret = ret or {textures = {}, shots = {}}
    if path then
        string = cc.FileUtils:getInstance():getStringFromFile(path)
    end
    string = string or LoadTextFile(M.default_path)
    local json = DeSerialize(string)
    if json.load then
        M.loadstr(json.load)
    end
    for k,v in pairs(json.images) do
        local tex
        tex = LoadTexture(k,_path .. v)
        if lstg.FileManager.FileExist(_path .. v) then
            tex = LoadTexture(k,_path .. v)
        else
            tex = LoadTexture(k,v)
        end
        tex = k
        ret.textures[k] = tex
    end
    for k,v in pairs(json.shots) do
        ret.shots[k] = {tex = ret.textures[v.tex] or ret.textures[json.default_img]}
        local rect = M.evalrect(v.rect)
        Print(rect)
        local res = LoadImage("SHOT_DATA:" .. k,ret.shots[k].tex,
                rect.l, rect.t, rect.r-rect.l, rect.b-rect.t,v.hitsize,v.hitsize,false)
        ret.shots[k].res = res
        if v.center then
            SetImageCenter(res, eval(v.center))
        end
        if v.size then
            SetImageScale(res, v.size/json.default_size)
        end
        for _k,_v in pairs(v) do
            ret.shots[k][_k] = ret.shots[k][_k] or _v
        end
    end
    return ret
end
function M.optimize_sheet(tb)
    for k,v in pairs(tb.shots) do
        v[1], v[2], v[3] = v.res, v.hitsize, v.default_size
    end
end

return M