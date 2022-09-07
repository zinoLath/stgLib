---BMF LuaSTG System by Zino Lath v0.01a
local M = {}
BMF = M
local ffi = require "ffi"
ffi.cdef[[
typedef struct {
    int id;
    int _char;
    int state;
    double x;
    double y;
} zfontrender;
]]
local GCSD = GetCurrentScriptDirectory()
local bytetofloat = 1/255
M.states = {}
M.fonts = {}
M.charlist = {
    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', ' ', '!', '"', '#', '$',
    '%', '&', "'", '(', ')', '*', '+', ',', '-', '.', '/', ':', ';', '<', '=',
    '>', '?', '@', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L',
    'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', '[',
    '\\',']', '^', '_', '`', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j',
    'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y',
    'z', '{', '|', '}', '~'
}
local ctdefault = Color(255,255,255,255)
local cbdefault = Color(255,255,255,255)
CreateRenderTarget("BMF_FONT_BUFFER")
CreateRenderTarget("BMF_FONT_BORDER")
LoadFX("BMF_BORDER_SHADER", GCSD .. "shader.fx")
LoadFX("BMF_EMPTY_SHADER", GCSD .. "empty.fx")

for k,v in ipairs(M.charlist) do
    M.charlist[v] = k
end
--
M.font_functions = {}
function M:loadFont(name,path)
    --local data = xml:ParseXmlText(FU:getStringFromFile(path))
    local handler = xml2lua.dom:new()
    local parser = xml2lua.parser(handler)
    parser:parse(LoadTextFile(path .. name .. ".fnt"))
    local data = handler.root
    Print("BMFFONT LOADED: "..name)
    local tex_name = "bmftexture:" .. name
    local textures = {}
    for k,_v in pairs(data._children[3]._children) do
        local v = _v._attr
        textures[v.id] = LoadTexture(tex_name .. v.id, path .. v.file)
    end
    local ret = {}
    local chars = {}
    local function getValueN(tb, id)
        return tonumber(tb[string.sub(id,2)])
    end
    for k,_v in pairs(data._children[4]._children) do
        local v = _v._attr
        chars[string.char(getValueN(v, '@id'))] = {
            id = (getValueN(v, '@id')),
            x = getValueN(v, '@x'), y = getValueN(v, '@y'),
            width = getValueN(v, '@width'), height = getValueN(v, '@height'),
            xoffset = getValueN(v, '@xoffset'), yoffset = getValueN(v, '@yoffset'),
            xadvance = getValueN(v, '@xadvance'),
            sprite_name = name .. v['id']
        }
        local curchr = chars[string.char(getValueN(v, '@id'))]
        curchr.sprite =
        LoadImage(name .. v['id'], textures[v.page], curchr.x,curchr.y,curchr.width, curchr.height,0,0,false)
        if M.charlist[string.char(getValueN(v, '@id'))] then
            chars[M.charlist[string.char(getValueN(v, '@id'))]] = chars[string.char(getValueN(v, '@id'))]
        end
        local spr = chars[string.char(getValueN(v, '@id'))].sprite
        SetImageCenter(spr,0,getValueN(v, '@height'))
        --SetImageCenter(name .. v['id'],0,getValueN(v, '@height')*0)
    end
    local info = data._children[1]._attr
    local common = data._children[2]._attr
    ret.face = info['face']
    ret.size = tonumber(info['size'])
    ret.bold = info['bold'] == '1'
    ret.charset = info['charset']
    ret.stretchH = info['stretchH']
    ret.smooth = info['smooth']
    ret.padding = info['padding']
    ret.spacing = info['spacing']
    ret.outline = tonumber(info['outline'])
    ret.lineHeight = tonumber(common['lineHeight'])
    ret.base = tonumber(common['base'])
    ret.scaleW = tonumber(common['scaleW'])
    ret.scaleH = tonumber(common['scaleH'])
    ret.pages = tonumber(common['pages'])
    ret.alpha = info['alphaChnl'] == '1'
    ret.chars = chars
    ret.is_bmf = true
    local font_count = #M.fonts
    M.fonts[font_count+1] = ret
    M.fonts[name] = ret
    ret.id = font_count+1
    ret.name = name
    ret.mono_exception = {}
    for k,v in pairs(self.font_functions) do
        ret[k] = v
    end
    return ret
