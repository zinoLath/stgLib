--------------------------------------------------------------------------------
--- Debug UI
--- 璀境石
--------------------------------------------------------------------------------

---@class lstg.debug
local M = {}

--------------------------------------------------------------------------------

local imgui_exist, imgui = pcall(require, "imgui")

---@param vkey number
---@return fun():boolean
function M.KeyDownTrigger(vkey)
    local _last_state = false
    local _state = false
    return function ()
        _state = lstg.GetKeyState(vkey)
        if not _last_state and _state then
            _last_state = _state
            return true
        else
            _last_state = _state
            return false
        end
    end
end

local F1_trigger = M.KeyDownTrigger(KEY.F1)
local F2_trigger = M.KeyDownTrigger(KEY.F3)

-- global cheat = false

local b_show_all = true
local b_show_menubar = false

local b_show_demo_window = false
local b_show_memuse_window = false
local b_show_framept_window = false
local b_show_testinput_window = false
local b_show_resmgr_window = false

function M.update()
    if imgui_exist then
        local flag = false
        if b_show_all then
            flag = flag or b_show_menubar
            flag = flag or b_show_demo_window
            flag = flag or b_show_memuse_window
            flag = flag or b_show_framept_window
            flag = flag or b_show_testinput_window
            flag = flag or b_show_resmgr_window
        end
        imgui.backend.NewFrame(flag)
    end
end

function M.layout()
    if F1_trigger() then
        b_show_all = not b_show_all
    end
    if F2_trigger() then
        b_show_menubar = not b_show_menubar
    end
    if imgui_exist then
        imgui.ImGui.NewFrame()
        if b_show_all then
            if b_show_menubar then
                if imgui.ImGui.BeginMainMenuBar() then
                    if imgui.ImGui.BeginMenu("Player") then
                        if imgui.ImGui.MenuItem("Cheat", nil, cheat) then cheat = not cheat end
                        imgui.ImGui.EndMenu()
                    end
                    if imgui.ImGui.BeginMenu("Reload") then
                        -- 添加自己的按钮
                        --if imgui.ImGui.MenuItem("example") then lstg.DoFile("example.lua") end
                        imgui.ImGui.EndMenu()
                    end
                    if imgui.ImGui.BeginMenu("Tool") then
                        if imgui.ImGui.MenuItem("Memory Usage", nil, b_show_memuse_window) then b_show_memuse_window = not b_show_memuse_window end
                        if imgui.ImGui.MenuItem("Frame Statistics", nil, b_show_framept_window) then b_show_framept_window = not b_show_framept_window end
                        if imgui.ImGui.MenuItem("Test Input", nil, b_show_testinput_window) then b_show_testinput_window = not b_show_testinput_window end
                        if imgui.ImGui.MenuItem("Resource Manager", nil, b_show_resmgr_window) then b_show_resmgr_window = not b_show_resmgr_window end
                        if imgui.ImGui.MenuItem("Demo", nil, b_show_demo_window) then b_show_demo_window = not b_show_demo_window end
                        imgui.ImGui.EndMenu()
                    end
                    imgui.ImGui.EndMainMenuBar()
                end
            end
            
            if b_show_demo_window then
                b_show_demo_window = imgui.ImGui.ShowDemoWindow(b_show_demo_window)
            end
            if b_show_memuse_window and imgui.backend.ShowMemoryUsageWindow then
                b_show_memuse_window = imgui.backend.ShowMemoryUsageWindow(b_show_memuse_window)
            end
            if b_show_framept_window and imgui.backend.ShowFrameStatistics then
                b_show_framept_window = imgui.backend.ShowFrameStatistics(b_show_framept_window)
            end
            
            if b_show_testinput_window and imgui.backend.ShowTestInputWindow then
                b_show_testinput_window = imgui.backend.ShowTestInputWindow(b_show_testinput_window)
            end

            if b_show_resmgr_window and imgui.backend.ShowResourceManagerDebugWindow then
                b_show_resmgr_window = imgui.backend.ShowResourceManagerDebugWindow(b_show_resmgr_window)
            end
        end
        imgui.ImGui.EndFrame()
    end
end

function M.draw()
    if imgui_exist then
        if b_show_all then
            imgui.ImGui.Render()
            imgui.backend.RenderDrawData()
        end
    end
end

return M
