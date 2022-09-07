local M = {}
MenuSys = M
local mouse = lstg.Input.Mouse
---ok so there's three types of objects in this thing:
---
---the menu manager: the singular object that serves a sort of base for everything else, and is the 'abstraction' of
---the system from an outside perspective. in  here, you define the main menu that should be played (the first one),
---and the background object
---the parameters you set are: the list of menus that should be instantiated, the background bg, the starting function
---
---the menus: many objects/classes that serve as a way to represent an instance of a menu. basically it just means it
---stores how a menu behaves and looks, storing the classes that are used on the options, and so on
---the parameters you set on this are: which options should be used for each... option, how their positions are defined
---what each option should do when you select it
---
---the options: they're the directly interactable objects. they have a lot of types, and they're in general the hardest
---thing to use lmfao
---the parameters you can set: the function for every event (in, out, select, unselect)
---
---i'm going to use multicast delegate-like stuff for defining the behavior functions, such as what to do when an option
---is selected, or what to do when you go out

M.option = Class(object)
function M.option:init(manager,menu,tid,id,data)
    self.bound = false
    self.active = true
    self.manager = manager
    self.menu = menu
    self.layer = LAYER_MENU
    self.tid = tid
    self.id = id
    self.data = data
    self.group = GROUP_MENU
    self.scale = 1
    menu.class.obj_init(self,menu)
    self._x = self._x or self.x
    self._y = self._y or self.y
    self.rect = true
    self.a, self.b = 128,128
    self.font = self.class.font or manager.class.font
    self.pool = self.class.pool
    self.class.ctor(self,data,manager)
end
function M.option:frame()
    task.Do(self)
end
function M.option:ctor(data,manager)

end
function M.option:render()
    SetViewMode("ui")
    if self.img then
        DefaultRenderFunc(self)
        return
    end
    local pool = self.pool or self.class.pool
    if pool then
        BMF:renderPool(pol,self.x,self.y,self.scale,9999999,self.timer)
    end
    local font = self.font or self.class.font
    if not font then
        RenderText('menu',self.tid,self.x,self.y,0.6*2.25*self.scale,'center')
    elseif type(font) == "table" then
        font:render(self.tid,self.x,self.y,self.scale)
    else
        font:render(self.tid,self.x,self.y,0,0,self.scale,self.scale)
    end
end
local voidfunc = function()  end
function M.option:colli(other)
    if mouse.GetKeyState(mouse.Primary) then
        local func = self.class.click or voidfunc
        task.New(self,function() func(self,other)  end)
    end
    if mouse.GetKeyState(mouse.Primary) then
        local func = self.class.hold or voidfunc
        task.New(self,function() func(self,other)  end)
    end
    local menu = self.menu
    local func = menu.class.hover or voidfunc
    task.New(self,function() func(self,other)  end)
end
function M.option:_in()
    self.active = true
    SetFieldInTime(self, 60, math.tween.cubicInOut, {'x', self._x}, {'y', self._y})
end
function M.option:_out()
    self.active = false
    if self.delx or self.dely then
        local delx, dely = self.delx or self.x, self.dely or self.y
        SetFieldInTime(self,60,math.tween.cubicInOut,{'x',delx},{'y',dely})
    end
end
function M.option:_select()
    SetFieldInTime(self, 10, math.tween.cubicInOut, {'x', self._x + 100})
end
function M.option:_unselect()
    SetFieldInTime(self, 10, math.tween.cubicInOut, {'x', self._x})
end
function M.option:kill()
    PreserveObject(self)
    task.New(self,function()
        CallClass(self, "_out")
        Del(self)
    end)
end
function M.option:del()
    Print("option is being deleted")
end
M.option.classname = 'option'

