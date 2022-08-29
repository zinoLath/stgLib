local event = lstg.EventDispatcher
local max = max
--[[
lstg.eventDispatcher:addListener('load.THlib.after', function()
    CopyImage('enemy_placeholder', 'parimg1')
end, 1, 'load enemy placeholder')
--]]
enemybase = zclass(object)
function enemybase:init(hp, nontjt, anim_set)
    self.group = nontjt and GROUP_NONTJT or GROUP_ENEMY
    self.layer = LAYER_ENEMY
    self.hp = hp
    self.maxhp = hp
    self._servants = {}
    self.dmgratio = 1
    self.protect = 0
    if anim_set then
        anim_set:attachObj(self)
    end
    self.lastdmg = 0
end
function enemybase:frame()
    if self.hp <= 0 then
        self.class.onDeath(self)
    end
    if self.animManager then
        self.animManager:update()
    end
    task.Do(self)
    self.protect = max(self.protect - 1,0)
    self.lastdmg = 0
end
function enemybase:colli(other)
    if other.dmg and self.protect == 0 then
        self.class.onDamage(self,other,other.dmg * self.dmgratio)
        if self._master and self._dmg_transfer and IsValid(self._master) then
            self._master.class.onDamage(self._master,other,other.dmg * self._dmg_transfer)
        end
        if not other.killflag then
            Kill(other)
        end
    end
end
function enemybase:kill()
    KillServants(self)
end
function enemybase:del()
    DelServants(self)
end
function enemybase:render()
    if self.animManager then
        self.animManager:render()
    else
        DefaultRenderFunc(self)
    end
end
function enemybase:setBaseHP(newhp)
    self.hp = newhp
    self.maxhp = newhp
end
function enemybase:setHP(newhp)
    self.hp = newhp
end
function enemybase:onDamage(other,dmg)
    self.lastdmg = dmg
    self.hp = self.hp - dmg
end
function enemybase:onDeath()
    Kill(self)
end

enemy = zclass(enemybase)
function enemy:init(anim_set,hp,clear_bul,auto_delete,nontjt)
    enemybase.init(self,hp,nontjt,anim_set)
    self.img = "parimg1"
    self.clear_bul = clear_bul
    self.bound = auto_delete
    self.drop = {}
end
function enemy:onDeath()
    Kill(self)
    item.DropItem(self.x,self.y,self.drop)
    if self.clear_bullet then
        New(bullet_killer, self.x, self.y, false)
    end
end