end
function M.font_functions:setMonospace(monospace, mono_exception)
    if monospace then
        self.monospace = monospace
        local ret = {}
        for k,v in ipairs(mono_exception) do
            ret[v] = true
        end
        self.mono_exception = ret
    else
        self.monospace = nil
        self.mono_exception = { }
    end
    return self
end
function M.font_functions:getSize(str,scale,offsetfunc)
    local cursor = Vector(0,-self.base*scale/2)
    local chars = self.chars
    local base_c = cursor:clone()
    local monospace = self.monospace
    local min_x,max_x,min_y,max_y = 0,0,0,0
    for i=1, #str do
        local c = str:sub(i,i)
        if c ~= "\n" then
            local char = chars[c]
            local width = char.width*scale * GetImageScale()
            if monospace and not self.mono_exception[c] then
                width = monospace*scale*0.5
            end
            local height = char.height*scale * GetImageScale()
            local x,y = cursor.x,
                        cursor.y - char.yoffset*scale
            min_x = math.min(min_x,x)
            max_x = math.max(max_x,x + width)
            min_y = math.min(min_y,y)
            max_y = math.max(max_y,y + height)
            if monospace and not self.mono_exception[c] then
                cursor.x = cursor.x + monospace*scale*0.5
            else
                cursor.x = cursor.x + char.xadvance*scale*0.5
            end
        else
            base_c.y = base_c.y + self.lineHeight*scale
            cursor = base_c
            cursor.x = 0
        end
    end
    return max_x - min_x,  max_y - min_y
end
local white = Color(255,255,255,255)
function M.font_functions:render(str,x,y,scale,halign,valign,color,offsetfunc)
    halign = halign or "center"
    valign = valign or "vcenter"
    local move_scale = 1
    if lstg.viewmode ~= "ui" then
        move_scale = 0.7
    end
    local wd, hg = self:getSize(str,scale*move_scale)
    local cursor = Vector(x,y - self.base*scale*move_scale/2)
    local vec = Vector(0,0)
    if halign == "center" then
        cursor.x = cursor.x - wd/2
    elseif halign == "left" then
        cursor.x = cursor.x
    elseif halign == 'right' then
        cursor.x = cursor.x - wd
    end
    if valign == "top" then
        cursor.y = cursor.y + hg
    elseif valign == 'vcenter' then
        cursor.y = cursor.y + hg/2
    elseif valign == 'bottom' then
        cursor.y = cursor.y
    end
    local base_c = cursor:clone()
    local chars = self.chars
    local monospace = self.monospace
    for i=1, #str do
        local c = str:sub(i,i)
        if c ~= "\n" then
            local char = chars[c]
            local offset = char.xoffset*scale*move_scale
            if offsetfunc then
                vec = offsetfunc(i,c,str)
            end
            if color then
                SetImageColor(char.sprite,color)
            end
            Render(char.sprite,cursor.x + offset + vec.x,cursor.y - char.yoffset*scale*move_scale + vec.y,
                    0,scale,scale,0)
            if color then
                SetImageColor(char.sprite,white)
            end
            if monospace and not self.mono_exception[c] then
                local current_space = monospace
                cursor.x = cursor.x + current_space/2*scale*move_scale
            else
                cursor.x = cursor.x + char.xadvance/2*scale*move_scale
            end
        else
            base_c.y = base_c.y - self.lineHeight*scale*move_scale
            cursor = base_c
        end
    end
end
function M.font_functions:renderOutline(str,x,y,scale,halign,valign,color,offsetfunc,outline_size,outline_color,blend,alpha)
    blend = blend or "mul+alpha"
    PushRenderTarget("BMF_FONT_BUFFER")
    RenderClear(Color(0x00000000))
    self:render(str,x,y,scale,halign,valign,color,offsetfunc)
    PopRenderTarget("BMF_FONT_BUFFER")
    local _color = outline_color
    local _size = outline_size
    alpha = alpha or 1
    lstg.PostEffect("BMF_BORDER_SHADER", "BMF_FONT_BUFFER", 6, "mul+alpha",
            {
                { _color.r*bytetofloat, _color.g*bytetofloat, _color.b*bytetofloat, _color.a*bytetofloat },
                { _size, alpha, 0, 0}
            })
