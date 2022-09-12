---=====================================
---luastg screen
---=====================================
local function deepcopy(tb) --copies a table Completely, copying the metatable and the child tables (other ref data types dont get copied)
    local ret = {}
    if getmetatable(tb) then
        setmetatable(ret, getmetatable(tb))
    end
    for k,v in pairs(tb) do
        if type(v) ~= "table" then
            ret[k] = v
        else
            ret[k] = deepcopy(v)
        end
    end
    return ret
end
local function softcopy(tb) --copies just the main table, every child table is just the reference
    local ret = {}
    for k,v in pairs(tb) do
        ret[k] = v
    end
    return ret
end

----------------------------------------
--- build-in white

lstg.CreateRenderTarget("rt:screen-white", 64, 64)
lstg.LoadImage("img:screen-white", "rt:screen-white", 16, 16, 16, 16)

function UpdateScreenResources()
    lstg.PushRenderTarget("rt:screen-white")
    lstg.RenderClear(lstg.Color(255, 255, 255, 255))
    lstg.PopRenderTarget()
end
local scwidth, scheight = 1920,1080 --screen width and height (coords, not actual resolution)
local stg_scale = 2.25
local rsw, rsh = scwidth / stg_scale, scheight / stg_scale
local rx, ry = scwidth/2, scheight/2 --stgframe center on the screen
local ww, wh = 800/stg_scale, 1000/stg_scale --world width and height (stg frame)
--local hidden_width = 48
local rw, rh = ww*stg_scale, wh*stg_scale --render width and height (the size of the stg frame on the screen)
local boundw, boundh = 32, 32 --object deletion box size (stg frame + bound)
Print(string.format("STG size: %d x %d", ww, wh))

local pw, ph = 800/stg_scale, 1000/stg_scale --player bounds (no idea why its different lol)
local RAW_DEFAULT_WORLD = {--this one is the "standard" one that will always be the base for everything
    l = -ww/2, r = ww/2, b = -wh/2, t = wh/2,
    boundl = -ww/2-boundw, boundr = ww/2+boundw, boundb = -wh/2-boundh, boundt = wh/2+boundh,
    scrl = rx-rw/2, scrr = rx+rw/2, scrb = ry-rh/2, scrt = ry+rh/2,
    pl = -pw/2, pr = pw/2, pb = -ph/2, pt = ph/2,

    world = 15,

    scale = stg_scale
}

local DEFAULT_WORLD = deepcopy(RAW_DEFAULT_WORLD)

----------------------------------------
---screen

---@class screen
screen = {}

---@param no_reset_world boolean
---@overload fun()
function ResetScreen(no_reset_world)
    -- 根据横纵比选择坐标系
    screen.width = scwidth
    screen.height = scheight
    -- 计算视口位置
    screen.hScale = setting.resx / screen.width
    screen.vScale = setting.resy / screen.height
    screen.resScale = setting.resx / setting.resy
    screen.scale = math.min(screen.hScale, screen.vScale)
    screen.scalefrom480 = screen.width/640
    if screen.resScale >= (screen.width / screen.height) then
        screen.dx = (setting.resx - screen.scale * screen.width) * 0.5
        screen.dy = 0
    else
        screen.dx = 0
        screen.dy = (setting.resy - screen.scale * screen.height) * 0.5
    end
    lstg.scale_3d = 0.007 * screen.scale
    -- 版面
    if not no_reset_world then
        if setting.resx > setting.resy then
            ResetWorld()
            ResetWorldOffset()
        else
            -- 大概只用于启动器，目前还没有做竖版的
            lstg.world = deepcopy(RAW_DEFAULT_WORLD)
            SetBound(lstg.world.boundl, lstg.world.boundr, lstg.world.boundb, lstg.world.boundt)
            ResetWorldOffset()
        end
    end
end

function ResetScreen2() -- TODO: 删了这个不再使用的方法
    ResetScreen(true)
end

