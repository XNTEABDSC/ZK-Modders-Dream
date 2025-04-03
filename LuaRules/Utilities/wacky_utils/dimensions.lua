VFS.Include("LuaRules/Utilities/wacky_utils/include.lua")
if not Spring.Utilities.wacky_utils.GetDimensions then
    local wacky_utils=Spring.Utilities.wacky_utils
    VFS.Include("LuaRules/Utilities/wacky_utils/str_explode.lua")
    local str_explode=Spring.Utilities.wacky_utils.str_explode

    function wacky_utils.GetDimensions(str)
        if not str then
            return nil
        end
        local dimensionsStr = str_explode(" ", str)
        -- string conversion (required for MediaWiki export)
        if dimensionsStr then
            local dimensions = {}
            for i,v in pairs(dimensionsStr) do

                dimensions[i] = tonumber(v)
            end
            return dimensions
        else
            return nil
            --error("Fail to GetDimensions on " .. scale)
        end
    end

    function wacky_utils.ToDimensions(v3)
        return tostring(v3[1]) .. " " .. tostring(v3[2]) .. " " .. tostring(v3[3])
    end

    Spring.Utilities.wacky_utils=wacky_utils
end