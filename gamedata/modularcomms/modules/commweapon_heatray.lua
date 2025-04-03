return{
    moduledef={
        commweapon_heatray={
            name="Heatray",
		    description="Heatray: Rapidly melts anything at short range; steadily loses all of its damage over distance",
        }
    },
    dynamic_comm_def=function (shared)
		shared=ModularCommDefsShared or shared
		local moduleImagePath=shared.moduleImagePath
		local COST_MULT=shared.COST_MULT
		local HP_MULT=shared.HP_MULT
        
        local moddef={
            name = "commweapon_heatray",
            humanName = "Heatray",
            description = "Heatray: Rapidly melts anything at short range; steadily loses all of its damage over distance",
            image = moduleImagePath .. "commweapon_heatray.png",
            limit = 2,
            cost = 0,
            requireChassis = {"assault", "knight"},
            requireLevel = 1,
            slotType = "basic_weapon",
            applicationFunction = function (modules, sharedData)
                if sharedData.noMoreWeapons then
                    return
                end
                if not sharedData.weapon1 then
                    sharedData.weapon1 = "commweapon_heatray"
                else
                    sharedData.weapon2 = "commweapon_heatray"
                end
            end,
            hardcodedID=7,
        }
        local GenAdvWeaponModule=shared.GenAdvWeaponModule
        local moddef2=GenAdvWeaponModule(moddef)
        moddef2.hardcodedID=54
		return {moddef,moddef2}
    end
}