local function base_class(base)
    base = base or {
        __store = {}
    }
    if type(base) == "string" then
        base = require(base)
    end
    local ret = {
        __store = {
            __base = base,
            __type = package.current_module
        }}
    ret.__index = ret
    return ret
end
local protected_fields = {"__private", "__settled"}
local function class_index(tb,key)
    local tb_store = rawget(tb,"__store")
    if tb_store.__settled then
        for k,v in ipairs(protected_fields) do
            if key == v then
                error(string.format("Trying to access forbidden field %s",key))
            end
        end
        if rawget(tb_store.__private,key) then
            error(string.format("Trying to access (read) private field %s", key))
        else
            local ret = rawget(tb_store,key)
            if ret ~= nil then
                return rawget(tb_store,key)
            else
                return rawget(tb_store,"__base")[key]
            end
        end
    else
        local ret = rawget(tb_store,key)
        if ret ~= nil then
            return rawget(tb_store,key)
        else
            return rawget(tb_store,"__base")[key]
        end
    end
end
local function class_newindex(tb,key,value)
    local tb_store = rawget(tb,"__store")
    if tb_store.__settled then
        for k,v in ipairs(protected_fields) do
            if key == v then
                error(string.format("Trying to access forbidden field %s",key))
            end
        end
        if rawget(tb_store.__private,key) then
            error(string.format("Trying to access (write) private field %s", key))
        elseif rawget(tb_store.__readonly,key) then
            error(string.format("Trying to access (write) readonly field %s", key))
        else
            return rawset(tb_store,key,value)
        end
    else
        return rawset(tb_store,key,value)
    end
end
local function settle_class(tb)
    rawset(rawget(tb,"__store"),"__settled", true)
    return tb
end
function class(base)
    local ret = base_class(base)
    local mt = {
        __call = function(cls_tb,...)
            local obj = setmetatable({}, cls_tb)
            cls_tb.new(obj,...)
            return obj
        end,
        __type = "classdef",
        __index = class_index,
        __newindex = class_newindex,
        __len = settle_class
    }
    ret = setmetatable(ret,mt)
    return ret
end
function static_class(base)
    local ret = base_class(base)
    local mt = {
        __call = function(cls_tb,...)
            cls_tb:call(...)
        end,
        __type = "classdef",
        __is_static = true,
        __copy = false,
        __index = class_index,
        __newindex = class_newindex,
        __len = settle_class
    }
    ret = setmetatable(ret,mt)
    return ret
end
function interface()
    local ret = {
        __no_include = {}
    }
    setmetatable(ret, {
        __index = function(tb,k)
            if k == "no_include" then
                return tb.__no_include
            end
            if tb.__no_include[k] then
                return tb.__no_include[k]
            end
            return tb[k]
        end
    })
    return ret
end
function setInterface(class,interface)
    for k,v in pairs(interface) do
        if k ~= "__no_include" then
            class[k] = v
        end
    end
    return class
end
function new(cls,...)
    return require(cls)(...)
end
function ctype(v)
    if type(v) ~= "table" then
        return type(v)
    else
        local mt = getmetatable(v)
        if mt then
            return (mt.__type) or type(v)
        else
            return type(v)
        end
    end
end
function copy(v)
    if type(v) ~= "table" then
        return v
    else
        local mt = getmetatable(v)
        if mt == nil then
            return deepcopy(v)
        elseif mt.__copy == false then
            return v
        elseif v.copy ~= nil then
            return v:copy()
        else
            return deepcopy(v)
        end
    end
end