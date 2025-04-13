local REPAIR_ENERGY_COST_FACTOR = Game.repairEnergyCostFactor
local spSetUnitBuildSpeed=Spring.SetUnitBuildSpeed
GG.attRaw_BuildSpeed={}
return {
    UpdateBuildSpeed = {
        new = function(unitID, unitDefID)
            local ud = UnitDefs[unitDefID]
            local buildSpeed = ud.buildSpeed or 0

            local buildMultCur = 1

            return {
                newDataHandler = function(frame)
                    local buildMult = 1

                    return {
                        fold = function(data)
                            buildMult = buildMult * (data.build or 1)
                        end,
                        apply = function()
                            GG.attRaw_BuildSpeed[unitID] = buildSpeed*buildMult
                            if buildMult ~= buildMultCur and buildSpeed > 0 then
                                local newBuildSpeed = buildSpeed * buildMult
                                spSetUnitBuildSpeed(unitID,
                                    newBuildSpeed, -- build
                                    newBuildSpeed / REPAIR_ENERGY_COST_FACTOR, -- repair
                                    newBuildSpeed, -- reclaim
                                    0.5 * newBuildSpeed -- rezz
                                )
                                buildMultCur = buildMult
                            end
                        end
                    }
                end,
                clear = function()
                    GG.attRaw_BuildSpeed[unitID] = nil
                    -- Reset logic can be added here if needed
                end
            }
        end
    }
}