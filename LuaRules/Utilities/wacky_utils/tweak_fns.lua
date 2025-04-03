VFS.Include("LuaRules/Utilities/wacky_utils/include.lua")
if not Spring.Utilities.wacky_utils.unit_defs_tweak_fns then
    local wacky_utils=Spring.Utilities.wacky_utils

    VFS.Include("LuaRules/Utilities/ordered_list.lua")
    
    local unit_defs_tweak_fns=Spring.Utilities.OrderedList.New()
    wacky_utils.unit_defs_tweak_fns=unit_defs_tweak_fns
    
    local WeaponDefsTweakFns=Spring.Utilities.OrderedList.New()
    wacky_utils.weapon_defs_tweak_fns=WeaponDefsTweakFns

    local function AddFnToUnitDefsTweakFns(ordered)
        unit_defs_tweak_fns.Add(ordered)
    end
    wacky_utils.AddFnToUnitDefsTweakFns=AddFnToUnitDefsTweakFns

    local function AddFnToUnitDefsTweakFnsMut(ordered)
        Spring.Utilities.OrderedList.AddMult(unit_defs_tweak_fns,ordered)
    end
    wacky_utils.AddFnToUnitDefsTweakFnsMut=AddFnToUnitDefsTweakFnsMut

    local function RunOrderedList(OList)
        local res=OList.ForEach(function (v,k)
            Spring.Echo("Run Task: " .. k)
            if v then
                v()
            end
        end)
        if res then
            for key, value in pairs(res) do
                Spring.Echo("Warning: Not Done Task " .. key .. ", after:")
                for _, k2 in pairs(value.afters) do
                    Spring.Echo(k2)
                end
            end
        end
    end
    wacky_utils.RunOrderedList=RunOrderedList
    wacky_utils.RunUnitDefsTweakFns=function ()
        RunOrderedList(unit_defs_tweak_fns)
    end

    

    --- make "modify_" .. key .. "_begin" and "modify_" .. key .. "_end" and order<br/>
    --- they are in modify_values_begin and modify_values_end<br/>
    --- cost exclude, use modify_cost_begin modify_cost_end<br/>
    local OrderKeyGen=function (order,keys)
        local begins,ends={},{}
        for _, key in pairs(keys) do
            
            local beginstr="modify_" .. key .. "_begin"
            local endstr="modify_" .. key .. "_end"
            if not order.kvlist[beginstr] and not order.kvlist[endstr] then
                order.Add({k=beginstr,a={endstr},b="modify_values_begin"})
                order.Add({k=endstr,a="modify_values_end"})
            end
            begins[#begins+1] = beginstr
            endstr[#endstr+1] = endstr
        end
        return begins,ends
    end
    
    wacky_utils.OrderKeyGen=OrderKeyGen

    do
        local fns=unit_defs_tweak_fns
        fns.Add({k="pre_set_values"})
        fns.Add({k="default_add_build_begin",a={"default_add_build_end"}})
        fns.Add({k="default_add_build_end"})
        fns.Add({k="default_set_morph_begin",a={"default_set_morph_end"}})
        fns.Add({k="default_set_morph_end"})
        fns.Add({k="default_modify_value_begin",a={"default_modify_value_end"},b={"pre_set_values"}})
        fns.Add({k="default_modify_value_end",a={"post_set_values"}})
        fns.Add({k="default_modify_cost_begin",a={"default_modify_cost_end"},b={"pre_set_values"}})
        fns.Add({k="default_modify_cost_end",a={"post_set_values"}})
        fns.Add({k="default_modify_feature_begin",a={"default_modify_feature_end"},b={"pre_set_values"}})
        fns.Add({k="default_modify_feature_end",a={"post_set_values"}})
        fns.Add({k="post_set_values"})
        --- notes that changes that may removes previous modify (e.g. buildoptions = ...) should be before default_modify, not in
    end
    --[==[
    local utils={
        "fn_list"
    }
    local utilsPath="utils/wacky_utils/"
    for _, value in pairs(utils) do
        VFS.Include(utilsPath .. value)
    end
    ]==]

    --- Optional Fns that may be done
    local OptionalUnitDefsTweakFns={}
    --- Optional Fns that may be done
    wacky_utils.OptionalUnitDefsTweakFns=OptionalUnitDefsTweakFns
    ---add a function at domain
    ---
    ---notes fn may needs to use lowerkeys 
    ---@param domain string
    ---@param ordered ValueAndOrder<fun()>
    local function AddFnToOptionalUnitDefsTweakFns(domain,ordered)

        if OptionalUnitDefsTweakFns[domain]==nil then
            OptionalUnitDefsTweakFns[domain]={}
        end
        
        if OptionalUnitDefsTweakFns[domain]==true then
            AddFnToUnitDefsTweakFns(ordered)
        else
            local l=OptionalUnitDefsTweakFns[domain]
            l[ordered.k]=ordered
        end
    end
    wacky_utils.AddFnToOptionalUnitDefsTweakFns=AddFnToOptionalUnitDefsTweakFns
    
    ---put fns in domain into 
    ---@param domain string
    local function PushOptionalUnitDefsTweakFns(domain)
        local lf=OptionalUnitDefsTweakFns[domain]
        if lf~=nil and lf~=true then
            for _, value in pairs(lf) do
                AddFnToUnitDefsTweakFns(value)
            end
            OptionalUnitDefsTweakFns[domain]=true
        end
    end
    wacky_utils.PushOptionalUnitDefsTweakFns=PushOptionalUnitDefsTweakFns
    
    Spring.Utilities.wacky_utils=wacky_utils
end