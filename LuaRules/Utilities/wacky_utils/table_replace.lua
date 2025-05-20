VFS.Include("LuaRules/Utilities/wacky_utils/include.lua")
if not Spring.Utilities.wacky_utils.table_replace then
    local wacky_utils=Spring.Utilities.wacky_utils


    ---Put things in tweaks to t at same key. <br/>
    ---for k, v in pairs(tweaks) do <br/>
    ---if type(v)=="function" then t[k]=v(t[k]) <br/>
    ---elseif (vt == "table") and type(t[k]) == "table" then wacky_utils.table_replace(v)(t[k]) <br/>
    ---else t[k] = v end end<br/>
    ---@param tweaks table
    ---@return fun(t:table):table
    local function table_replace(tweaks)
        local function replace(t)
            for k, v in pairs(tweaks) do
                local tkv=t[k]
                local vt=type(v)
                if vt=="function" then
                    t[k]=v(tkv)
                elseif (vt == "table") and type(tkv) == "table" then
                    wacky_utils.table_replace(v)(tkv)
                else
                    t[k] = v
                end
            end
        end
        return replace
    end
    wacky_utils.table_replace=table_replace

    Spring.Utilities.wacky_utils=wacky_utils
end

return Spring.Utilities.wacky_utils.table_replace