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
M.states = {}
M.fonts = {}
M.charlist = {
    ' ', '!', '"', '#', '$', '%', '&', "'", '(', ')', '*', '+', ',', '-', '.',
    '/', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', ':', ';', '<', '=',
    '>', '?', '@', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L',
    'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', '[',
    '\\',']', '^', '_', '`', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j',
    'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y',
    'z', '{', '|', '}', '~'
}
for k,v in ipairs(M.charlist) do
    M.charlist[v] = k
end
--
M.font_functions = {}
function M:loadFont(name,path,imgpath)
    --local data = xml:ParseXmlText(FU:getStringFromFile(path))
    local handler = xml2lua.dom:new()
    local parser = xml2lua.parser(handler)
    parser:parse(LoadTextFile(path))
    local data = handler.root
    local str, id = PrintTableRecursive(data)
    Print("FONT: "..name)
    Print(id)
    local tex = LoadTexture("bmftexture:" .. name, imgpath)
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
            sprite = LoadImage(name .. v['id'], "bmftexture:" .. name, getValueN(v, '@x'),getValueN(v, '@y'),
                    getValueN(v, '@width'), getValueN(v, '@height'),0,0,false),
            sprite_name = 'philosopher_' .. v['id']
        }
        chars[M.charlist[string.char(getValueN(v, '@id'))]] = chars[string.char(getValueN(v, '@id'))]
        local spr = chars[string.char(getValueN(v, '@id'))].sprite
        --SetImageCenter(name .. v['@id'],0,getValueN(v, '@height'))
        SetImageCenter(name .. v['id'],0,getValueN(v, '@height'))
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
function M.font_functions:getSize(str,scale)
    local cursor = Vector(0,self.base)
    local chars = self.chars
    local cwidth = 0
    local cxoff = 0
    local cxadvance = 0
    local maxheight = 0
    local maxbottom = 0
    local linecount = 1
    local move_scale = 1
    local base_c = cursor:clone()
    local monospace = self.monospace
    for i=1, #str do
        local c = str:sub(i,i)
        if c ~= "\n" then
            local char = chars[c]
            if monospace and not self.mono_exception[c] then
                local current_space = monospace
                cursor.x = cursor.x + current_space/2
                cxadvance = current_space
                cwidth = current_space
            else
                cwidth = char.width
                cxadvance = char.xadvance
                cursor.x = cursor.x + cxadvance/2
            end
            cxoff = char.xoffset
            maxheight = math.max(maxheight,char.height/2 - char.yoffset)
            maxbottom = math.min(maxbottom,char.height/-2 + char.yoffset)
        else
            base_c.y = base_c.y - self.lineHeight
            linecount = linecount + 1
            cursor = base_c
            cursor.x = 0
        end
    end
    return (cursor.x - cxadvance + cwidth)*scale*move_scale, (linecount * self.lineHeight)*scale*move_scale