---用于设置默认world参数
function OriginalSetDefaultWorld(l, r, b, t, bl, br, bb, bt, sl, sr, sb, st, pl, pr, pb, pt, m)
    local w = {}
    w.l = l
    w.r = r
    w.b = b
    w.t = t
    w.boundl = bl
    w.boundr = br
    w.boundb = bb
    w.boundt = bt
    w.scrl = sl
    w.scrr = sr
    w.scrb = sb
    w.scrt = st
    w.pl = pl
    w.pr = pr
    w.pb = pb
    w.pt = pt
    w.world = m
    DEFAULT_WORLD = w
end

function SetDefaultWorld(l, b, w, h, bound, m)
    OriginalSetDefaultWorld(
    --l,r,b,t,
            (-w / 2), (w / 2), (-h / 2), (h / 2),
    --bl,br,bb,bt,
            (-w / 2) - bound, (w / 2) + bound, (-h / 2) - bound, (h / 2) + bound,
    --sl,sr,sb,st,
            (l), (l + w), (b), (b + h),
    --pl,pr,pb,pt
            (-w / 2), (w / 2), (-h / 2), (h / 2),
    --world mask
            m
    )
end

---用于重置world参数
function RawGetDefaultWorld()
    local w = {}
    for k, v in pairs(RAW_DEFAULT_WORLD) do
        w[k] = v
    end
    return w
end

function GetDefaultWorld()
    local w = {}
    for k, v in pairs(DEFAULT_WORLD) do
        w[k] = v
    end
    return w
end

function RawResetWorld()
    local w = {}
    for k, v in pairs(RAW_DEFAULT_WORLD) do
        w[k] = v
    end
    lstg.world = w
    DEFAULT_WORLD = w
    SetBound(lstg.world.boundl, lstg.world.boundr, lstg.world.boundb, lstg.world.boundt)
end

function ResetWorld()
    local w = {}
    for k, v in pairs(DEFAULT_WORLD) do
        w[k] = v
    end
    lstg.world = w
    SetBound(lstg.world.boundl, lstg.world.boundr, lstg.world.boundb, lstg.world.boundt)
end

---用于设置world参数
function OriginalSetWorld(l, r, b, t, bl, br, bb, bt, sl, sr, sb, st, pl, pr, pb, pt, m)
    local w = lstg.world
    w.l = l
    w.r = r
    w.b = b
    w.t = t
    w.boundl = bl
    w.boundr = br
    w.boundb = bb
    w.boundt = bt
    w.scrl = sl
    w.scrr = sr
    w.scrb = sb
    w.scrt = st
    w.pl = pl
    w.pr = pr
    w.pb = pb
    w.pt = pt
    w.world = m
end

function SetWorld(l, b, w, h, bound, m)
    bound = bound or 32
    m = m or 15
    OriginalSetWorld(
    --l,r,b,t,
            (-w / 2), (w / 2), (-h / 2), (h / 2),
    --bl,br,bb,bt,
            (-w / 2) - bound, (w / 2) + bound, (-h / 2) - bound, (h / 2) + bound,
    --sl,sr,sb,st,
            (l), (l + w), (b), (b + h),
    --pl,pr,pb,pt
            (-w / 2), (w / 2), (-h / 2), (h / 2),
    --world mask
            m
    )
    SetBound(lstg.world.boundl, lstg.world.boundr, lstg.world.boundb, lstg.world.boundt)
end

----------------------------------------
---3d

lstg.view3d = {
    eye = { 0, 0, -1 },
    at = { 0, 0, 0 },
    up = { 0, 1, 0 },
    fovy = PI_2,
    z = { 0, 2 },
    fog = { 0, 0, Color(0x00000000) },
}

function Reset3D()
    lstg.view3d.eye = { 0, 0, -1 }
    lstg.view3d.at = { 0, 0, 0 }
    lstg.view3d.up = { 0, 1, 0 }
    lstg.view3d.fovy = PI_2
    lstg.view3d.z = { 1, 2 }
    lstg.view3d.fog = { 0, 0, Color(0x00000000) }
end

