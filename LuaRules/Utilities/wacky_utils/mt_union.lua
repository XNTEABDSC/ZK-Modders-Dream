VFS.Include("LuaRules/Utilities/wacky_utils/include.lua")
if not Spring.Utilities.wacky_utils.mt_union then
    local wacky_utils=Spring.Utilities.wacky_utils

    
    local function mt_union(a,b)
        local c={}
        setmetatable(c,{__index=function (t,k)
            local res=a[k]
            if res==nil then
                res=b[k]
            end
            return res
        end,__newindex=function (t,k,v)
            if a[k]~=nil then
                a[k]=v
            elseif b[k]~=nil then
                b[k]=v
            else
                a[k]=v
            end
        end})
        --setmetatable(a,{__index=b})
        return c
    end
    wacky_utils.mt_union=mt_union

    local function mt_chain(a,b)
        local c={}
        setmetatable(c,{
            __index=function (t, k)
                local i=#a
                if k<=i then
                    return a[k]
                else
                    return b[k-i]
                end
            end,
            __newindex=function (t,k,v)
                local i=#a
                if k<=i then
                    a[k]=v
                else
                    b[k-i]=v
                end
                
            end
        })
    end

    wacky_utils.mt_chain=mt_chain

    Spring.Utilities.wacky_utils=wacky_utils
end