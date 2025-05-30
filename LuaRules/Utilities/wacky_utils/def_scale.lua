VFS.Include("LuaRules/Utilities/wacky_utils/include.lua")
if not Spring.Utilities.wacky_utils.table_replace then
    local wacky_utils=Spring.Utilities.wacky_utils
    wacky_utils.wacky_utils_include("modify_all")
    wacky_utils.wacky_utils_include("others")
    wacky_utils.wacky_utils_include("dimensions")
    local modify_all=wacky_utils.modify_all
    local lowervalues=wacky_utils.lowervalues
    local list_to_set=wacky_utils.list_to_set
        local udtryScales3=list_to_set(lowervalues({
            --"collisionVolumeOffsets",
            --"collisionVolumeScales",
            "selectionVolumeOffsets",
            "selectionVolumeScales"
        }))
        local udtryScales1=list_to_set(lowervalues({
            "trackOffset",
            "trackWidth",
            "trackStrength",
            "trackStretch",
            "buildingGroundDecalSizeX","buildingGroundDecalSizeY","buildingGroundDecalDecaySpeed"
        }))
        local udcpdefScales1=list_to_set(lowervalues({
            "model_rescale"
        }))
        local udtryScales1round=list_to_set(lowervalues({
            -- special
            --"footprintX",
            --"footprintZ",
        }))
        local udcptryScales3=list_to_set(lowervalues({
            --"aimposoffset","midposoffset"
        }))
        local udcptryScales1=list_to_set(lowervalues({
            --"modelradius","modelheight"
        }))
        local GetDimensions=wacky_utils.GetDimensions
        local ToDimensions=wacky_utils.ToDimensions
        local function scale3(scale)
            return function(v)
                if type(v)=="string" then
                    local ss=GetDimensions(v)
                    if ss then
                        if #ss~=3 then
                            Spring.Echo("Odd thing found " .. v)
                        end
                        for i = 1, #ss do
                            ss[i]=ss[i]*scale
                        end
                        return ToDimensions(ss)
                    else
                        return v
                    end
                else
                    return v
                end
            end
        end
        local function scale1(scale)
            return function (v)
                if type(v)=="number" then
                    return v*scale
                else
                    return v
                end
            end
        end
        local function defscale1(scale)
            return function (v)
                if type(v)=="number" then
                    return v*scale
                else
                    return scale
                end
            end
        end
        local function scale1round(scale)
            return function (v)
                if type(v)=="number" then
                    v=v*scale
                    v=math.floor(v+0.5)
                    if v<1 then
                        v=1
                    end
                    return v
                else
                    return v
                end
            end
        end
        local function ScaleYardMap(oldYardMap,oldx,oldz,newx,newz)
            local oldYardMapTable={}
            local oldYardMapIndex=1
            for z = 1, oldz do
                local oldYardMapTablez={}
                oldYardMapTable[z]=oldYardMapTablez
                for x = 1, oldx do
                    local nextchar
                    while true do
                        nextchar=string.sub(oldYardMap,oldYardMapIndex,oldYardMapIndex)
                        oldYardMapIndex=oldYardMapIndex+1
                        if nextchar==nil then
                            error("Bad YardMap and size")
                        end
                        if nextchar~=" " then
                            break
                        end
                    end
                    oldYardMapTablez[x]=nextchar
                end
            end
            local newYardMapTable={}
            local newYardMap=""
            local newxToOldx=oldx/newx
            local newzToOldz=oldz/newz
            for z = 1, newz do
                local oldYardMapTabley=oldYardMapTable[math.ceil((z-0.5)*newzToOldz)]
                for x = 1, newx do
                    newYardMap=newYardMap .. oldYardMapTabley[math.ceil((x-0.5)*newxToOldx)]
                end
            end
            return newYardMap
        end
        --local modify_all=wacky_utils.modify_all
        function wacky_utils.set_scale(ud,scale)
            
            -- Spring.Echo("set_scale scale: " .. tostring(scale))
            -- Spring.Echo("modify_all udtryScales3")
            modify_all(ud,udtryScales3,scale3(scale))
            -- Spring.Echo("modify_all udtryScales1")
            modify_all(ud,udtryScales1,scale1(scale))
            -- Spring.Echo("modify_all udtryScales1round")
            modify_all(ud,udtryScales1round,scale1round(scale))

            ud.customparams=ud.customparams or {}
            local udcp=ud.customparams
            
            -- Spring.Echo("modify_all udcptryScales3")
            modify_all(udcp,udcptryScales3,scale3(scale))
            -- Spring.Echo("modify_all udcptryScales1")
            modify_all(udcp,udcptryScales1,scale1(scale))
            ud.customparams.dynamic_colvol=true
            
            -- Spring.Echo("modify_all udcpdefScales1")
            modify_all(udcp,udcpdefScales1,defscale1(scale))

            
            if ud.movementclass then
                -- Spring.Echo("modify movementclass")
                local b,s,p=wacky_utils.MoveDef_CanGen(ud.movementclass)
                if b then
                    s=s*scale
                    s=math.floor(s+0.5)
                    if s<1 then
                        s=1
                    end
                    -- Spring.Echo("Change unit " .. ud.name .. "'s movementclass to: " ..p .. b .. tostring(s))
                    ud.movementclass=p .. b .. tostring(s)
                end
            end
            
            if ud.footprintx then
                -- Spring.Echo("modify footprint")
                local oldfpx,oldfpz=ud.footprintx,ud.footprintz
                local newfpx,newfpz=scale1round(scale)(oldfpx),scale1round(scale)(oldfpz)
                ud.footprintx,ud.footprintz=newfpx,newfpz
                -- Spring.Echo(("modify footprint from %s,%s to %s,%s"):format(tostring(oldfpx),tostring(oldfpz),tostring(newfpx),tostring(newfpz)))
                if ud.yardmap then
                    -- Spring.Echo("modify yardmap: ")
                    -- Spring.Echo(tostring(ud.yardmap))

                    ud.yardmap=ScaleYardMap(ud.yardmap,oldfpx,oldfpz,newfpx,newfpz)
                end
            end
        end

    Spring.Utilities.wacky_utils=wacky_utils
end