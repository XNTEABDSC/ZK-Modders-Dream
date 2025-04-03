VFS.Include("LuaRules/Utilities/wacky_utils/include.lua")
if not Spring.Utilities.wacky_utils.SetMorphMut then
    local wacky_utils=Spring.Utilities.wacky_utils

    wacky_utils.wacky_utils_include("tweak_fns")
    local AddFnToUnitDefsTweakFns=wacky_utils.AddFnToUnitDefsTweakFns
    local function SetMorphMut(srcname,copyedname,morphtime,morphprice)
        if not UnitDefs[srcname] then
            error("unit " .. srcname .. "do not exist")
        end
        local ud_cp=UnitDefs[srcname].customparams
        if ud_cp.morphto then
            ud_cp.morphto_1=ud_cp.morphto
            ud_cp.morphto=nil
            ud_cp.morphtime_1=ud_cp.morphtime
            ud_cp.morphtime=nil
            ud_cp.morphcost_1=ud_cp.morphcost
            ud_cp.morphcost=nil
        end
        --morphprice=morphprice or UnitDefs[copyedname].metalcost-UnitDefs[srcname].metalcost
        local i=1
        morphtime=morphtime or 10
        while true do
            if not ud_cp["morphto_" .. i] then
                ud_cp["morphto_" .. i]=copyedname
                ud_cp["morphtime_" .. i]=morphtime
                ud_cp["morphcost_" .. i]=morphprice
                break
            end
            i=i+1
        end
    end
    wacky_utils.SetMorphMut=SetMorphMut

    local function MakeSetMorphMutValueWithOrder(srcname,copyedname,morphtime,morphprice)
        return{
            k=("set_morph_mul(" .. srcname .. ", " .. copyedname .. ")"),
            b={"default_set_morph_begin"},
            a={"default_set_morph_end"},
            v=function ()
                SetMorphMut(srcname,copyedname,morphtime,morphprice)
                --UnitDefs[srcname].description=UnitDefs[srcname].description .. "  Can morph into " .. copyedname
            end
        }
    end
    wacky_utils.MakeSetMorphMutValueWithOrder=MakeSetMorphMutValueWithOrder

    Spring.Utilities.wacky_utils=wacky_utils
end