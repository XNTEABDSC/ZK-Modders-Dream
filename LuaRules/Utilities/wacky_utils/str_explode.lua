VFS.Include("LuaRules/Utilities/wacky_utils/include.lua")
if not Spring.Utilities.wacky_utils.str_explode then
    local wacky_utils=Spring.Utilities.wacky_utils

    
    function wacky_utils.str_explode(div, str)
        if div == '' then
            return nil
        end
        local pos, arr = 0, {}
        -- for each divider found
        for st, sp in function() return string.find(str, div, pos, true) end do
            arr[#arr+1] = string.sub(str, pos, st - 1)-- Attach chars left of current divider
            
            pos = sp + 1 -- Jump past current divider
        end
        if pos<=string.len(str) then
            arr[#arr+1] = string.sub(str,pos)-- Attach chars right of last divider
        end
        return arr
    end

    Spring.Utilities.wacky_utils=wacky_utils
end