M.menu = Class(object)
--class, id, extra data
--extra data by default is the select function, the positions, the font, and so on
M.menu.options = {
    {M.option, 'bald Option'},
    {M.option, 'bald Option2'}
}
function M.menu:init(manager)
    self.bound = false
    self.selected = 1
    self.manager = manager
    self.options = {}
    self.group = GROUP_MENU
    self.layer = LAYER_MENU
    CallClass(self,"createOptions")
    self.coroutine = coroutine.create(self.class.coroutine)
    self.key_co = {}
    for k,v in pairs(self.class.key_events) do
        local test = false
        for _k, _v in ipairs(self.class.repeat_keys) do
            Print(string.format("v = %s | _v = %s",tostring(k), tostring(_v)))
            if k == _v then
                test = true
            end
        end
        if test then
            self.key_co[k] = coroutine.create(MenuInputChecker)
        end
    end
    CallClass(self, "ctor", manager)
end
--manager,menu,tid,id,data
function M.menu:createOptions()
    local lookup_table = self.option_def or self.class.options
    for k,v in ipairs(lookup_table) do
        local obj = New(v[1],self.manager, self, v[2], k, v[3])
        table.insert(self.options,obj)
        self.options[v[2]] = obj
    end
end
function M.menu:kill()
    CallClass(self,"killOptions")
end
function M.menu:del()
    CallClass(self,"delOptions")
end
function M.menu:killOptions()
    for k,v in ipairs(self.options) do
        Kill(v)
    end
    if self._servants then
        for k,v in pairs(self._servants) do
            Kill(v)
        end
    end
end
function M.menu:delOptions()
    for k,v in ipairs(self.options) do
        Del(v)
    end
    if self._servants then
        for k,v in pairs(self._servants) do
            Del(v)
        end
    end
end
function M.menu:_in()
    for k,v in ipairs(self.options) do
        task.New(v, function()
            v.class._in(v)
        end)
    end
    if self._servants then
        for k,v in pairs(self._servants) do
            task.New(v, function()
                v.class._in(v)
            end)
        end
    end
end
function M.menu:_out()
    for k,v in ipairs(self.options) do
        task.New(v, function()
            v.class._out(v)
        end)
    end
    if self._servants then
        for k,v in pairs(self._servants) do
            task.New(v, function()
                v.class._out(v)
            end)
        end
    end