end
function M.font_functions:render(str,x,y,scale,halign,valign,rm,offsetfunc)
    halign = halign or "center"
    valign = valign or "vcenter"
    local move_scale = 1
    if lstg.viewmode ~= "ui" then
        move_scale = 0.44444444444444444
    end
    local wd, hg = self:getSize(str,scale)
    local cursor = Vector(x,y - self.base*scale/2)
    local vec = Vector(0,0)
    if halign == "center" then
        cursor.x = cursor.x - wd/2
    elseif halign == 'right' then
        cursor.x = cursor.x - wd
    end
    if valign == "bottom" then
        cursor.y = cursor.y + hg
    elseif valign == 'vcenter' then
        cursor.y = cursor.y + hg/2
    elseif valign == 'top' then
        cursor.y = cursor.y
    end
    local base_c = cursor:clone()
    local chars = self.chars
    local monospace = self.monospace
    local _rm = rm
    if type(rm) == "string" then
        _rm = string.format("BMFSTATE:%s", rm)
    elseif rm then
        _rm = rm:getName()
    end
    for i=1, #str do
        local c = str:sub(i,i)
        if c ~= "\n" then
            local char = chars[c]
            local offset = char.xoffset*scale*move_scale
            if offsetfunc then
                vec = offsetfunc(i,c,str)
            end
            if _rm then
                char.sprite:setRenderMode(_rm)
            end
            Render(char.sprite,cursor.x + offset + vec.x,cursor.y - char.yoffset*scale*move_scale + vec.y,
                    0,scale,scale,0)
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
M.tag_funcs = {}
M.tag_funcs.state = {
    init = function(tag,state)
        state.render_funcs = state.render_funcs or {}
        if tag._attr.color then
            state.color_top = StringToColor(tag._attr.color)
            state.color_bot = StringToColor(tag._attr.color)
        end
        if tag._attr.bcolor then
            state.color_bot = StringToColor(tag._attr.bcolor)
        end
        if tag._attr.alpha then
            state.color_bot.a = tonumber(tag._attr.alpha)
            state.color_top.a = tonumber(tag._attr.alpha)
        end
    end
}
M.tag_funcs.shake = {
    init = function(tag,state)
        state.render_funcs = state.render_funcs or {}
        state.render_funcs.shake = function(render_command,_state,char,timer,v)
            render_command.y = render_command.y + 3 * sin(timer*5 + v.id * 30)
        end
    end
}
count = 1
--done TODO: PUT STATE ON EACH WORD, OVERWRITE STATES
local function returnTList(txt,info,state,ret,state_list,cursor)
    state = state or {}
    state_list = state_list or {}
    state.scale = state.scale or 1
    local cr_state = softcopy(state)
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
local function getLargestHeight(line)
    local heightList = {}
    for k,v in ipairs(line) do
        table.insert(heightList,v.lineHeight)
    end
    return math.max(unpack(heightList))
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
    for k,v in ipairs(glyphList) do
        v.id = k
        stateList[v.state].border_size = stateList[v.state].border_size or 0
        stateList[v.state].border_color = stateList[v.state].border_color or Color(255,0,0,0)
        if v.state ~= si then
            local borderHash = stateList[v.state].border_size * 255 * 255 * 255 +
            stateList[v.state].border_color.r * 255 * 255 + stateList[v.state].border_color.g * 255 + stateList[v.state].border_color.b
            local hasHash = false
            for _k,_v in ipairs(borderList) do
                if _v.borderHash == borderHash then
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
            borderList[i] = {borderHash = borderHash, color = stateList[si].border_color, glyphList = {}, size = stateList[si].border_size}
        end
        table.insert(borderList[i].glyphList,v)
    end
    local ret = {glyphList = glyphList, stateList = stateList, borderList = borderList}
    return ret
end
local ctdefault = Color(255,255,255,255)
local cbdefault = Color(255,255,255,255)
local font_RTBUFFER = CreateRenderTarget("BMF_FONT_BUFFER")
function M:renderPool(pool,x,y,scale,count,timer)
    local render_command = {}
    count = count or 9999999999
    timer = timer or 0
    render_command._xorg = x
    render_command._yorg = y
    for _k,_v in ipairs(pool.borderList) do
        --PushRenderTarget("BMF_FONT_BUFFER")
        --RenderClear(Color(0x00000000))
        for k,v in ipairs(_v.glyphList) do
            if v.id > count then
                break
            end
            local state = pool.stateList[v.state]
            local char = state.font.chars[M.charlist[v._char]]
            render_command.x = x+v.x*scale
            render_command.y = y+v.y*scale
            render_command.img = char.sprite
            render_command.scale = scale*state.scale
            render_command.topcolor = state.color_top or ctdefault
            render_command.botcolor = state.color_bot or cbdefault
            render_command.rot = 0
            if state.render_funcs then
                for _k,_funcs in pairs(state.render_funcs) do
                    _funcs(render_command,state,char,timer,v)
                end
            end
            SetImageState(render_command.img, "", render_command.topcolor,render_command.topcolor,render_command.botcolor,render_command.botcolor)
            Render(render_command.img,render_command.x,render_command.y,render_command.rot,render_command.scale,render_command.scale)
        end
        --PopRenderTarget("BMF_FONT_BUFFER")
        --TODO: USE RENDERTARGET FOR OUTLINE (EXTRA_BLEND_NEEDED)
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