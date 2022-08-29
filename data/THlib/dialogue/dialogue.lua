local M = Class()
local path = GetCurrentScriptDirectory()
CopyImage("dialogue_bound_viewer", "white")
dialogue_font = BMF:loadFont("philosopher",font_path)
dialogue_manager = M
sample_dialogue =
[[
<dialogue>
	<meta>
		<speaker id="kage1" name="Kagerou" position="-200,0" flip="false"/>
		<speaker id="kage2" name="Kagerou" position="200,0" flip="true"/>
	</meta>
	<action>
        <message speaker="kage1">
            Lorem ipsum dolor sit amet, consectetur adipiscing elit. Quisque sagittis
            pretium nulla quis ultrices. Praesent sollicitudin, ipsum ac
            ornare egestas, enim nisi tempus metus, quis elementum leo metus vitae odio.
            Aenean dapibus sapien vitae nisi sceleris que venenatis. Phasellus mi felis,
            accumsan maximus vestibulum a, ultrices non odio. Nulla porta mi sit amet
            fringilla egestas.
        </message>
	</action>
</dialogue>
]]

LoadImageFromFile("kagerou", path .. "kage_port.png",true)
LoadImageFromFile("textbox", path .. "textbox.png",true)
LoadImageFromFile("kage_title_R", path .. "kagerou_right.png",true)
LoadImageFromFile("kage_title_L", path .. "kagerou_left.png",true)
M.tag_list = {}
M.tag_list.message = {}
---Make it update the objects text render command
function M.tag_list.message.init(obj,actiondata,id,xml)
    local data = actiondata
    local state = {
        font = dialogue_font,
        scale = 0.4,
        --monospace = 70,
        --monospace_exception = {}
    }
    data.render_pool = BMF:pool(xml,state,obj.width,10,30)
end
function M.tag_list.message.co(obj,id,actiondata)
    obj.render_pool = actiondata.render_pool
    while(true) do
        --Print(obj.render_pool)
        coroutine.yield()
    end
end
function M:init(data)
    self.width = 2000
    if type(data) == "string" then
        local handler = xml2lua.dom:new()
        local parser = xml2lua.parser(handler)
        parser:parse(data)
        data = handler.root
    end
    self.meta = data._children[1]
    self.speakers = {}
    for k,v in ipairs(self.meta) do
        if v._type == "speaker" then
            self.speakers[v._attr.id] = v._attr
        end
    end
    ---make a table for each action, and then run it on a coroutine
    self.actions = data._children[2]._children
    self.actiondata = {}
    for k,v in ipairs(self.actions) do
        if M.tag_list[v._name] then
            self.actiondata[k] = {}
            self.actiondata[k].co_func = M.tag_list[v._name].co
            M.tag_list[v._name].init(self,self.actiondata[k],k,v)
        end
    end
    self.actionid = 1
    self.co = coroutine.create(self.actiondata[self.actionid].co_func)
    self.layer = LAYER_UI+100
    self.bound = false
    Print("Nicki")
end
function M:frame()
    if self.co then
        if coroutine.status(self.co) ~= "dead" then
            local C, E = coroutine.resume(self.co,self,self.actionid,self.actiondata[self.actionid])
            --Print(self.render_pool)
            if(not C)then
                error(E)
            end
        end
    end
end
function M:render()
    SetViewMode("ui")
    local x,y = screen.width/2,200
    Render("textbox",x,y,0,2,2)
    if self.render_pool then
        local scale = 1
        RenderRect("dialogue_bound_viewer", x-600, x-600+self.width*scale*0.5, y-0,y+50)
        BMF:renderPool(self.render_pool,x-600,y+50,scale,nil,self.timer)
    end
    SetViewMode("world")
end
function M:nextAction()
    self.actionid = self.actionid + 1
    self.co = coroutine.create(self.actiondata[self.actionid].co_func)
end