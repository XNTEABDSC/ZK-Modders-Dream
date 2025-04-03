VFS.Include("LuaRules/Utilities/wacky_utils/include.lua")
if not Spring.Utilities.wacky_utils.loop_until_finish_all_table then
    local wacky_utils=Spring.Utilities.wacky_utils

    local function loop_until_finish_all_list(values,fn)
        local values_unfinished={}
        while #values>0 do
            local c=#values
            local c2=0
            for i=1,c do
                local value=values[i]
                if fn(value) then

                else
                    c2=c2+1
                    values_unfinished[c2]=value
                end
            end
            if #values==#values_unfinished then
                return values_unfinished
            else
                values=values_unfinished
                values_unfinished={}
            end
        end
        return nil
    end
    wacky_utils.loop_until_finish_all_list=loop_until_finish_all_list
    local function loop_until_finish_all_table(values,fn)
        local values_unfinished={}
        while next(values) do
            local reduced=false
            for key,value in pairs(values) do
                local res=fn(key,value)
                values_unfinished[key]=res
                if not res then
                    reduced=true
                end
            end
            if not reduced then
                return values_unfinished
            else
                values=values_unfinished
                values_unfinished={}
            end
        end
        return nil
    end
    wacky_utils.loop_until_finish_all_table=loop_until_finish_all_table
    Spring.Utilities.wacky_utils=wacky_utils
end