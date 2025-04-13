local INLOS_ACCESS = {inlos = true}

local function GetMass(health, cost)
	return (((cost/2) + (health/8))^0.6)*6.5
end

---@type {[string|number]:AttributesHandlerFactory}
return{
    UpdateHealthCostMass={
        new=function (unitID,unitDefID)
            local ud=UnitDefs[unitDefID]
            local origUnitHealth= ud.health
            local origUnitCost= ud.buildTime
            local curHealthMult=1
            local curHealthAdd=0
            local curCostMult=1
            local curMassMult=1
            ---@type AttributesHandler
            return{
                newDataHandler=function (frame)
                    local healthMult=1
                    local healthAdd=0
                    local costMult=1
                    local massMult=1

                    ---@type AttributesDataHandler
                    return {
                        ---@param data {healthAdd:number?,healthMult:number?,cost:number?,mass:number?}
                        fold=function (data)
                            healthMult=healthMult*(data.healthMult or 1)
                            healthAdd=healthAdd+(data.healthAdd or 0)
                            costMult=costMult*(data.cost or 1)
                            massMult=massMult*(data.mass or 1)
                        end,
                        apply=function ()
                            GG.att_CostMult[unitID] = costMult
                            GG.att_HealthMult[unitID] = healthMult
                            if curCostMult~=costMult or curHealthAdd~=healthAdd or curMassMult~=massMult or curHealthMult~=healthMult then
                                
                                local newMaxHealth = (origUnitHealth + healthAdd) * healthMult
                                local oldHealth, oldMaxHealth = Spring.GetUnitHealth(unitID)
                                Spring.SetUnitMaxHealth(unitID, newMaxHealth)
                                Spring.SetUnitHealth(unitID, oldHealth * newMaxHealth / oldMaxHealth)
                                
                                local origCost = origUnitCost
                                local cost = origCost*costMult
                                Spring.SetUnitCosts(unitID, {
                                    metalCost = cost,
                                    energyCost = cost,
                                    buildTime = cost,
                                })
                                
                                if massMult == 1 then
                                    -- Default to update mass based on new stats, if a multiplier is not set.
                                    local mass = GetMass(newMaxHealth, cost)
                                    Spring.SetUnitMass(unitID, mass)
                                    Spring.SetUnitRulesParam(unitID, "massOverride", mass, INLOS_ACCESS)
                                else
                                    local mass = GetMass(origUnitHealth, origCost) * massMult
                                    Spring.SetUnitMass(unitID, mass)
                                    Spring.SetUnitRulesParam(unitID, "massOverride", mass, INLOS_ACCESS)
                                end
                                curCostMult=costMult
                                curHealthAdd=healthAdd
                                curMassMult=massMult
                                curHealthMult=healthMult
                            end
                        end
                    }
                end,
                clear=function ()
                    
                end
            }
        end
    }
}