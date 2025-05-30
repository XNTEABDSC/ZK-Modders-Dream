if not Spring.UnitScript.script_weapon_charging_salvo then
    local script_weapon_charging_salvo={}
    local ALLY_ACCESS = {allied = true}
	local spGetGameFrame         = Spring.GetGameFrame
    local floor=math.floor
    local StartThread=Spring.UnitScript.StartThread
    ---@param onOneCharge nil|fun(charge:number)
    function script_weapon_charging_salvo.newBurstWeapon(unitID,salvoCapacity,reloadTimePerSalvo,onOneCharge)
        local o={}
        --[=[
        local count=salvoCapacity
        local reloadingTime=0
        ]=]
        local charge=salvoCapacity
        local active=true
        local reloadChargePerSecond=1/reloadTimePerSalvo
        
        function o.CanShot()
            return charge>=1
        end
        function o.DoShot()
            charge=charge-1
        end
        function o.TryShot()
            if charge>=1 then
                charge=charge-1
                return true
            end
            return false
        end
        function o.salvoCapacity()
            return salvoCapacity
        end
        function o.salvoReloadSecond()
            return reloadTimePerSalvo
        end
        function o.FullReloadTimeLeft()
            return reloadTimePerSalvo*(salvoCapacity-charge)
            --salvoReloadSecond*salvoCapacity - (salvoReloadSecond*count+reloadingTime)
        end
        function o.ReloadThread()
            while active do
                if charge<salvoCapacity then
                    local oldChargeInt=floor(charge)

                    local stunnedOrInbuild = Spring.GetUnitIsStunned(unitID)
		            local reloadMult = (stunnedOrInbuild and 0) or (Spring.GetUnitRulesParam(unitID, "totalReloadSpeedChange") or 1)

                    charge=charge+reloadChargePerSecond*0.1*reloadMult
                    
                    local newChargeInt=floor(charge)
                    local scriptReloadFrame=spGetGameFrame()+(reloadTimePerSalvo*(salvoCapacity-charge))*30
                    --local scriptReloadPercentage=(charge/reloadTimePerSalvo)/salvoCapacity
                    Spring.SetUnitRulesParam(unitID, "scriptLoaded", newChargeInt, ALLY_ACCESS)
                    Spring.SetUnitRulesParam(unitID, "scriptReloadFrame", scriptReloadFrame, ALLY_ACCESS)
                    if newChargeInt>oldChargeInt then
                        if onOneCharge then
                            onOneCharge(charge)
                        end
                    end
                    --Spring.SetUnitRulesParam(unitID, "scriptReloadPercentage", scriptReloadPercentage, ALLY_ACCESS)
                else
                    charge=salvoCapacity
                    Spring.SetUnitRulesParam(unitID, "scriptLoaded", floor(charge), ALLY_ACCESS)
                    Spring.SetUnitRulesParam(unitID, "scriptReloadFrame", nil, ALLY_ACCESS)
                    --Spring.SetUnitRulesParam(unitID, "scriptReloadPercentage", nil, ALLY_ACCESS)

                end
                Sleep(100)
            end
        end
        function o.Deactive()
            active=false
        end
        function o.WaitUntilReady()
            while charge<=1 do
                Sleep(100)
            end
        end
        return o
    end
    function script_weapon_charging_salvo.newBurstWeaponFromWD(unitID,wd,onOneCharge)
        local cp=wd.customParams or wd.customparams
        local salvo=tonumber(cp.script_burst)
        local fullreload=tonumber(cp.script_reload)
        return script_weapon_charging_salvo.newBurstWeapon(unitID,salvo,fullreload/salvo,onOneCharge)
    end
    Spring.UnitScript.script_weapon_charging_salvo=script_weapon_charging_salvo
end
return Spring.UnitScript.script_weapon_charging_salvo