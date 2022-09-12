---=====================================
---luastg object
---=====================================

----------------------------------------
--碰撞组(底层所需)
GROUP_GHOST = 0
GROUP_ENEMY_BULLET = 1
GROUP_ENEMY = 2
GROUP_PLAYER_BULLET = 3
GROUP_PLAYER = 4
GROUP_INDES = 5
GROUP_ITEM = 6
GROUP_NONTJT = 7
GROUP_SPELL = 8--由OLC添加，可用于自机bomb
GROUP_MENU = 9
GROUP_CURSOR = 9
GROUP_ALL = 16
GROUP_NUM_OF_GROUP = 16
--层次结构
LAYER_BG = -700
LAYER_ENEMY = -600
LAYER_PLAYER_BULLET = -500
LAYER_PLAYER = -400
LAYER_ITEM = -300
LAYER_ENEMY_BULLET = -200
LAYER_ENEMY_BULLET_EF = -100
LAYER_TOP = 0
LAYER_UI = 250
LAYER_POST_PROCESS = 500
LAYER_MENU = 1000

----------------------------------------
---class

all_class = {}
class_name = {}

--base class of all classes
object = { 0, 0, 0, 0, 0, 0;
           is_class = true,
           init = function()
           end,
           del = function()
           end,
           frame = function()
           end,
           render = DefaultRenderFunc,
           colli = function(other)
           end,
           kill = function()
           end
}
table.insert(all_class, object)
local function functify(fnc)
    if type(fnc) == "table" then
        if fnc.funced then
            return fnc
        elseif fnc.tofunc then
            return fnc:tofunc()
        else
            return function (...)
                for k,v in ipairs(fnc) do
                    v(...)
                end
            end
        end
    else
        return fnc
    end
end
local function baseclass(base)
    if not base then
        --[!!!处理一个特殊的歧义!!!]
        --由于lua无法识别传入nil参数和不传入参数，所以会出现歧义，进而可能会引发最隐匿的bug
        --如果指定的基类base不存在(nil)，这个函数等效于不传入参数base，那么这个函数就会按照XXX=Class(object)处理
        local dinfo = debug.getinfo(2)
        local ret = ""
        ret = ret .. "定义新的object class类时使用了不存在的基类。\n"
        ret = ret .. "这将会等价于使用object class作为基类，即Class(object)。\n"
        ret = ret .. "谨慎检查这是否是您想要的结果。\n"
        ret = ret .. "----file: [" .. dinfo.source .. "]\n----line: " .. dinfo.currentline
        lstg.Log(3, ret)
        ret = ret .. "\n忽略这个警告?"
        --lstg.MsgBoxWarn(ret)
        --忽视警告，则使用默认基类object类
        base = object
    end
    if (type(base) ~= 'table') or not base.is_class then
        error('Invalid base class or base class does not exist.')
    end
    local result = { 0, 0, 0, 0, 0, 0 }
    result.is_class = true
    result.init = base.init
    result.del = base.del
    result.frame = base.frame
    result.render = base.render
    result.colli = base.colli
    result.kill = base.kill
    result.base = base
    return result
end
---define new class
---@param base object
---@param define object
---@overload fun(base:object)
function Class(base, define)
    local result = baseclass(base)
    if define and type(define) == "table" then
        for k, v in pairs(define) do
            result[k] = v
        end
    end
    table.insert(all_class, result)
    return result
end
local function dirret(...)
    return ...
end
function zclass(base, ...)
    local arg = {...}
    base = base or object
    local copyf = dirret
    if arg[#arg] == true then
        copyf = deepcopy
        table.remove(arg)
    end
    local result = baseclass(base)
    result.base = base
    result[".render"] = true
    for k, v in pairs(base) do
        if type(k) ~= "number" then
            result[k] = copyf(v)
        end
    end
    for k,define in ipairs(arg) do
        if type(define) == "table" then
            for k, v in pairs(define) do
                result[k] = copyf(v)
            end
        end
    end
    table.insert(all_class, result)
    return result
end
---对所有class的回调函数进行整理，给底层调用
function InitAllClass()
    for _, v in pairs(all_class) do
        v[1] = functify(v.init)
        v[2] = functify(v.del)
        v[3] = functify(v.frame)
        v[4] = functify(v.render)
        v[5] = functify(v.colli)
        v[6] = functify(v.kill)
    end
end

----------------------------------------
---单位管理

function RawDel(o)
    if o then
        o.status = 'del'
        if o._servants then
            DelServants(o)
        end
    end
end

function RawKill(o)
    if o then
        o.status = 'kill'
        if o._servants then
            KillServants(o)
        end
    end
end

function PreserveObject(o)
    o.status = 'normal'
end

local OldKill = Kill
local OldDel = Del

function Kill(o)
    if o then
        if o._servants then
            KillServants(o)
        end
        OldKill(o)
    end
end

function Del(o)
    if o then
        if o._servants then
            DelServants(o)
        end
        OldDel(o)
    end
end


--！潜在问题：多玩家适配
function SetV2(obj, v, angle, rot, aim)
    if aim then
        SetV(obj, v, angle + Angle(obj, player), rot)
    else
        SetV(obj, v, angle, rot)
    end
end

Class = zclass