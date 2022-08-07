---=====================================
---stagegroup|replay|pausemenu system
---extra game loop
---=====================================

----------------------------------------
---ext加强库

---@class ext @额外游戏循环加强库
ext = {}

local extpath = "THlib/ext/"

DoFile(extpath .. "ext_pause_menu.lua")
 --暂停菜单和暂停菜单资源
DoFile(extpath .. "ext_replay.lua")
 --CHU爷爷的replay系统以及切关函数重载
DoFile(extpath .. "ext_stage_group.lua")
 --关卡组

ext.replayTicker = 0
 --控制录像播放速度时有用
ext.slowTicker = 0
 --控制时缓的变量
ext.time_slow_level = {1, 2, 3, 4}
 --60/30/20/15 4个程度
ext.pause_menu = ext.pausemenu()
 --实例化的暂停菜单对象，允许运行时动态更改样式

---重置缓速计数器
function ext.ResetTicker()
    ext.replayTicker = 0
    ext.slowTicker = 0
end

---获取暂停菜单发送的命令
---@return string
function ext.GetPauseMenuOrder()
    return ext.pause_menu_order
end

---发送暂停菜单的命令，命令有以下类型：
---'Continue'
---'Return to Title'
---'Quit and Save Replay'
---'Give up and Retry'
---'Restart'
---'Replay Again'
---@param msg string
function ext.PushPauseMenuOrder(msg)
    ext.pause_menu_order = msg
end

----------------------------------------
---extra user function

function GameStateChange()
end

---设置标题
function ChangeGameTitle()
    local mod = setting.mod and #setting.mod > 0 and setting.mod
    local ext =
        table.concat(
        {
            string.format("FPS=%.1f", GetFPS()),
            "OBJ=" .. GetnObj(),
            gconfig.window_title
        },
        " | "
    )
    if mod then
        SetTitle(mod .. " | " .. ext)
    else
        SetTitle(ext)
    end
end

---切关处理
function ChangeGameStage()
    ResetWorld()
    ResetWorldOffset()
     --by ETC，重置world偏移

    lstg.ResetLstgtmpvar()
     --重置lstg.tmpvar
    ex.Reset()
     --重置ex全局变量

    if lstg.nextvar then
        lstg.var = lstg.nextvar
        lstg.nextvar = nil
    end

    -- 初始化随机数
    if lstg.var.ran_seed then
        --Print('RanSeed',lstg.var.ran_seed)
        ran:Seed(lstg.var.ran_seed)
    end

    --刷新最高分
    if not stage.next_stage.is_menu then
        if scoredata.hiscore == nil then
            scoredata.hiscore = {}
        end
        lstg.tmpvar.hiscore = scoredata.hiscore[stage.next_stage.stage_name .. "@" .. tostring(lstg.var.player_name)]
    end

    --切换关卡
    stage.current_stage = stage.next_stage
    stage.next_stage = nil
    stage.current_stage.timer = 0
    stage.current_stage:init()
end

---获取输入
function GetInput()
    if stage.next_stage then
        KeyStatePre = {}
    elseif ext.pause_menu:IsKilled() then
        -- 刷新KeyStatePre
        for k, _ in pairs(setting.keys) do
            KeyStatePre[k] = KeyState[k]
        end
    end

    -- 不是录像时更新按键状态
    if not ext.replay.IsReplay() then
        for k, v in pairs(setting.keys) do
            KeyState[k] = GetKeyState(v)
        end
    end

    if ext.pause_menu:IsKilled() then
        if ext.replay.IsRecording() then
            -- 录像模式下记录当前帧的按键
            replayWriter:Record(KeyState)
        elseif ext.replay.IsReplay() then
            -- 回放时载入按键状态
            replayReader:Next(KeyState)
        end
    end
end

