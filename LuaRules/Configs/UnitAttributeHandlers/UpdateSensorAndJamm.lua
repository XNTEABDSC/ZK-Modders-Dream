local INLOS_ACCESS = {inlos = true}


local function tobool(val)
	local t = type(val)
	if (t == 'nil') then
		return false
	elseif (t == 'boolean') then
		return val
	elseif (t == 'number') then
		return (val ~= 0)
	elseif (t == 'string') then
		return ((val ~= '0') and (val ~= 'false'))
	end
	return false
end

---@type {[string|number]:AttributesHandlerFactory}
return{
    UpdateSensorAndJamm={
        new=function (unitID,unitDefID)
            local ud=UnitDefs[unitDefID]
            local origUnitSight= ud.sightDistance
            local radarUnitDef= ud.radarDistance
			local sonarUnitDef =  ud.sonarDistance
            local sonarCanDisable = tobool(ud.customParams.sonar_can_be_disabled)
            local jammerUnitDef = ud.radarDistanceJam
            
            local senseMultCur = 1
            local setRadarCur = false
            local setSonarCur = false
            local setJammerCur = false
            local setSightCur = false

            local abilityDisabledCur=false
            ---@type AttributesHandler
            return{
                newDataHandler=function (frame)
                    local senseMult = 1
                    local setRadar = false
                    local setSonar = false
                    local setJammer = false
                    local setSight = false
                    local abilityDisabled=false

                    ---@type AttributesDataHandler
                    return {
                        ---@param data {abilityDisabled:boolean,sense:number?,setRadar:boolean?,setJammer:boolean?,setSonar:boolean?,setSight:boolean?}
                        fold=function (data)
                            senseMult=senseMult*(data.sense or 1)

                            ---@diagnostic disable: cast-local-type
                            
                            setRadar=setRadar or data.setRadar
                            setSonar=setSonar or data.setSonar
                            setJammer=setJammer or data.setJammer
                            setSight=setSight or data.setSight
                            abilityDisabled=abilityDisabled or data.abilityDisabled

                            ---@diagnostic enable: cast-local-type
                            

                        end,
                        apply=function ()
                            if senseMult~=senseMultCur or setRadar~=setRadarCur or setSonar~=setSonarCur or setJammer~=setJammerCur or setSight~=setSightCur or abilityDisabledCur~=abilityDisabled then
                                local abilityMult=(not abilityDisabled) and 1 or 0
                                if setRadar or radarUnitDef>0 then
                                    Spring.SetUnitSensorRadius(unitID, "radar", abilityMult*(setRadar or radarUnitDef)*senseMult)
                                end
                                if setSonar or sonarUnitDef then
                                    local sonarAbilityMult=1
                                    if sonarCanDisable and abilityDisabled then
                                        sonarAbilityMult=0
                                    end
                                    --sonarCanDisable and abilityMult or 1
                                    --there will be a day for humanity to be cooked by this
                                    Spring.SetUnitSensorRadius(unitID, "sonar", (sonarAbilityMult)*(setSonar or sonarUnitDef)*senseMult)
                                end
                                if setJammer or jammerUnitDef then
                                    Spring.SetUnitSensorRadius(unitID, "radarJammer", abilityMult*(setJammer or jammerUnitDef)*senseMult)
                                end
                                Spring.SetUnitSensorRadius(unitID, "los", (setSight or origUnitSight)*senseMult)
                                Spring.SetUnitSensorRadius(unitID, "airLos", (setSight or origUnitSight)*senseMult)
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