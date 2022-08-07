local M = {}
TextManager = M --this is the table youll access
M.current_lang = "english"
M.langs = {}
local function getRecursiveText(tb,ret,level)
    ret = ret or {}
    level = level or ""
    for k,v in pairs(tb) do
        if type(v) ~= "table" then
            ret[level .. k] = v
        else
            getRecursiveText(v,ret,level .. tostring(k) .. "." )
        end
    end
    return ret
end
--- Adds a text pack to the text manager, if there is a table, the keys will be linked and separated by .
--- (example: { foo = { bar = "test" } } will have its test at "foo.bar"). The name argument is set to put a prefix
--- before all keys (M:addTextPack("english", { foo = "bar" }, "test") will have "bar" at "test.foo"
---@param language string
---@param pack table
---@param name string @optional
function M:addTextPack(language,pack,name)
    if not self.langs[language] then
        self.langs[language] = {}
    end
    if name then
        name = name .. "."
    end
    getRecursiveText(pack,self.langs[language],name)
end
--- Sets the current language
---@param language string
function M:setLanguage(language)
    self.current_lang = language
end
--- Gets a determined key
---@param key any
function M:getText(key)
    return self.langs[self.current_lang][key]
end