function Set3D(key, a, b, c)
    if key == 'fog' then
        a = tonumber(a or 0)
        b = tonumber(b or 0)
        if c then
            c.a = 255 -- 雾的透明度应该固定写 255
        end
        lstg.view3d.fog = { a, b, c }
        return
    end
    a = tonumber(a or 0)
    b = tonumber(b or 0)
    c = tonumber(c or 0)
    if key == 'eye' then
        lstg.view3d.eye = { a, b, c }
    elseif key == 'at' then
        lstg.view3d.at = { a, b, c }
    elseif key == 'up' then
        lstg.view3d.up = { a, b, c }
    elseif key == 'fovy' then
        lstg.view3d.fovy = a
    elseif key == 'z' then
        lstg.view3d.z = { a, b }
    end
end

----------------------------------------
---视口、投影等的转换和坐标映射

function SetViewMode(mode)
    lstg.viewmode = mode
    if mode == '3d' then
        SetViewport(0 * screen.scale + screen.dx, screen.width * screen.scale + screen.dx,
                0 * screen.scale + screen.dy, screen.height * screen.scale + screen.dy)
        SetPerspective(
                lstg.view3d.eye[1], lstg.view3d.eye[2], lstg.view3d.eye[3],
                lstg.view3d.at[1], lstg.view3d.at[2], lstg.view3d.at[3],
                lstg.view3d.up[1], lstg.view3d.up[2], lstg.view3d.up[3],
                lstg.view3d.fovy, (lstg.world.r - lstg.world.l) / (lstg.world.t - lstg.world.b),
                lstg.view3d.z[1], lstg.view3d.z[2]
        )
        SetFog(lstg.view3d.fog[1], lstg.view3d.fog[2], lstg.view3d.fog[3])
        SetImageScale(((((lstg.view3d.eye[1] - lstg.view3d.at[1]) ^ 2
                + (lstg.view3d.eye[2] - lstg.view3d.at[2]) ^ 2
                + (lstg.view3d.eye[3] - lstg.view3d.at[3]) ^ 2) ^ 0.5)
                * 2 * math.tan(lstg.view3d.fovy * 0.5)) / screen.width)
    elseif mode == 'world' then
        --计算world宽高和偏移
        local offset = lstg.worldoffset
        local w = lstg.world
        local world = {
            height = (w.t - w.b), --world高度
            width = (w.r - w.l), --world宽度
        }
        world.setheight = world.height * (1 / offset.vscale)--缩放后的高度
        world.setwidth = world.width * (1 / offset.hscale)--缩放后的宽度
        world.setdx = offset.dx * (1 / offset.hscale)--水平整体偏移
        world.setdy = offset.dy * (1 / offset.vscale)--垂直整体偏移
        --计算world最终参数
        world.l = offset.centerx - (world.setwidth / 2) + world.setdx
        world.r = offset.centerx + (world.setwidth / 2) + world.setdx
        world.b = offset.centery - (world.setheight / 2) + world.setdy
        world.t = offset.centery + (world.setheight / 2) + world.setdy
        --应用参数
        SetRenderRect(world.l, world.r, world.b, world.t, w.scrl, w.scrr, w.scrb, w.scrt)
        SetImageScale(1/screen.scalefrom480)
    elseif mode == 'ui' then
        SetRenderRect(0, screen.width, 0, screen.height, 0, screen.width, 0, screen.height)
        SetImageScale(1)
    elseif mode == '2dbg' then
        SetRenderRect(0, screen.width, 0, screen.height, 0, screen.width, 0, screen.height)
        SetImageScale(1/screen.scalefrom480)
    else
        error('Invalid arguement.')
    end
end

function RenderClearViewMode(color)
    local function draw(l, r, b, t)
        lstg.SetImageState("img:screen-white", "", color)
        lstg.RenderRect("img:screen-white", l, r, b, t)
    end
    if lstg.viewmode == '3d' then
        SetViewMode('world')
        local w = lstg.world
        draw(w.l, w.r, w.b, w.t)
        SetViewMode('3d')
    elseif lstg.viewmode == 'world' then
        local w = lstg.world
        draw(w.l, w.r, w.b, w.t)
    elseif lstg.viewmode == 'ui' or lstg.viewmode == "2dbg" then
        draw(0, screen.width, 0, screen.height)
    else
        error('Unknown viewmode.')
    end
