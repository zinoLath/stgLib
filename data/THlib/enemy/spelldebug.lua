function SpellDebugger(bossname, spellid, playerc)
    local bossc = _editor_class[bossname] or bossname
    playerc = playerc or reimuA_player
    local s = stage.New('init', true, false)
    s.group = {
        number = 1,
        title = 'menu'
    }
    s.number = 1
    function s:init()
        stage.DefaultInit(self)
        New(playerc)
        task.NewHashed(self, "main", function()
            New(river_background)
            local ref = New(bossc,{bossc.cards[spellid]})
            ref.x, ref.y = 0,120
            while not IsValid(ref) do
                task.Wait(1)
            end
            task.Wait(60)
        end)
    end
    s.render = stage.group.render
    s.frame = stage.group.frame
end