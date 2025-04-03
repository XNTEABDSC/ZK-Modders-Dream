if Spring==nil then
    Spring={}
end
if Spring.Utilities==nil then
    Spring.Utilities={}
end
if not Spring.Utilities.wacky_utils then
    Spring.Utilities.wacky_utils={}
end
if not Spring.Utilities.wacky_utils.wacky_utils_include then
    local wacky_utils=Spring.Utilities.wacky_utils

    
    local function wacky_utils_include(name)
        
        VFS.Include("LuaRules/Utilities/wacky_utils/" .. name .. ".lua")
    end
    wacky_utils.wacky_utils_include=wacky_utils_include

    Spring.Utilities.wacky_utils=wacky_utils
end