VFS.Include("LuaRules/Utilities/wacky_utils/include.lua")
if not Spring.Utilities.wacky_utils.table_replace then
    local wacky_utils=Spring.Utilities.wacky_utils

    
    local common_depthmodparams = {
        quadraticCoeff = 0.0027,
        linearCoeff = 0.02,
    }
    local function selectless(t,size)
        return ((size<=#t) and t[size]) or t[#t]
    end
    local crushstrengthGen=function (size)
        return selectless({5,50,150,500,5000} ,size)
    end
    local minwaterdepthGenBoat
    local BaseGen={
        KBOT=function (size)
            return {
                footprintx = size,
                footprintz = size,
                maxwaterdepth = selectless({16,22,22,22,123} ,size),
                maxslope = 36,
                crushstrength = crushstrengthGen(size),
                depthmodparams = common_depthmodparams,
            }
        end,
        TANK=function (size)
            return {
                footprintx = size,
                footprintz = size,
                slopemod = 20,
                maxwaterdepth = selectless({22,22,22,22,123} ,size),
                maxslope = 18,
                crushstrength = crushstrengthGen(size),
                depthmodparams = common_depthmodparams,
            }
        end,
        HOVER=function (size)
            return {
                footprintx = size,
                footprintz = size,
                maxslope = 18,
                maxwaterdepth = 5000,
                slopemod = 30,
                crushstrength = crushstrengthGen(size),
            }
        end,
        BOAT = function(size)
            return {
                footprintx = size,
                footprintz = size,
                minwaterdepth = selectless({5,5,5,5,15} ,size),
                crushstrength = 5000,
            }
        end
    }
    local PrefixDo={
        A=function (t)
            t.maxwaterdepth = 5000
            t.depthmod = 0
            t.depthmodparams=nil
        end,
        T=function (t)
            t.maxslope = 70
        end,
        U=function (t)
            t.subMarine=1
        end,
        B=function (t,b,s)
            if b=="HOVER" then
                t.maxslope = 36
            end
        end,
        S=function (t)
            t.maxwaterdepth=t.maxwaterdepth/2
            t.crushstrength=t.crushstrength/4
        end
    }
    function wacky_utils.MoveDef_CanGen(md)
        Spring.Echo("MoveDefGen Evaluating " .. md)
        local basetyl,basetyr
        for key, _ in pairs(BaseGen) do
            basetyl,basetyr=string.find(md,key)
            if basetyl then
                break
            end
        end
        if basetyl and basetyr then
            local prefixs=string.sub(md,1,basetyl-1)
            local baset=string.sub(md,basetyl,basetyr)
            local sizestr=string.sub(md,basetyr+1)
            local size=tonumber(sizestr)
            if not size then
                Spring.Echo("MoveDefGen Evaluate no size")
                return false
            end
            for i=1,string.len(prefixs) do
                local prefix=string.sub(prefixs,i,i)--prefixs[i]
                if prefix==nil then
                    Spring.Echo("MoveDefGen Evaluate odd nil prefix " .. tostring( prefix) .. " from " .. tostring( prefixs) .. " at " .. i)
                elseif not PrefixDo[prefix] then
                    Spring.Echo("MoveDefGen Evaluate bad prefix " .. prefix)
                    return nil
                end
            end
            Spring.Echo("MoveDefGen Evaluate Result: ".. baset , size,prefixs)
            return baset,size,prefixs
        else
            Spring.Echo("MoveDefGen Evaluate no base")
        end
        return nil
    end
    ---@param baset string
    ---@param size number
    ---@param prefixs string
    ---@return table
    function wacky_utils.MoveDef_TryGen(baset,size,prefixs)
        Spring.Echo(string.format("MoveDefGen Generating base: %s, size: %s, prefixs: %s", tostring(baset), tostring(size), tostring(prefixs)))
        local movedef=BaseGen[baset](size)
        Spring.Echo(string.format("MoveDefGen Generating prefixs len: %s",tostring(prefixs:len())))
        for i=1,string.len(prefixs) do
            local prefix=string.sub(prefixs,i,i)
            Spring.Echo(string.format("MoveDefGen Applying Prefix: %s",tostring(prefix)))
            PrefixDo[prefix](movedef,baset,size)
        end
        return movedef
    end

    Spring.Utilities.wacky_utils=wacky_utils
end