-- reloadTime is in seconds
-- offsets = {x,y,z} , where x is left(-)/right(+), y is up(+)/down(-), z is forward(+)/backward(-)
VFS.Include("LuaRules/Utilities/wacky_utils.lua")
local utils=Spring.Utilities.wacky_utils

local DRONES_COST_RESOURCES = false

local carrierDefs = {}

local carrierDefNames = {

	shipcarrier = {
		spawnPieces = {"DroneAft", "DroneFore", "DroneLower","DroneUpper"},
		{
			drone = UnitDefNames.dronecarry.id,
			reloadTime = 5,
			maxDrones = 8,
			spawnSize = 1,
			range = 1000,
			maxChaseRange = 1500,
			buildTime = 25,
			maxBuild = 4,
			offsets = {0, 0, 0, colvolMidX = 0, colvolMidY = 0, colvolMidZ = 0, aimX = 0, aimY = 0, aimZ = 0}
		},
	},
	--gunshipkrow = { {drone = UnitDefNames.dronelight.id, reloadTime = 15, maxDrones = 6, spawnSize = 2, range = 900, buildTime=3,
	-- offsets = {0,0,0,colvolMidX=0, colvolMidY=0,colvolMidZ=0,aimX=0,aimY=0,aimZ=0}},
	--[=[
	nebula = {
		spawnPieces = {"pad1", "pad2", "pad3", "pad4"},
		{
			drone = UnitDefNames.dronefighter.id,
			reloadTime = 3,
			maxDrones = 8,
			spawnSize = 2,
			range = 1000,
			maxChaseRange = 1500,
			buildTime = 15,
			maxBuild = 4,
			offsets = {0, 8, 15, colvolMidX = 0, colvolMidY = 30, colvolMidZ = 0, aimX = 0, aimY = 0, aimZ = 0} --shift colvol to avoid collision.
		},
	},]=]
	pw_garrison = {
		spawnPieces = {"drone"},
		{
			drone = UnitDefNames.dronelight.id,
			reloadTime = 10,
			maxDrones = 8,
			spawnSize = 1,
			range = 800,
			maxChaseRange = 1300,
			buildTime = 5,
			maxBuild = 1,
			offsets = {0, 3, 0, colvolMidX = 0, colvolMidY = 0, colvolMidZ = 0, aimX = 0, aimY = 0, aimZ = 0}
		},
	},
	pw_grid = {
		spawnPieces = {"drone"},
		{
			drone = UnitDefNames.droneheavyslow.id,
			reloadTime = 10,
			maxDrones = 6,
			spawnSize = 1,
			range = 800,
			maxChaseRange = 1300,
			buildTime = 5,
			maxBuild = 1,
			offsets = {0, 5, 0, colvolMidX = 0, colvolMidY = 0, colvolMidZ = 0, aimX = 0, aimY = 0, aimZ = 0}
		},
	},
	pw_hq_attacker = {
		spawnPieces = {"drone"},
		{
			drone = UnitDefNames.dronelight.id,
			reloadTime = 10,
			maxDrones = 6,
			spawnSize = 1,
			range = 500,
			maxChaseRange = 1200,
			buildTime = 5,
			maxBuild = 1,
			offsets = {0, 3, 0, colvolMidX = 0, colvolMidY = 0, colvolMidZ = 0, aimX = 0, aimY = 0, aimZ = 0}
		},
	},
	pw_hq_defender = {
		spawnPieces = {"drone"},
		{
			drone = UnitDefNames.dronelight.id,
			reloadTime = 10,
			maxDrones = 6,
			spawnSize = 1,
			range = 600,
			maxChaseRange = 1200,
			buildTime = 5,
			maxBuild = 1,
			offsets = {0, 3, 0, colvolMidX = 0, colvolMidY = 0, colvolMidZ = 0, aimX = 0, aimY = 0, aimZ = 0}
		},
	},
}

local presets = {
	module_companion_drone = {
		drone = UnitDefNames.dronelight.id,
		reloadTime = 12,
		maxDrones = 2,
		spawnSize = 1,
		range = 600,
		maxChaseRange = 1200,
		buildTime = 6,
		maxBuild = 1,
		offsets = {0, 35, 0, colvolMidX = 0, colvolMidY = 0, colvolMidZ = 0, aimX = 0, aimY = 0, aimZ = 0}
	},
	module_battle_drone = {
		drone = UnitDefNames.droneheavyslow.id,
		reloadTime = 18,
		maxDrones = 1,
		spawnSize = 1,
		range = 600,
		maxChaseRange = 1200,
		buildTime = 9,
		maxBuild = 1,
		offsets = {0, 35, 0, colvolMidX = 0, colvolMidY = 0, colvolMidZ = 0, aimX = 0, aimY = 0, aimZ = 0}
	},
}

local unitRulesCarrierDefs = {
	drone = {
		drone = UnitDefNames.dronelight.id,
		reloadTime = 12,
		maxDrones = 2,
		spawnSize = 1,
		range = 600,
		maxChaseRange = 1200,
		buildTime = 10,
		maxBuild = 1,
		offsets = {0, 50, 0, colvolMidX = 0, colvolMidY = 0, colvolMidZ = 0, aimX = 0, aimY = 0, aimZ = 0}
	},
	droneheavyslow = {
		drone = UnitDefNames.droneheavyslow.id,
		reloadTime = 18,
		maxDrones = 1,
		spawnSize = 1,
		range = 600,
		maxChaseRange = 1200,
		buildTime = 15,
		maxBuild = 1,
		offsets = {0, 50, 0, colvolMidX = 0, colvolMidY = 0, colvolMidZ = 0, aimX = 0, aimY = 0, aimZ = 0}
	}
}
local thingsWhichAreDrones = {
	[UnitDefNames.dronecarry.id] = true,
	[UnitDefNames.dronelight.id] = true,
	[UnitDefNames.droneheavyslow.id] = true,
	[UnitDefNames.dronefighter.id] = true
}

for id, ud in pairs(UnitDefs) do
	if ud.customParams and ud.customParams.drone_defs_is_drone then
		thingsWhichAreDrones[id]=true
	end
end

local Globals={
	carrierDefs=carrierDefs,
	carrierDefNames=carrierDefNames,
	presets=presets,
	unitRulesCarrierDefs=unitRulesCarrierDefs,
	thingsWhichAreDrones=thingsWhichAreDrones,
}


--[[
for name, ud in pairs(UnitDefNames) do
	if ud.customParams.sheath_preset then
		sheathDefNames[name] = Spring.Utilities.CopyTable(presets[ud.customParams.sheath_preset], true)
	end
end
]]--
for id, ud in pairs(UnitDefs) do
	if ud.customParams and ud.customParams.drone_defs_drone_preset then
		local presetsstr=ud.customParams.drone_defs_drone_preset
		--[==[
		presets[ud.name]=utils.justloadstring(predefs,Globals)
		presets[ud.name].drone=id]==]
		local presetstable=utils.justeval_errnil(presetsstr,utils.getenv_merge(Globals))
		for key, value in pairs(presetstable or {}) do
			presets[key]=value
		end
	end
end

for id, ud in pairs(UnitDefs) do
	if ud.customParams and ud.customParams.drone_defs_carrier_def then
		local drones=ud.customParams.drone_defs_carrier_def
		carrierDefs[id]=Spring.Utilities.MergeTable(carrierDefs[id] or {},utils.justeval_errnil(drones,utils.getenv_merge(Globals)))
		Spring.Echo("Loaded carrier " .. ud.name)
	end
end

for id, ud in pairs(UnitDefs) do
	if ud.customParams then
		if ud.customParams.drones then
			local droneFunc,err = loadstring("return "..ud.customParams.drones)
			if not droneFunc then
				Spring.Log("LuaRules/Configs/drone_defs.lua",LOG.ERROR,"Failed to loadstring for unit " .. ud.name .. "\n ".. "loading " .. "return "..ud.customParams.drones .."\n with error: " .. err)
			else
				local drones = droneFunc()
				carrierDefs[id] = carrierDefs[id] or {}
				for i=1,#drones do
					carrierDefs[id][i] = Spring.Utilities.CopyTable(presets[drones[i]])
				end
			end
		end
		if ud.customParams.drone_defs_drone_spawn_pieces then
			carrierDefs[id] = carrierDefs[id] or {}
			carrierDefs[id].spawnPieces=utils.justeval_errnil(ud.customParams.drone_defs_drone_spawn_pieces)
		end
	end
end

for udid, data in pairs(carrierDefs) do
	local ud=UnitDefs[udid]
	if ud then
		if ud.customParams.def_scale then
			local scale=tonumber(ud.customParams.def_scale)
			for idrone=1,#data do
				local dronedata=data[idrone]
				for key, value in pairs(dronedata.offsets) do
					dronedata.offsets[key]=value*scale
				end
			end
		end
		carrierDefs[ud.id] = data
	end
end




local function ProcessCarrierDef(carrierData)
	local ud = UnitDefs[carrierData.drone]
	-- derived from: time_to_complete = (1.0/build_step_fraction)*build_interval
	local buildUpProgress = 1/(carrierData.buildTime)*(1/30)
	carrierData.buildStep = buildUpProgress
	carrierData.buildStepHealth = buildUpProgress*ud.health
	
	if DRONES_COST_RESOURCES then
		carrierData.buildCost = ud.metalCost
		carrierData.buildStepCost = buildUpProgress*carrierData.buildCost
		carrierData.perSecondCost = carrierData.buildCost/carrierData.buildTime
	end

	
	carrierData.colvolTweaked = carrierData.offsets.colvolMidX ~= 0 or carrierData.offsets.colvolMidY ~= 0
									or carrierData.offsets.colvolMidZ ~= 0 or carrierData.offsets.aimX ~= 0
										or carrierData.offsets.aimY ~= 0 or carrierData.offsets.aimZ ~= 0
	return carrierData
end

for name, carrierData in pairs(carrierDefs) do
	for i = 1, #carrierData do
		carrierData[i] = ProcessCarrierDef(carrierData[i])
	end
end

for name, carrierData in pairs(unitRulesCarrierDefs) do
	carrierData = ProcessCarrierDef(carrierData)
end

return carrierDefs, thingsWhichAreDrones, unitRulesCarrierDefs
