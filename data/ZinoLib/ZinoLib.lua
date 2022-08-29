local path = GetCurrentScriptDirectory()
local miscpath = path.."misc\\"
Vector = Include(miscpath..'BrineVector.lua')
Include(miscpath..'Stack.lua')
Include(miscpath..'EventDispatcher.lua')
Include(miscpath..'MiscFunctions.lua')
Include(miscpath..'MulticastDelegate.lua')
Include(miscpath..'TextManager.lua')
Include(miscpath..'VertexRenderer.lua')
Include(miscpath..'PatternObject.lua')
Include(path..'BMF\\font.lua') --TO REFACTOR
Include(path..'animation\\main.lua')
Include(path..'particle\\particle.lua')
Include(path..'menu\\main.lua') --TO REFACTOR
--Include(path..'shader\\shader.lua')
Include(path..'xml\\xml2lua.lua')