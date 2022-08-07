local base = GetCurrentScriptDirectory()
local path = base.."misc\\"
Vector = Include(path..'BrineVector.lua')
Include(path..'Stack.lua')
Include(path..'MiscFunctions.lua')
Include(path..'MulticastDelegate.lua')
Include(path..'TextManager.lua')
ZQuads = Include(path..'VertexRenderer.lua')
--Include(path..'PatternObject.lua')
--Include(path..'PatternObject2.lua') TO REFACTOR
path = base
Include(path..'BMF\\font.lua') --TO REFACTOR
ZAnim = Include(path..'animation\\main.lua')
--Include(path..'player\\player.lua') --TO REFACTOR
Include(path..'menu\\main.lua') --TO REFACTOR
--Include(path..'shader\\shader.lua')
Include(path..'xml\\xml2lua.lua')