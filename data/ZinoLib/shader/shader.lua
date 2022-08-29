local path = GetCurrentScriptDirectory()
POSTEFF_PATH = path
Print("============LOADING SHADERS=============")
--LoadFX("gradient_map_fast",path.."gradient_map_fast.glsl")
Print("==========LOADING SHADERS DONE==========")
posteff_obj = zclass(object)
local posteff_obj_push = Class(object)
CreateRenderTarget("POSTEFFRT")
function posteff_obj:init(layerb, layert, shader, attr, blend, rtname)
    self.attr = attr or {}
    self.rtname = rtname or "POSTEFFRT"
    self.layer = layert
    self.shader = shader
    self._blend = blend or ""
    self.push = New(posteff_obj_push,self,layerb)
end
function posteff_obj:render()
    PopRenderTarget(self.rtname)
    PostEffect(self.rtname,self.shader,self._blend,self.attr)
end
function posteff_obj:del()
    RawDel(self.push)
end
function posteff_obj:kill()
    RawKill(self.push)
end

function posteff_obj_push:init(master,layerb)
    self.master = master
    self.rtname = self.master.rtname
    self.layer = layerb
end
function posteff_obj_push:render()
    PushRenderTarget(self.master.rtname)
end