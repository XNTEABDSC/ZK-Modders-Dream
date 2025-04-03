VFS.Include("LuaRules/Utilities/wacky_utils/include.lua")
if not Spring.Utilities.wacky_utils.GetUnitLua then
    local wacky_utils=Spring.Utilities.wacky_utils

    ---get lua table of unit defined by .lua file
    local function GetUnitLua(udname)
        if not Shared then
            Shared={}
        end
        return VFS.Include("units/".. udname ..".lua")[udname]
    end
    wacky_utils.GetUnitLua=GetUnitLua

    Spring.Utilities.wacky_utils=wacky_utils
end