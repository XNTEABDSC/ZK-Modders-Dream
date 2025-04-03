if Spring==nil then
    Spring={}
end
if Spring.Utilities==nil then
    Spring.Utilities={}
end
if not Spring.Utilities.wacky_utils then
    local wacky_utils={}
    Spring.Utilities.wacky_utils=wacky_utils
end
VFS.Include("LuaRules/Utilities/tablefunctions.lua")

local luaFiles=VFS.DirList("LuaRules/Utilities/wacky_utils", "*.lua") or {}
for i = 1, #luaFiles do
    VFS.Include(luaFiles[i])
end