end

function WorldToUI(x, y)
    local w = lstg.world
    return w.scrl + (w.scrr - w.scrl) * (x - w.l) / (w.r - w.l), w.scrb + (w.scrt - w.scrb) * (y - w.b) / (w.t - w.b)
end

function WorldToScreen(x, y)
    local w = lstg.world
    if setting.resx > setting.resy then
        return (setting.resx - setting.resy * screen.width / screen.height) / 2 / screen.scale + w.scrl + (w.scrr - w.scrl) * (x - w.l) / (w.r - w.l), w.scrb + (w.scrt - w.scrb) * (y - w.b) / (w.t - w.b)
    else
        return w.scrl + (w.scrr - w.scrl) * (x - w.l) / (w.r - w.l), (setting.resy - setting.resx * screen.height / screen.width) / 2 / screen.scale + w.scrb + (w.scrt - w.scrb) * (y - w.b) / (w.t - w.b)
    end
end

function ScreenToWorld(x, y)
    --该功能并不完善
    local dx, dy = WorldToScreen(0, 0)
    return x - dx, y - dy
end

---设置渲染矩形（会被SetViewMode覆盖）
---@param l number @坐标系左边界
---@param r number @坐标系右边界
---@param b number @坐标系下边界
---@param t number @坐标系上边界
---@param scrl number @渲染系左边界
---@param scrr number @渲染系右边界
---@param scrb number @渲染系下边界
---@param scrt number @渲染系上边界
---@overload fun(info:table):nil @坐标系信息
function SetRenderRect(l, r, b, t, scrl, scrr, scrb, scrt)
    local function setViewportAndScissorRect(l, r, b, t)
        SetViewport(l, r, b, t)
        SetScissorRect(l, r, b, t)
    end
    if l and r and b and t and scrl and scrr and scrb and scrt then
        --设置坐标系
        SetOrtho(l, r, b, t)
        --设置视口
        setViewportAndScissorRect(
                scrl * screen.scale + screen.dx,
                scrr * screen.scale + screen.dx,
                scrb * screen.scale + screen.dy,
                scrt * screen.scale + screen.dy
        )
        --清空fog
        SetFog()
        --设置图像缩放比
        SetImageScale(1)
    elseif type(l) == "table" then
        --设置坐标系
        SetOrtho(l.l, l.r, l.b, l.t)
        --设置视口
        setViewportAndScissorRect(
                l.scrl * screen.scale + screen.dx,
                l.scrr * screen.scale + screen.dx,
                l.scrb * screen.scale + screen.dy,
                l.scrt * screen.scale + screen.dy
        )
        --清空fog
        SetFog()
        --设置图像缩放比
        SetImageScale(1)
    else
        error("Invalid arguement.")
    end
end
----------------------------------------
---world offset
---by ETC
---用于独立world本身的数据、world坐标系中心偏移和横纵缩放、world坐标系整体偏移

local DEFAULT_WORLD_OFFSET = {
    centerx = 0, centery = 0, --world中心位置偏移
    hscale = 1, vscale = 1, --world横向、纵向缩放
    dx = 0, dy = 0, --整体偏移
}

lstg.worldoffset = {
    centerx = 0, centery = 0, --world中心位置偏移
    hscale = 1, vscale = 1, --world横向、纵向缩放
    dx = 0, dy = 0, --整体偏移
}

---重置world偏移
function ResetWorldOffset()
    lstg.worldoffset = lstg.worldoffset or {}
    for k, v in pairs(DEFAULT_WORLD_OFFSET) do
        lstg.worldoffset[k] = v
    end
end

---设置world偏移
function SetWorldOffset(centerx, centery, hscale, vscale)
    lstg.worldoffset.centerx = centerx
    lstg.worldoffset.centery = centery
    lstg.worldoffset.hscale = hscale
    lstg.worldoffset.vscale = vscale
end

----------------------------------------
---init

ResetScreen()--先初始化一次，！！！注意不能漏掉这一步
