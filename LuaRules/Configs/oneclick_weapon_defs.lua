-- reloadTime is in seconds

local oneClickWepDefs = {}

local oneClickWepDefNames = {
	terraunit = {
		{ functionToCall = "Detonate", name = "Cancel", tooltip = "Cancel selected terraform units.", texture = "LuaUI/Images/Commands/Bold/cancel.png", partBuilt = true},
	},
	gunshipkrow = {
		{ functionToCall = "ClusterBomb", reloadTime = 854, name = "Carpet Bomb", tooltip = "Drop Bombs: Drop a huge number of bombs in a circle under the Krow", weaponToReload = 3, texture = "LuaUI/Images/Commands/Bold/bomb.png",},
	},
	--hoverdepthcharge = {
	--	{ functionToCall = "ShootDepthcharge", reloadTime = 256, name = "Drop Depthcharge", tooltip = "Drop Depthcharge: Drops a on the sea surface or ground.", weaponToReload = 1, texture = "LuaUI/Images/Commands/Bold/dgun.png",},
	--},
	subscout = {
		{ functionToCall = "Detonate", name = "Detonate", tooltip = "Detonate: Kill selected bomb units.",  texture = "LuaUI/Images/Commands/Bold/detonate.png",},
	},
	cloakbomb = {
		{ functionToCall = "Detonate", name = "Detonate", tooltip = "Detonate: Kill selected bomb units.",  texture = "LuaUI/Images/Commands/Bold/detonate.png",},
	},
	shieldbomb = {
		{ functionToCall = "Detonate", name = "Detonate", tooltip = "Detonate: Kill selected bomb units.", texture = "LuaUI/Images/Commands/Bold/detonate.png",},
	},
	jumpbomb = {
		{ functionToCall = "Detonate", name = "Detonate", tooltip = "Detonate: Kill selected bomb units.",  texture = "LuaUI/Images/Commands/Bold/detonate.png",},
	},
	gunshipbomb = {
		{ functionToCall = "Detonate", name = "Detonate", tooltip = "Detonate: Kill selected bomb units.", texture = "LuaUI/Images/Commands/Bold/detonate.png",},
	},
	amphbomb = {
		{ functionToCall = "Detonate", name = "Detonate", tooltip = "Detonate: Kill selected bomb units.",  texture = "LuaUI/Images/Commands/Bold/detonate.png",},
	},
	shieldscout = {
		{ functionToCall = "Detonate", name = "Detonate", tooltip = "Detonate: Kill selected bomb units.", texture = "LuaUI/Images/Commands/Bold/detonate.png",},
	},
	bomberdisarm = {
		{ functionToCall = "StartRun", name = "Start Run", tooltip = "Unleash Lightning: Manually activate Thunderbird run.", texture = "LuaUI/Images/Commands/Bold/bomb.png",},
	},
	--[[
	tankraid = {
		{ functionToCall = "FlameTrail", reloadTime = 850, name = "Flame Trail", tooltip = "Leave a path of flame in your wake", useSpecialReloadFrame = true, texture = "LuaUI/Images/Commands/Bold/sprint.png",},
	},
	--]]
	planefighter = {
		{ functionToCall = "Sprint", reloadTime = 850, name = "Speed Boost", tooltip = "Speed boost (5x for 1 second)", useSpecialReloadRemaining = true, texture = "LuaUI/Images/Commands/Bold/sprint.png",},
	},
	planelightscout = {
		{ functionToCall = "SprintDetonate", name = "Detonate", tooltip = "Speed up (5x for 3 seconds) and charge reveal radius, then detonate.", texture = "LuaUI/Images/Commands/Bold/detonate.png",},
	},
	--hoverriot = {
	--	{ functionToCall = "Sprint", reloadTime = 1050, name = "Speed Boost", tooltip = "Speed boost (4x for 1 second)", useSpecialReloadRemaining = true, texture = "LuaUI/Images/Commands/Bold/sprint.png",},
	--},
	--planescout = {
	--	{ functionToCall = "Cloak", reloadTime = 600, name = "Temp Cloak", tooltip = "Cloaks for 5 seconds", useSpecialReloadFrame = true},
	--},
	gunshipheavytrans = {
		{ functionToCall = "ForceDropUnit", reloadTime = 7, name = "Drop Cargo", tooltip = "Eject Cargo: Drop the unit in the transport.", useSpecialReloadFrame = true,},
	},
	gunshiptrans = {
		{ functionToCall = "ForceDropUnit", reloadTime = 7, name = "Drop Cargo", tooltip = "Eject Cargo: Drop the unit in the transport.", useSpecialReloadFrame = true,},
	},
	
	--staticmissilesilo = {
	--	dummy = true,
	--	{ functionToCall = nil, name = "Select Missiles", tooltip = "Select missiles", texture = "LuaUI/Images/Commands/Bold/missile.png"},
	--},
}


for name, data in pairs(oneClickWepDefNames) do
	if UnitDefNames[name] then
		oneClickWepDefs[UnitDefNames[name].id] = data
	end
end

VFS.Include("LuaRules/Utilities/wacky_utils.lua")
local utils=Spring.Utilities.wacky_utils

local defcopys={}
for udid, ud in pairs(UnitDefs) do
	local udcp=ud.customParams
	if udcp then
		local cpstr=udcp.oneclick_weapon_defs
		if cpstr then
			oneClickWepDefs[udid]=utils.justeval_errnil(cpstr)
		end
		local defcopy=udcp.oneclick_weapon_defs_copy
		if defcopy then
			defcopys[#defcopys+1] = {udid,UnitDefNames[defcopy].id}
		end
	end
end

do
	local defcopys_unfinished=utils.loop_until_finish_all_list(defcopys,function (item)
		local src=item[2]
		local into=item[1]
		if oneClickWepDefs[src] then
			oneClickWepDefs[into]=oneClickWepDefs[src]
			return true
		else
			return false
		end
	end)

	if defcopys_unfinished then
		local unfinisheds=""
		for _,item in pairs(defcopys_unfinished) do
			unfinisheds=unfinisheds ..
				((UnitDefs[item[1]] and UnitDefs[item[1]].name) or ("unknow unit " .. item[1])) .. " <- " ..
				((UnitDefs[item[2]] and UnitDefs[item[2]].name) or ("unknow unit " .. item[2]))
		end
		Spring.Log("missing oneclick_weapon_defs_copy: " .. unfinisheds,LOG.WARNING)
		
	end
end



return oneClickWepDefs
