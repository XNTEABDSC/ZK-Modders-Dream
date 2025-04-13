
local INLOS_ACCESS = {inlos = true}
local spSetUnitRulesParam=Spring.SetUnitRulesParam
GG.att_StaticBuildRateMult={}
return {
    UpdateStaticAttributes = {
        new = function(unitID, unitDefID)
            local staticBuildpowerMultCur = 1
            local staticMetalMultCur = 1
            local staticEnergyMultCur = 1
            local staticShieldRegenCur = 1
            local staticHealthRegenCur = 1

            return {
                newDataHandler = function(frame)
                    local staticBuildpowerMult = 1
                    local staticMetalMult = 1
                    local staticEnergyMult = 1
                    local staticShieldRegen = 1
                    local staticHealthRegen = 1

                    return {
                        fold = function(data)
                            if data.static then
                                staticBuildpowerMult = staticBuildpowerMult * (data.build or 1)
                                staticMetalMult = staticMetalMult * (data.econ or 1)
                                staticEnergyMult = staticEnergyMult * (data.econ or 1) * (data.energy or 1)
                                staticShieldRegen = staticShieldRegen * (data.shieldRegen or 1)
                                staticHealthRegen = staticHealthRegen * (data.healthRegen or 1)
                            end
                        end,
                        apply = function()
                            spSetUnitRulesParam(unitID, "totalStaticBuildpowerMult", staticBuildpowerMult, INLOS_ACCESS)
                            spSetUnitRulesParam(unitID, "totalStaticMetalMult", staticMetalMult, INLOS_ACCESS)
                            spSetUnitRulesParam(unitID, "totalStaticEnergyMult", staticEnergyMult, INLOS_ACCESS)
                            spSetUnitRulesParam(unitID, "totalStaticShieldRegen", staticShieldRegen, INLOS_ACCESS)
                            spSetUnitRulesParam(unitID, "totalStaticHealthRegen", staticHealthRegen, INLOS_ACCESS)
                            GG.att_StaticBuildRateMult[unitID] = staticBuildpowerMult
                        end
                    }
                end,
                clear = function()
                    GG.att_StaticBuildRateMult[unitID] = nil
                    -- Reset logic can be added here if needed
                end
            }
        end
    }
}