---行为帧动作(和游戏循环的帧更新分开)
function DoFrame()
    --标题设置
    ChangeGameTitle()
    --刷新输入
    GetInput()
    --切关处理
    if stage.next_stage then
        --切关时清空资源和回收对象
        if stage.current_stage then
            stage.current_stage:del()
            task.Clear(stage.current_stage)
            if stage.preserve_res then
                stage.preserve_res = nil
            else
                RemoveResource "stage"
            end
            ResetPool()
        end
        ChangeGameStage()
    end
    --stage和object逻辑
    if GetCurrentSuperPause() <= 0 or stage.nopause then
        ex.Frame()
        task.Do(stage.current_stage)
        stage.current_stage:frame()
        stage.current_stage.timer = stage.current_stage.timer + 1
    end
    ObjFrame()
    if GetCurrentSuperPause() <= 0 or stage.nopause then
        BoundCheck()
    end
    if GetCurrentSuperPause() <= 0 then
        CollisionCheck(GROUP_PLAYER, GROUP_ENEMY_BULLET)
        CollisionCheck(GROUP_PLAYER, GROUP_ENEMY)
        CollisionCheck(GROUP_PLAYER, GROUP_INDES)
        CollisionCheck(GROUP_ENEMY, GROUP_PLAYER_BULLET)
        CollisionCheck(GROUP_NONTJT, GROUP_PLAYER_BULLET)
        CollisionCheck(GROUP_ITEM, GROUP_PLAYER)
        --由OLC添加，可用于自机bomb
        CollisionCheck(GROUP_SPELL, GROUP_ENEMY)
        CollisionCheck(GROUP_SPELL, GROUP_NONTJT)
        CollisionCheck(GROUP_SPELL, GROUP_ENEMY_BULLET)
        CollisionCheck(GROUP_SPELL, GROUP_INDES)
        --由OLC添加，用于检查与自机碰撞，可以做？？？（好吧其实我不知道能做啥= =
        CollisionCheck(GROUP_CPLAYER, GROUP_PLAYER)
    end
    UpdateXY()
    AfterFrame()
end

---缓速和加速
function DoFrameEx()
    if ext.replay.IsReplay() then
        --播放录像时
        ext.replayTicker = ext.replayTicker + 1
        ext.slowTicker = ext.slowTicker + 1
        if GetKeyState(setting.keysys.repfast) then
            for _ = 1, 4 do
                DoFrame(true, false)
                ext.pause_menu_order = nil
            end
        elseif GetKeyState(setting.keysys.repslow) then
            if ext.replayTicker % 4 == 0 then
                DoFrame(true, false)
                ext.pause_menu_order = nil
            end
        else
            if lstg.var.timeslow then
                local tmp = min(4, max(1, lstg.var.timeslow))
                if ext.slowTicker % (ext.time_slow_level[tmp]) == 0 then
                    DoFrame(true, false)
                end
            else
                DoFrame(true, false)
            end
            ext.pause_menu_order = nil
        end
    else
        --正常游戏时
        ext.slowTicker = ext.slowTicker + 1
        if lstg.var.timeslow and lstg.var.timeslow > 0 then
            local tmp = min(4, max(1, lstg.var.timeslow))
            if ext.slowTicker % (ext.time_slow_level[tmp]) == 0 then
                DoFrame(true, false)
            end
        else
            DoFrame(true, false)
        end
    end
end

function BeforeRender()
end

function AfterRender()
    --暂停菜单渲染
    local state = 0
    ext.pause_menu:render()
end

function GameExit()
end

----------------------------------------
---extra game call-back function

local Ldebug = require("lib.Ldebug")

function FrameFunc()
    Ldebug.update()
    --重设boss ui的槽位（多boss支持）
    --boss_ui.active_count = 0
    --执行场景逻辑
    if ext.pause_menu:IsKilled() then
        --处理录像速度与正常更新逻辑
        DoFrameEx()
        --按键弹出菜单
        if (GetLastKey() == setting.keysys.menu or ext.pop_pause_menu) and (not stage.current_stage.is_menu) then
            ext.pause_menu:FlyIn()
        end
    end
    --暂停菜单更新
    ext.pause_menu:frame()
    Ldebug.layout()
    --退出游戏逻辑
    if lstg.quit_flag then
        GameExit()
    end
    return lstg.quit_flag
end

function RenderFunc()
    BeginScene()
    UpdateScreenResources()
    SetWorldFlag(1)
    BeforeRender()
    if
        stage.current_stage.timer and stage.current_stage.timer >= 0 and
            (stage.next_stage == nil or stage.next_stage.is_menu)
     then
        stage.current_stage:render()
        ObjRender()
        SetViewMode("world")
        DrawCollider()
        if Collision_Checker then
            Collision_Checker.render()
        end
    end
    AfterRender()
    Ldebug.draw()
    EndScene()
    -- 截图
    if GetLastKey() == setting.keysys.snapshot then
        lstg.LocalUserData.Snapshot()
    end
end

function FocusLoseFunc()
    --[[
    if ext.pause_menu == nil and stage.current_stage then
        if not stage.current_stage.is_menu then
            ext.pop_pause_menu = true
        end
    end
    --]]
end