end
M.tag_funcs = {}
M.tag_funcs.state = {
    init = function(tag,state)
        state.render_funcs = state.render_funcs or {}
        if tag._attr.color then
            state.color_top = StringToColor(tag._attr.color)
            state.color_bot = state.color_bot or StringToColor(tag._attr.color)
        end
        if tag._attr.bcolor then
            state.color_bot = StringToColor(tag._attr.bcolor)
        end
        if tag._attr.alpha then
            state.alpha = tonumber(tag._attr.alpha)
        end
    end
}
M.tag_funcs.shake = {
    init = function(tag,state)
        state.render_funcs = state.render_funcs or {}
        state.render_funcs.shake = function(render_command,_state,char,timer,v)
            render_command.y = render_command.y + 10 * sin(timer*5 + v.id * 30)
        end
    end
}
M.tag_funcs.border = {
    init = function(tag,state)
        state.render_funcs = state.render_funcs or {}
        if tag._attr.color then
            state.border_color = StringToColor(tag._attr.color)
        end
    end
}
local function fontcopy(tb)
    if type(tb) == "table" then
        local ret = setmetatable({  }, getmetatable(tb))
        for k,v in pairs(tb) do
            if type(v) ~= "table" and k ~= "font" then
                ret[k] = v
            else
                ret[k] = fontcopy(v)
            end
        end
        return ret
    else
        return tb
    end
