VFS.Include("LuaRules/Utilities/wacky_utils/include.lua")
if not Spring.Utilities.wacky_utils.MakeAddBuildValueWithOrder then
    local wacky_utils=Spring.Utilities.wacky_utils

    wacky_utils.wacky_utils_include("tweak_fns")
    --VFS.Include("LuaRules/Utilities/wacky_utils/tweak_fns.lua")
    local AddFnToUnitDefsTweakFns=wacky_utils.AddFnToUnitDefsTweakFns
    
    
    local function MakeAddBuildValueWithOrder(builer,buildee)
        return{
            k="add_build(" .. builer .. ", " .. buildee .. ")",
            b={"default_add_build_begin"},
            a={"default_add_build_end"},
            v=function ()
                if not UnitDefs[builer] then
                    error("add_build(" .. builer .. ", " .. buildee .. "): unit " .. builer .. " do not exist")
                end
                if not UnitDefs[buildee] then
                    Spring.Echo("warning: ".. "add_build(" .. builer .. ", " .. buildee .. "): unit " .. buildee .. "do not exist")
                end
                if not UnitDefs[builer].buildoptions then
                    UnitDefs[builer].buildoptions={}
                end
                Spring.Echo("add_build(" .. builer .. ", " .. buildee .. ")")
                UnitDefs[builer].buildoptions[#UnitDefs[builer].buildoptions+1]=buildee
            end
        }
    end

    local function MakeAddBuild(builer,buildee)
        AddFnToUnitDefsTweakFns(MakeAddBuildValueWithOrder(builer,buildee))
    end

    wacky_utils.MakeAddBuildValueWithOrder=MakeAddBuildValueWithOrder
    wacky_utils.MakeAddBuild=MakeAddBuild
    Spring.Utilities.wacky_utils=wacky_utils
end