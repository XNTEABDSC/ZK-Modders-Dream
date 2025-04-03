VFS.Include("LuaRules/Utilities/wacky_utils/include.lua")
if not Spring.Utilities.wacky_utils.modify_all then
    local wacky_utils=Spring.Utilities.wacky_utils

    
    ---t[key]=modifyfn(t[key],value,key,t)
    ---@param t table
    ---@param toChange {[string]:any}
    ---@param modifyfn fun(value:any,tochange:any,key:string,t:table):any
    local function modify_all(t,toChange,modifyfn)
        for key,value in pairs(toChange) do
            local key2=key
            local tbvalue=t[key2]
            if not tbvalue then
                key2=string.lower(key2)
                tbvalue=t[key2]
            end
            t[key2]=modifyfn(tbvalue,value,key,t)
        end
    end
    wacky_utils.modify_all=modify_all

    Spring.Utilities.wacky_utils=wacky_utils
end