end
local function returnTList(txt,info,state,ret,state_list,cursor)
    state = state or {}
    state_list = state_list or {}
    state.scale = state.scale or 1
    state.alpha = state.alpha or 1
    local cr_state = fontcopy(state)
    state_list[#state_list+1] = cr_state
    local state_id = #state_list
    ret = ret or {}
    info = info or {}
    local width = info.width or 99999

    local chars = cr_state.font.chars
    cursor = cursor or Vector(0,0)
    for k,v in ipairs(txt._children) do
        if v._type == "TEXT" then
            local str = v._text
            for i = 1, #str do
                local c = str:sub(i,i)
                if c ~= "\n" then
                    local nextc, nextchar
                    if i < #str then
                        nextc = str:sub(i+1,i+1)
                        nextchar = cr_state.font.chars[nextc]
                    end
                    local scale = cr_state.scale
                    local char = cr_state.font.chars[c]
                    local char_advance, nextchar_width
                    if (not cr_state.monospace) and (not (cr_state.monospace_exception and cr_state.monospace_exception[c])) then
                        char_advance = chars[c].xadvance*scale
                    else
                        char_advance = cr_state.monospace
                    end
                    if nextc and nextchar then
                        nextchar_width = nextchar.width - nextchar.xoffset
                    else
                        nextchar_width = 0
                    end
                    if cursor.x + char_advance + nextchar_width*0 > width and c ~= " " then
                        cursor.x = 0
                        cursor.y = cursor.y - info.maxheight or 0
                    end
                    local glyph = ffi.new("zfontrender",0,M.charlist[c] or 0,state_id, cursor.x + char.xoffset*scale, cursor.y - char.yoffset*scale - cr_state.font.base*scale)
                    cursor.x = cursor.x + char_advance
                    info.maxheight = math.max(info.maxheight or 0, cr_state.font.lineHeight * cr_state.scale)
                    table.insert(ret, glyph)
                end
            end
            --table.remove(ret)
        else
            if M.tag_funcs[v._name] then
                M.tag_funcs[v._name].init(v,state)
            end
            returnTList(v,info,state,ret,state_list,cursor)
            --table.insert(ret, { _type = "TAG_END" })
        end
    end
    return ret,state_list
end
---text is the table ver of a xml element!!!
function M:pool(text,init_state,width)
    if type(text) == "string" then
        text = "<TXT>" .. text .. "</TXT>"
        local handler = xml2lua.dom:new()
        local parser = xml2lua.parser(handler,false)
        parser:parse(text)
        text = handler.root
    end
    if not text._children then
        text = {children = text}
    end
    --Print(PrintTableRecursive(text))
    init_state = init_state or {}

    local glyphList, stateList = returnTList(text,{width = width},init_state)
    local borderList = {}
    local i = 1
    local si = 1
    local max_border_size = 0
    local first_border_size = 0
    for k,v in ipairs(glyphList) do
        v.id = k
        stateList[v.state].border_size = stateList[v.state].border_size or 0
        max_border_size = math.max(max_border_size,stateList[v.state].border_size)
        if k == 1 then
            first_border_size = stateList[v.state].border_size
        end
        stateList[v.state].border_color = stateList[v.state].border_color or Color(255,0,0,0)
        if v.state ~= si then
            for _k,_v in ipairs(borderList) do
                if _v.color == stateList[v.state].border_color then
                    i = _k
                    hasHash = true
                end
            end
            if not hasHash then
                i = #borderList + 1
            end
        end
        si = v.state
        local borderHash = stateList[si].border_color.r * 255 * 255 + stateList[si].border_color.g * 255 + stateList[si].border_color.b
        if not borderList[i] then
            borderList[i] = {borderHash = borderHash, color = stateList[si].border_color, glyphList = {}, size = stateList[si].border_size, alpha = stateList[si].alpha or 1}
        end
        table.insert(borderList[i].glyphList,v)
    end
    local ret = {glyphList = glyphList, stateList = stateList, borderList = borderList, max_border = max_border_size, first_border = first_border_size}
    return ret
end
function M:getPoolRect(pool)
    local max_x = 0
    local min_x = 0
    local min_y = 0
    local max_y = 0
    for k,v in ipairs(pool.glyphList) do
        local state = pool.stateList[v.state]
        local char = state.font.chars[M.charlist[v._char]]
        min_x = math.min(min_x, v.x)
        max_x = math.max(max_x, v.x + char.width * GetImageScale())
        min_y = math.min(min_y, v.y)
        max_y = math.max(max_y, v.y + char.height * GetImageScale())
    end
    return min_x, max_x, min_y, max_y
end
function M:getPoolWidth(pool)
    local x1, x2, y1, y2 = M:getPoolRect(pool)
    return x2-x1
end
local render_command = {}
local border_command = {
    { 0, 0, 0, 0 },
    { 0, 0, 0, 0}
}
function M:renderPool(pool,x,y,scale,count,timer,imgscale)
    table.clear(render_command)
    scale = scale or 1
    count = count or 9999999999
    timer = timer or 0
    imgscale = imgscale or 1
    render_command._xorg = x
    render_command._yorg = y
    for _k,_v in ipairs(pool.borderList) do
        PushRenderTarget("BMF_FONT_BUFFER")
        RenderClear(Color(0x00000000))
        for k,v in ipairs(_v.glyphList) do
            if v.id > count then
                break
            end
            local state = pool.stateList[v.state]
            local char = state.font.chars[M.charlist[v._char]]
            render_command.x = x+v.x*scale
            render_command.y = y+v.y*scale
            render_command.img = char.sprite
            render_command.scale = scale*state.scale*imgscale
            render_command.topcolor = state.color_top or ctdefault
            render_command.botcolor = state.color_bot or cbdefault
            render_command.rot = 0
            if state.render_funcs then
                for _,_funcs in pairs(state.render_funcs) do
                    _funcs(render_command,state,char,timer,v)
                end
            end
            SetImageState(render_command.img, "", render_command.topcolor,render_command.topcolor,render_command.botcolor,render_command.botcolor)
            Render(render_command.img,render_command.x,render_command.y,render_command.rot,render_command.scale,render_command.scale)
        end
        PopRenderTarget("BMF_FONT_BUFFER")
        local color = _v.color
        local size = _v.size
        local alpha = _v.alpha or 1
        border_command[1][1] = color.r * bytetofloat
        border_command[1][2] = color.g * bytetofloat
        border_command[1][3] = color.b * bytetofloat
        border_command[1][4] = color.a * bytetofloat
        border_command[2][1] = size
        border_command[2][2] = alpha
        lstg.PostEffect("BMF_BORDER_SHADER", "BMF_FONT_BUFFER", 6, "mul+alpha", border_command)
    end
end
function M.font_functions:clone()
    local ret = {}
    for k,v in pairs(self) do
        if type(v) == "table" then
            ret[k] = M.font_functions.clone(v)
        else
            ret[k] = v
        end
    end
    return ret
end

return M