end
function M.menu:scroll(vert)
    local lookup_table = self.options
    local t_ids = lookup_table
    local select = self.selected
    if(select + vert > #t_ids) then
        select = 1
    elseif(select + vert < 1) then
        select = #t_ids
    else
        select = select + vert
    end
    self.class.changeSelect(self,select,vert)
end
function M.menu:changeSelect(newid,vert)
    local t_ids = self.options
    local oldid = self.selected
    CallClass(self, "onScroll",newid,oldid,vert)
    for i=1, #t_ids do
        if i ~= newid then
            local obj = self.options[i]
            task.New(obj, function()
                obj.class._unselect(obj,oldid,newid,vert)
            end)
        end
    end

    self.selected = newid

    local obj2 = self.options[self.selected]
    obj2.class._select(obj2,oldid,newid,vert)
end
function M.menu:hover(option)
    local newid = option.id
    if newid ~= self.selected then
        CallClass(self,"changeSelect",newid)
    end
end
function M.menu:select()
end
M.menu.repeat_keys = {'menu_up', 'menu_down'}
M.menu.key_events = {}
function M.menu.key_events.menu_down(self)
   self.class.scroll(self,1)
end
function M.menu.key_events.menu_up(self)
    self.class.scroll(self,-1)
end
function M.menu.key_events.confirm(self)
    local obj = self.options[self.selected]
    local func = (obj.onEnter or obj.class.onEnter) or voidfunc
    func(obj)
end
function M.menu.obj_init(self,menu)
    self._x, self._y = 300, 300 - self.id * 50
    self.delx = -400
    self.dely = self._y
    self.x = self.delx
    self.y = self.dely
end
function M.menu:enter()
    self.class._in(self)
end
function M.menu:coroutine()
    while true do
        for k,v in pairs(self.class.key_events) do
            if self.key_co[k] ~= nil then
                local e, key_status
                e, key_status = coroutine.resume(self.key_co[k],k)
                if key_status then
                    self.class.key_events[k](self)
                end
            else
                if SysKeyIsPressed(k) then
                    Print(k)
                    self.class.key_events[k](self)
                end
            end
        end
        coroutine.yield()
    end
end

M.manager = zclass(object)
M.manager.name = "DEFAULT_MANAGER"
--{class, id}
M.manager.menus = {
    {M.menu, "main_menu"}
}
M.manager.intro_menu = "main_menu"
function M.manager:init()
    self.menus = {}
    self.bound = false
    self.group = GROUP_MENU
    self.layer = LAYER_MENU-100
    self.stack = stack()
    for k,v in ipairs(self.class.menus) do
        Print(PrintTable(v))
        self.menus[v[2]] = New(v[1],self)
    end
    task.New(self,function()
        self.class.enter_menu(self,self.menus[self.class.intro_menu])
    end)
end
function M.manager:render()
    SetViewMode("ui")
    RenderText('menu',self.class.name,screen.width/2,screen.height/2,1,'center')
end
function M.manager:frame()
    task.Do(self)
    local C, E = coroutine.resume(self.stack[0].coroutine, self.stack[0])
    if(not C)then
        error(E)
    end
end
function M.manager:kill()
    for k,v in pairs(self.menus) do
        if v == self.stack[0] then
            Kill(v)
        else
            Del(v)
        end
    end
end
function M.manager:del()
    for k,v in pairs(self.menus) do
        Del(v)
    end
end
function M.manager:switch_menu(menu)
    if type(menu) == "string" then
        menu = self.menus[menu]
    end
    local prev_menu = self.stack[0]
    if menu.exit_other == nil or menu.exit_other then
        prev_menu.class._out(prev_menu)
    end
    self.class.enter_menu(self,menu)
end
function M.manager:enter_menu(menu)
    if type(menu) == "string" then
        menu = self.menus[menu]
    end
    self.stack:push(menu)
    menu.class._in(menu)
end
function M.manager:go_back()
    if #self.stack > 1 then
        local menu = self.stack[0]
        menu.class._out(menu)
        self.stack:pop()
    else
        CallClass(self,"exit")
    end
end

function MenuInputChecker(name)
    while(true) do
        while(not SysKeyIsPressed(name))do
            coroutine.yield(false) --return false until the key is pressed
        end
        coroutine.yield(true) --return true once
        for i=0, 30 do
            coroutine.yield(false) --return false for 30 frames
            if (not SysKeyIsDown(name)) then
                break --if the key is not being held down, break out of for (which will make you consequently restart
            end
        end
        while (SysKeyIsDown(name)) do
            coroutine.yield(true) -- return true once every 3 frames
            for i=0, 3 do
                coroutine.yield(false) --return false for 3 frames
            end
        end
    end
end

local function getMousePositionToUI()
    local mx, my = lstg.GetMousePosition() -- 左下角为原点，y 轴向上
    -- 转换到 UI 视口
    mx = mx - screen.dx
    my = my - screen.dy

    -- 方法一：正常思路

    -- 归一化
    --mx = mx / (screen.width * screen.scale)
    --my = my / (screen.height * screen.scale)
    -- 转换到 UI 坐标
    --mx = mx * screen.width
    --my = my * screen.height

    -- 方法二：由于 UI 坐标系左下角就是原点，直接用 screen.scale

    mx = mx / screen.scale
    my = my / screen.scale

    return mx, my
end
mouse_pointer = Class(object)
function mouse_pointer:init(manager)
    self.bound = false
    self.group = GROUP_CURSOR
    self.layer = 1000
    self.rect = true
    self.a, self.b = 16,16
    self.manager = manager
end
function mouse_pointer:frame()
    self.x, self.y = getMousePositionToUI()
    if not IsValid(self.manager) then
        Kill(self)
    end
end
return M