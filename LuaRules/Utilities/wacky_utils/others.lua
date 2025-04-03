VFS.Include("LuaRules/Utilities/wacky_utils/include.lua")
if not Spring.Utilities.wacky_utils.lowerkeys then
    local wacky_utils=Spring.Utilities.wacky_utils

    
    local function lowerkeys(t)
        local tn = {}
        if type(t) == "table" then
            for i,v in pairs(t) do
                local typ = type(i)
                if type(v)=="table" then
                    v = lowerkeys(v)
                end
                if typ=="string" then
                    tn[i:lower()] = v
                else
                    tn[i] = v
                end
            end
        end
        return tn
    end
    wacky_utils.lowerkeys=lowerkeys
    local function lowervalues(t)
        for key, value in pairs(t) do
            if type(value)=="string" then
                t[key]=value:lower()
            end
        end
        return t
    end
    wacky_utils.lowervalues=lowervalues
    local function round_to(n,base)
        n = n/base
        n = math.ceil(n+0.5)
        n = n*base
        return n
    end
    wacky_utils.round_to=round_to
    local function list_to_set(list,value)
        if value==nil then
            value=true
        end
        local set={}
        for _, k in pairs(list) do
            set[k]=value
        end
        return set
    end
    wacky_utils.list_to_set=list_to_set

    Spring.Utilities.wacky_utils=wacky_utils
end