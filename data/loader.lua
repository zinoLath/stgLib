--- Smart Lua Loader for use in `require()`
--
--- Designed for use in LuaSTG, but can be adapted to other projects if necessary.
--
--- Features:
--- - Relative path loading
---   - Stores modules by their fully qualified names
---     (no need to worry about loading a module twice)
---   - Start with a dot to indicate a relative path
---   - Use "<" to go back up levels (only at the beginning)
--- - Get the current file path from `package.current_path`
---   (relative to the current working directory)
--- - Get the current module name from `package.current_module` (fully qualified name)

--- Configuration and state for the Smart Lua Loader
package.sll = {
    --- Configuration

    --- Path prefixes to search.
    prefixes = {
        "data/",
    },

    --- Allowed suffixes to a path.
    --- "?" is substituted with the module name.
    --- The format of this table is [suffix] = whether to append "?" to the current module stack.
    suffixes = {
        ["/?.lua"] = false,
        ["/?/init.lua"] = true,
    },

    --- State

    module_stack = {},
    current_prefix = nil,

    loaded = {},
}
local sll = package.sll

package.current_path = ""
package.current_module = ""

function sll.findPath(modname,extension)
    local msg = ""
    local relative = modname:sub(1, 1) == "." or modname:sub(1, 1) == "<"

    local up = modname:match("^<*"):len()

    local parsed = {}
    for mod in modname:gmatch("([%a_][%w_]*)%.?") do
        table.insert(parsed, mod)
    end
    if not relative then
        for _, prefix in ipairs(sll.prefixes) do
            for suffix, keep_last in pairs(sll.suffixes) do
                suffix = suffix:gsub(".lua",extension)
                local trypath =
                    prefix ..
                        table.concat(parsed, "/", 1, #parsed - 1) ..
                        suffix:gsub("%?", parsed[#parsed])
                msg = msg .. ("\n\tno file \"%s\""):format(trypath)
                if lstg.FileManager.FileExist(trypath, true) then
                    return trypath
                end
            end
        end
    else
        local m = #sll.module_stack
        local current_module_idx = m - up
        if current_module_idx <= 0 then
            if up > 1 then
                error(
                        "Relative module index went up too far!\n" ..
                                ('Expected at most %d levels up ("%s"), got %d ("%s")'):format(
                                        m - 1, ("<"):rep(m - 1), up, ("<"):rep(up)
                                )
                )
            else
                error(
                        "Cannot find a module relative to the root!\n" ..
                                "Use an absolute path instead."
                )
            end
        end
        for suffix, keep_last in pairs(sll.suffixes) do
            suffix = suffix:gsub(".lua",extension)
            local s = ""
            if current_module_idx > 0 then
                s = "/"
            end
            local trypath = sll.current_prefix ..
                    table.concat(sll.module_stack, "/", 1, current_module_idx) .. s ..
                    table.concat(parsed, "/", 1, #parsed - 1) .. "/" ..
                    suffix:gsub("(%?)", parsed[#parsed])
            msg = msg .. ("\n\tno file '%s'"):format(trypath)
            if lstg.FileManager.FileExist(trypath, true) then
                local add_len = #parsed - 1
                if keep_last then
                    add_len = #parsed
                end
                return trypath
            end
        end
    end
    return msg
end
function sll.loader(modname)
    local msg = ""
    local relative = modname:sub(1, 1) == "." or modname:sub(1, 1) == "<"

    local up = modname:match("^<*"):len()

    local parsed = {}
    for mod in modname:gmatch("([%a_][%w_]*)%.?") do
        table.insert(parsed, mod)
    end

    if relative then
        local m = #sll.module_stack
        local current_module_idx = m - up
        if current_module_idx <= 0 then
            if up > 1 then
                error(
                        "Relative module index went up too far!\n" ..
                                ('Expected at most %d levels up ("%s"), got %d ("%s")'):format(
                                        m - 1, ("<"):rep(m - 1), up, ("<"):rep(up)
                                )
                )
            else
                error(
                        "Cannot find a module relative to the root!\n" ..
                                "Use an absolute path instead."
                )
            end
        end
        local full_modname =
        table.concat(sll.module_stack, ".", 1, current_module_idx) ..
                "." ..
                table.concat(parsed, ".") -- because modname might start with "<"
        if sll.loaded[full_modname] then
            return function()
                return sll.loaded[full_modname]
            end
        end
        for suffix, keep_last in pairs(sll.suffixes) do
            local s = ""
            if current_module_idx > 0 then
                s = "/"
            end
            local trypath =
            sll.current_prefix ..
                    table.concat(sll.module_stack, "/", 1, current_module_idx) .. s ..
                    table.concat(parsed, "/", 1, #parsed - 1) .. "/" ..
                    suffix:gsub("(%?)", parsed[#parsed])
            msg = msg .. ("\n\tno file '%s'"):format(trypath)
            if lstg.FileManager.FileExist(trypath, true) then
                local add_len = #parsed - 1
                if keep_last then
                    add_len = #parsed
                end
                return function()
                    local last_module_stack = sll.module_stack
                    local last_modname = package.current_module
                    local last_path = package.current_path
                    sll.module_stack = { unpack(sll.module_stack, 1, current_module_idx) }
                    for i = 1, add_len do
                        table.insert(sll.module_stack, parsed[i])
                    end
                    package.current_module = full_modname
                    package.current_path = trypath
                    local result = lstg.DoFile(trypath)
                    sll.loaded[full_modname] = result or true
                    sll.module_stack = last_module_stack
                    package.current_module = last_modname
                    package.current_path = last_path
                    return result
                end
            end
        end
    else
        if sll.loaded[modname] then
            return function()
                return sll.loaded[modname]
            end
        end
        for _, prefix in ipairs(sll.prefixes) do
            for suffix, keep_last in pairs(sll.suffixes) do
                local trypath =
                prefix ..
                        table.concat(parsed, "/", 1, #parsed - 1) ..
                        suffix:gsub("%?", parsed[#parsed])
                msg = msg .. ("\n\tno file \"%s\""):format(trypath)
                if lstg.FileManager.FileExist(trypath, true) then
                    local add_len = #parsed - 1
                    if keep_last then
                        add_len = #parsed
                    end
                    return function()
                        local last_prefix = sll.current_prefix
                        local last_module_stack = sll.module_stack
                        local last_modname = package.current_module
                        local last_path = package.current_path
                        sll.current_prefix = prefix
                        sll.module_stack = { unpack(parsed, 1, add_len) }
                        package.current_module = modname
                        package.current_path = trypath
                        local result = lstg.DoFile(trypath)
                        sll.loaded[modname] = result or true
                        sll.current_prefix = last_prefix
                        sll.module_stack = last_module_stack
                        package.current_module = last_modname
                        package.current_path = last_path
                        return result
                    end
                end
            end
        end
    end
    return msg
end

--- Replace Lua default loader
---@param modname string
package.loaders[2] =

-- Remove LuaSTG default loader
table.remove(package.loaders)