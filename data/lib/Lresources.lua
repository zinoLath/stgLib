---=====================================
---luastg resources
---=====================================

----------------------------------------
---脚本载入

lstg.included = {}
lstg.include_value = {}
lstg.current_script_path = { '' }

function Include(filename)
    local ret
    filename = tostring(filename)
    if string.sub(filename, 1, 1) == '~' then
        filename = lstg.current_script_path[#lstg.current_script_path] .. string.sub(filename, 2)
    end
    if not lstg.included[filename] then
        local i, j = string.find(filename, '^.+[\\/]+')
        if i then
            table.insert(lstg.current_script_path, string.sub(filename, i, j))
        else
            table.insert(lstg.current_script_path, '')
        end
        lstg.included[filename] = true
        ret = lstg.DoFile(filename)
        lstg.include_value[filename] = ret
        lstg.current_script_path[#lstg.current_script_path] = nil
    end
    if lstg.include_value[filename] then
        ret = lstg.include_value[filename]
    end
    return ret
end
function lstg.Require(filename)
    filename = tostring(filename)
    filename = filename:gsub("%.", "\\") .. ".lua"
    do lstg.MsgBoxWarn(filename) return end
    return Include(filename)
end
function GetCurrentScriptDirectory()
    return lstg.current_script_path[#lstg.current_script_path]
end


OriginalLoadTexture = LoadTexture
function LoadTexture(tex,...)
    OriginalLoadTexture(tex,...)
    --SetTextureSamplerState(tex,"point+clamp")
    return tex
end
----------------------------------------
---资源载入

ImageList = {}
ImageSize = {}--由OLC添加，用于储存加载的图片的大小
OriginalLoadImage = LoadImage

function LoadImage(img, ...)
    local arg = { ... }
    ImageList[img] = arg
    ImageSize[img] = { arg[4], arg[5] }--由OLC添加，储存加载的图片的大小
    OriginalLoadImage(img, ...)
    return img
end

---由OLC添加，获得加载的图片的大小
function GetImageSize(img)
    return unpack(ImageSize[img])
end

function CopyImage(newname, img)
    if ImageList[img] then
        return LoadImage(newname, unpack(ImageList[img]))
    elseif img then
        error("The image \"" .. img .. "\" can't be copied.")
    else
        error("Wrong argument #2 (expect string get nil)")
    end
end

function LoadImageGroup(prefix, texname, x, y, w, h, cols, rows, a, b, rect)
    local ret = {}
    for i = 0, cols * rows - 1 do
        local img = LoadImage(prefix .. (i + 1), texname, x + w * (i % cols), y + h * (int(i / cols)), w, h, a or 0, b or 0, rect or false)
        table.insert(ret,img)
    end
    return ret
end

function LoadImageFromFile(teximgname, filename, mipmap, a, b, rect)
    LoadTexture(teximgname, filename, mipmap)
    local w, h = GetTextureSize(teximgname)
    return LoadImage(teximgname, teximgname, 0, 0, w, h, a or 0, b or 0, rect)
end

function LoadAniFromFile(texaniname, filename, mipmap, n, m, intv, a, b, rect)
    LoadTexture(texaniname, filename, mipmap)
    local w, h = GetTextureSize(texaniname)
    LoadAnimation(texaniname, texaniname, 0, 0, w / n, h / m, n, m, intv, a, b, rect)
end

function LoadImageGroupFromFile(texaniname, filename, mipmap, n, m, a, b, rect)
    LoadTexture(texaniname, filename, mipmap)
    local w, h = GetTextureSize(texaniname)
    return LoadImageGroup(texaniname, texaniname, 0, 0, w / n, h / m, n, m, a, b, rect)
end

function LoadTTF(ttfname, filename, size)
    lstg.LoadTTF(ttfname, filename, 0, size)
end

----------------------------------------
---资源判断和枚举

ENUM_RES_TYPE = { tex = 1, img = 2, ani = 3, bgm = 4, snd = 5, psi = 6, fnt = 7, ttf = 8, fx = 9 }

function CheckRes(typename, resname)
    local t = ENUM_RES_TYPE[typename]
    if t == nil then
        error('Invalid resource type name.')
    else
        return lstg.CheckRes(t, resname)
    end
end

function EnumRes(typename)
    local t = ENUM_RES_TYPE[typename]
    if t == nil then
        error('Invalid resource type name.')
    else
        return lstg.EnumRes(t)
    end
end

function FileExist(filename)
    return lstg.FileManager.FileExist(filename, true)
end
