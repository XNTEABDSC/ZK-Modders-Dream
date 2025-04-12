-- copyed from zk src, make them modifiable (able to throw nuke)

include "constants.lua"

local base = piece "base"
local flare = piece "flare"
local firept = piece "firept"

local SOURCE_RANGE = 4200 -- size of the box which the emit point can be randomly placed in

--[[ Higher than hover height partially so that they don't spawn in front of people's eyes
     but come "from space" (cool!!), though also keep in mind that this has a mechanical
     effect on constant-fire accuracy due to distance scaling and spending more time applying
     turnrate/wobble compared to being fired from the lower height of the swarm. ]]
local SOURCE_HEIGHT = 9001

local HOVER_RANGE = 1600


local ud=UnitDefs[ Spring.GetUnitDefID(unitID) ]

local HOVER_HEIGHT = tonumber(ud.customParams.zenith_hover_height) or 2650

local udname=ud.name

local fireRange = WeaponDefNames[udname.."_meteor"].range

local smokePiece = {base}

local SIG_SPAWN = 1
local lastSpawnProjectileTime = Spring.GetGameFrame()

local Vector = Spring.Utilities.Vector
local projectiles = {}
local projectileCount = 0
local oldestProjectile = 1 -- oldestProjectile is for when the projectile table is being cyclicly overridden.

local spGetUnitIsStunned = Spring.GetUnitIsStunned
local spGetUnitRulesParam = Spring.GetUnitRulesParam
local spSetUnitRulesParam = Spring.SetUnitRulesParam
local spGetUnitCurrentCommand = Spring.GetUnitCurrentCommand
local spGiveOrderToUnit = Spring.GiveOrderToUnit
local spGetProjectileDefID=Spring.GetProjectileDefID
local spGetUnitTeam=Spring.GetUnitTeam
local spGetProjectileTeamID =Spring.GetProjectileTeamID
local spGetProjectileOwnerID =Spring.GetProjectileOwnerID
local spGetProjectileTarget=Spring.GetProjectileTarget


local function projectilesAdd(projID)
	projectileCount=projectileCount+1
	projectiles[projectileCount]=projID
end
local function projectilesReplace(projID)
	if projectileCount==0 then
		return nil
	end
	local oldProjID=projectiles[oldestProjectile]
	projectiles[oldestProjectile]=projID
	if oldestProjectile==projectileCount then
		oldestProjectile=1
	else
		oldestProjectile=oldestProjectile+1
	end
end
local function projectilesPop()
	if projectileCount==0 then
		return nil
	end
	local oldProjID=projectiles[oldestProjectile]
	if oldestProjectile==projectileCount then
		oldestProjectile=1
	else
		projectiles[oldestProjectile]=projectiles[projectileCount]
	end
	projectileCount=projectileCount-1
	return oldProjID
end
local function projectilesClear()
	local list=projectiles
	local count=projectileCount
	local index=0
	projectiles={}
	projectileCount=0
	oldestProjectile=1
	return function ()
		if index==count then
			return nil
		end
		index=index+1
		return list[index],index
	end
end

local function projectilesHasNeeded(neededtype)
	local loopcount=0
	while projectileCount>loopcount do
		local projID=projectiles[oldestProjectile]
		local type = spGetProjectileDefID(projID)
		if type==nil then
			projectilesPop()
		elseif not type==neededtype then
			if oldestProjectile==projectileCount then
				oldestProjectile=1
			else
				oldestProjectile=oldestProjectile+1
			end
			loopcount=loopcount+1
		else
			return projID
		end
	end
	return false
end
---@type number
local METEOR_CAPACITY =300
local function projectilesAddOrReplace(projID)
	if projectileCount<METEOR_CAPACITY then
		projectilesAdd(projID)
		return nil
	else
		return projectilesReplace(projID)
	end
end

local function projectilesFilter(filter)
	local index=1
	while index<=projectileCount do
		local res=filter(projectiles[index],index)
		if res then
			projectiles[index]=res
			index=index+1
		else
			projectiles[index]=projectiles[projectileCount]
			projectileCount=projectileCount-1
		end
	end
	if projectileCount>0 then
		while oldestProjectile>projectileCount do
			oldestProjectile=oldestProjectile- projectileCount
		end
	else
		oldestProjectile=1
	end
end

--local tooltipProjectileCount = 0 -- a more correct but less useful count.

local gravityWeaponDefID    = WeaponDefNames[udname.."_gravity_neg"].id
local floatWeaponDefID      = WeaponDefNames[udname.."_meteor_float"].id
local aimWeaponDefID        = WeaponDefNames[udname.."_meteor_aim"].id
local fireWeaponDefID       = WeaponDefNames[udname.."_meteor"].id
local uncontrolWeaponDefID  = WeaponDefNames[udname.."_meteor_uncontrolled"].id

-- 6 minutes to reach capacity.
local SPAWN_PERIOD = WeaponDefNames[udname.."_meteor"].reload  * 1000 -- in milliseconds
local light_period=WeaponDefNames[udname.."_gravity_neg"].reload*1000

do
	local cpcap=tonumber(ud.customParams.zenith_meteor_capacity)
	if cpcap then
		METEOR_CAPACITY=cpcap
	end
end

local SPREAD_PER_DIST = WeaponDefNames[udname.."_meteor"].accuracy/700*0.03

local timeToLiveDefs = {
	[floatWeaponDefID]     = 180000, -- 10 minutes, timeout is handled manually with METEOR_CAPACITY.
	[aimWeaponDefID]       = 300,    -- Should only exist for 1.5 seconds
	[fireWeaponDefID]      = 450,    -- 15 seconds, gives time for a high wobbly meteor to hit the ground.
	[uncontrolWeaponDefID] = 900,    -- 30 seconds, uncontrolled ones are slow
}

local gravityDefs = {
	[floatWeaponDefID]     = -0.2,  -- Gravity reduces the time taken to move from capture to the holding cloud.
	[aimWeaponDefID]       = 0,     -- No gravity, stops aim from being confused.
	[fireWeaponDefID]      = 0.2,   -- Pushes the meteor up a litte, makes an arcing effect.
	[uncontrolWeaponDefID] = -0.12, -- Gravity increases speed of fall and reduced size of drop impact zone.
}

local CMD_ATTACK = CMD.ATTACK
local CMD_DGUN=CMD.DGUN
local CMD_REMOVE=CMD.REMOVE
local gaiaTeam = Spring.GetGaiaTeamID()

local launchInProgress = false
local isBlocked = true
local currentlyEnabled = false

local INLOS_ACCESS = {inlos = true}

local ux, uy, uz

local function IsDisabled()
	local state = Spring.GetUnitStates(unitID)
	if not (state and state.active) then
		return true
	end
	local x, _, z = Spring.GetUnitPosition(unitID)
	local y = Spring.GetGroundHeight(x, z)
	if y < -95 then
		return true
	end
	return spGetUnitIsStunned(unitID) or (spGetUnitRulesParam(unitID, "disarmed") == 1) or (spGetUnitRulesParam(unitID, "lowpower") == 1)
end

local function TransformMeteor(weaponDefID, proID, meteorTeamID, meteorOwnerID, x, y, z)
	
	-- Get old projectile attributes
	local px, py, pz = Spring.GetProjectilePosition(proID)
	local vx, vy, vz = Spring.GetProjectileVelocity(proID)

	Spring.DeleteProjectile(proID)
	
	-- Send new one in the right direction
	local newProID = Spring.SpawnProjectile(weaponDefID, {
		pos = {px, py, pz},
		["end"] = {x, y, z},
		tracking = true,
		speed = {vx, vy, vz},
		ttl = timeToLiveDefs[weaponDefID],
		gravity = gravityDefs[weaponDefID],
		owner = meteorOwnerID,

		--[[ usually Zenith's team, but for uncontrolled meteors
		     like the ones from EMP or reaching the cap it's Gaia
		     so that allied shields will block them (also prevents
		     counting as a teamkill etc). ]]
		team = meteorTeamID,
	})
	if x then
		Spring.SetProjectileTarget(newProID, x, y, z)
	end
	
	return newProID, px, py, pz
end

local function DropSingleMeteor(index)
	local proID = projectiles[index]
	-- Check that the projectile ID is still valid
	if spGetProjectileDefID(proID) == floatWeaponDefID then
		TransformMeteor(uncontrolWeaponDefID, proID, gaiaTeam, nil)
	end
end

local function LoseControlOfMeteors()

	projectilesFilter(function (proID)
		if spGetProjectileDefID(proID) == floatWeaponDefID then
			return TransformMeteor(uncontrolWeaponDefID, proID, gaiaTeam, nil)
		else
			return proID
		end
	end)
	Spring.SetUnitRulesParam(unitID, "meteorsControlled", 0, INLOS_ACCESS)
end

local function RegainControlOfMeteors()
	local zenithTeamID = spGetUnitTeam(unitID)
	projectilesFilter(function (proID)
		if spGetProjectileDefID(proID) == uncontrolWeaponDefID then
			local ttl = Spring.GetProjectileTimeToLive(proID)
			if ttl > 0 then
				local hoverPos = Vector.PolarToCart(HOVER_RANGE*math.random()^2, 2*math.pi*math.random())
				return TransformMeteor(floatWeaponDefID, proID, zenithTeamID, nil, ux + hoverPos[1], uy + HOVER_HEIGHT, uz + hoverPos[2])
			end
		else
			return nil
		end
	end)
	Spring.SetUnitRulesParam(unitID, "meteorsControlled", projectileCount, INLOS_ACCESS)
end

local function SpawnMeteor()
	local zenithTeamID = spGetUnitTeam(unitID)
	local sourcePos = Vector.PolarToCart(SOURCE_RANGE*(1 - math.random()^2), 2*math.pi*math.random())
	local hoverPos = Vector.PolarToCart(HOVER_RANGE*math.random()^2, 2*math.pi*math.random())
	local proID = Spring.SpawnProjectile(floatWeaponDefID, {
		pos = {ux + sourcePos[1], uy + SOURCE_HEIGHT, uz + sourcePos[2]},
		tracking = true,
		speed = {0, -5, 0},
		ttl = 18000, -- 18000 = 10 minutes
		team = zenithTeamID,
	})
	Spring.SetProjectileTarget(proID, ux + hoverPos[1], uy + HOVER_HEIGHT, uz + hoverPos[2])
	
	-- Drop meteor if there are too many. It is more fun this way.
	local maydrop=projectilesAddOrReplace(proID)
	if maydrop then
		DropSingleMeteor(maydrop)
	else
		Spring.SetUnitRulesParam(unitID, "meteorsControlled", projectileCount, INLOS_ACCESS)
	end
end

local CheckMeteorTeam
local function CheckMeteorAvaliableThread()
	local zenithTeamID = spGetUnitTeam(unitID)
	if not CheckMeteorTeam==zenithTeamID then
		projectilesFilter(function (projID)
			local projTeam=spGetProjectileTeamID(projID)
			if projTeam==nil then
				return nil
			elseif projTeam==CheckMeteorTeam then
				local projDef=spGetProjectileDefID(projID)
				local projOwner=spGetProjectileOwnerID(projID)
				local _,x,y,z=spGetProjectileTarget(projID) -- should be
				return TransformMeteor(projDef,projID,zenithTeamID,projOwner,x,y,z)
			else
				return projID
			end
		end)
		CheckMeteorTeam=zenithTeamID
		Spring.SetUnitRulesParam(unitID, "meteorsControlled", projectileCount, INLOS_ACCESS)
	end
end

local function UpdateEnabled(newEnabled)
	if currentlyEnabled == newEnabled then
		return
	end
	currentlyEnabled = newEnabled
	if currentlyEnabled then
		RegainControlOfMeteors()
	else
		LoseControlOfMeteors()
		isBlocked = true -- Block until a projectile is fired successfully.
	end
end

local function EmitPrettyLight()
	while true do
		while IsDisabled() do
			--lastSpawnProjectileTime = Spring.GetGameFrame()
			UpdateEnabled(false)
			Sleep(100)
		end
		EmitSfx(flare, 2049)
		Sleep(light_period)
		UpdateEnabled(not isBlocked)
	end
end

local function SpawnProjectileThread()
	GG.zenith_spawnBlocked = GG.zenith_spawnBlocked or {}
	SetSignalMask(SIG_SPAWN)
	StartThread(EmitPrettyLight)
	StartThread(CheckMeteorAvaliableThread)
	while true do
		--Spring.SpawnProjectile(gravityWeaponDefID, {
		--	pos = {1000,1000,1000},
		--	speed = {10, 0 ,10},
		--	ttl = 100,
		--	maxRange = 1000,
		--})

		--// Handle stun and slow
		-- reloadMult should be 0 only when disabled.
		while IsDisabled() do
			lastSpawnProjectileTime = Spring.GetGameFrame()
			UpdateEnabled(false)
			Sleep(100)
		end
		lastSpawnProjectileTime = Spring.GetGameFrame()
		local reloadMult = (stunned_or_inbuild and 0) or (spGetUnitRulesParam(unitID, "lowpower") == 1 and 0) or (GG.att_ReloadChange[unitID] or 1)

		--EmitSfx(flare, 2049)
		Sleep(SPAWN_PERIOD/((reloadMult > 0 and reloadMult) or 1))

		UpdateEnabled(not isBlocked)
		if currentlyEnabled then
			SpawnMeteor()
		end

		isBlocked = GG.zenith_spawnBlocked[unitID]
		GG.zenith_spawnBlocked[unitID] = false
	end
end

local function LaunchAll(x, z)
	-- Sanitize input
	x, z = Spring.Utilities.ClampPosition(x, z)
	local y = math.max(0, Spring.GetGroundHeight(x,z))
	
	if Vector.AbsVal(ux - x, uz - z) > fireRange then
		return
	end
	
	launchInProgress = true
	local zenithTeamID = spGetUnitTeam(unitID)
	
	-- Make the aiming projectiles. These projectiles have high turnRate
	-- so are able to rotate the wobbly float projectiles in the right
	-- direction.
	local aim = {}
	local aimDist = {}
	local aimCount = 0
	
	for proID in projectilesClear() do
		-- Check that the projectile ID is still valid
		if spGetProjectileDefID(proID) == floatWeaponDefID then
			
			--// Shoot gravity beams at the new aim projectiles. Did not look great.
			--local px, py, pz = Spring.GetProjectilePosition(proID)
			--local dist = math.sqrt((px - ux)^2 + (py - uy)^2 + (pz - uz)^2)
			--local mult = 1000/dist
			--Spring.SpawnProjectile(gravityWeaponDefID, {
			--	pos = {ux, uy + 100, uz},
			--	speed = {(px - ux)*mult, (py - uy)*mult, (pz - uz)*mult},
			--	ttl = dist/1000,
			--	owner = unitID,
			--	maxRange = dist,
			--})
			
			-- Projectile is valid, launch!
			local id, px, py, pz = TransformMeteor(aimWeaponDefID, proID, zenithTeamID, unitID, x, y, z)
			local dist = Vector.Dist3D(x, y, z, px, py, pz)
			
			aimCount = aimCount + 1
			aim[aimCount] = id
			aimDist[aimCount] = dist
		end
	end
	Spring.SetUnitRulesParam(unitID, "meteorsControlled", projectileCount, INLOS_ACCESS)
	
	-- Raw projectile manipulation doesn't create an event (needed for stuff like Fire Once)
	if aimCount > 0 then
		script.EndBurst(1)
	end

	-- Sleep to give time for the aim projectiles to turn
	Sleep(1500)
	
	-- Destroy the aim projectiles and create the speedy, low turnRate
	-- projectiles.
	for i = 1, aimCount do
		local proID = aim[i]
		-- Check that the projectile ID is still valid
		if spGetProjectileDefID(proID) == aimWeaponDefID then
			-- Projectile is valid, launch!
			local aimOff = Vector.PolarToCart(aimDist[i]*SPREAD_PER_DIST*math.random(), 2*math.pi*math.random())
			TransformMeteor(fireWeaponDefID, proID, zenithTeamID, unitID, x + aimOff[1], y, z + aimOff[2])
			--Spring.MarkerAddPoint(x + aimOff[1], y, z + aimOff[2], math.floor(aimDist[i]*SPREAD_PER_DIST))
		end
	end
	
	launchInProgress = false
end

function LaunchOne(x,z)
	if projectileCount==0 then
		return
	end
	-- Sanitize input
	x, z = Spring.Utilities.ClampPosition(x, z)
	local y = math.max(0, Spring.GetGroundHeight(x,z))
	
	if Vector.AbsVal(ux - x, uz - z) > fireRange then
		return
	end
	launchInProgress = true
	
	local zenithTeamID = spGetUnitTeam(unitID)
	
	-- Make the aiming projectiles. These projectiles have high turnRate
	-- so are able to rotate the wobbly float projectiles in the right
	-- direction.
	local aim
	local aimDist

	local proID = projectilesPop()
		-- Check that the projectile ID is still valid
	if proID and spGetProjectileDefID(proID) == floatWeaponDefID then
		
		-- Projectile is valid, launch!
		local id, px, py, pz = TransformMeteor(aimWeaponDefID, proID, zenithTeamID, unitID, x, y, z)
		local dist = Vector.Dist3D(x, y, z, px, py, pz)
		
		aim = id
		aimDist = dist
	end
	
	Spring.SetUnitRulesParam(unitID, "meteorsControlled", projectileCount, INLOS_ACCESS)
	
	-- Raw projectile manipulation doesn't create an event (needed for stuff like Fire Once)
	script.EndBurst(1)
	Sleep(30)
	launchInProgress = false
	-- Sleep to give time for the aim projectiles to turn
	Sleep(1400)
	
	-- Destroy the aim projectiles and create the speedy, low turnRate
	-- projectiles.
	do
		local proID = aim
		-- Check that the projectile ID is still valid
		if spGetProjectileDefID(proID) == aimWeaponDefID then
			-- Projectile is valid, launch!
			local aimOff = Vector.PolarToCart(aimDist*SPREAD_PER_DIST*math.random(), 2*math.pi*math.random())
			TransformMeteor(fireWeaponDefID, proID, zenithTeamID, unitID, x + aimOff[1], y, z + aimOff[2])
			--Spring.MarkerAddPoint(x + aimOff[1], y, z + aimOff[2], math.floor(aimDist[i]*SPREAD_PER_DIST))
		end
	end
	
end

function OnLoadGame()
	local meteorCount = Spring.GetUnitRulesParam(unitID, "meteorsControlled") or 0
	for i = 1, meteorCount do
		SpawnMeteor()
	end
end

function script.Create()
	CheckMeteorTeam=spGetUnitTeam(unitID)
	spSetUnitRulesParam(unitID, "meteorSpawnBlocked", 0)
	spSetUnitRulesParam(unitID, "meteorsControlled", 0, INLOS_ACCESS)
	spSetUnitRulesParam(unitID, "meteorsControlledMax", METEOR_CAPACITY, INLOS_ACCESS)
	local x, _, z = Spring.GetUnitPosition(unitID)
	ux, uy, uz = x, Spring.GetGroundHeight(x, z), z
	
	Move(flare, y_axis, -110)
	Turn(flare, x_axis, math.rad(-90))
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
	StartThread(SpawnProjectileThread)
	
	-- Helpful for devving
	--local proj = Spring.GetProjectilesInRectangle(0,0, 10000, 10000)
	--for i = 1, #proj do
	--	Spring.SetProjectileCollision(proj[i])
	--end
end

function script.QueryWeapon(num)
	if lastSpawnProjectileTime < Spring.GetGameFrame() - 300 then
		lastSpawnProjectileTime = Spring.GetGameFrame()
		Signal(SIG_SPAWN)
		StartThread(SpawnProjectileThread)
	end
	return firept
end

function script.AimFromWeapon(num)
	return firept
end

function script.AimWeapon(num, heading, pitch)
	return num==1 or num==3 --and (spGetUnitRulesParam(unitID, "lowpower") == 0)
end

function script.BlockShot(num, targetID)
	if not projectilesHasNeeded(floatWeaponDefID) then
		return true
	end
	
	if IsDisabled() then
		return true
	end

	if projectileCount==0 then
		return true
	end

	local cmdID, _, cmdTag, cmdParam1, cmdParam2, cmdParam3 = spGetUnitCurrentCommand(unitID)
	if cmdID == CMD_ATTACK or cmdID==CMD_DGUN then

		local LaunchWay
		local doblock
		if num==3 then
			LaunchWay=LaunchOne
			doblock=true
			spGiveOrderToUnit(unitID,CMD_REMOVE,{cmdTag},{})
		else
			LaunchWay=LaunchAll
			doblock=true
		end

		if cmdParam3 then
			StartThread(LaunchWay, cmdParam1, cmdParam3)
			return doblock
		elseif not cmdParam2 then
			targetID = cmdParam1
		end
		if targetID then
			local x,y,z = Spring.GetUnitPosition(targetID)
			if x then
				local vx,_,vz = Spring.GetUnitVelocity(targetID)
				if vx then
					local dist = Vector.AbsVal(ux - x, uy + HOVER_HEIGHT - y, uz - z)
					-- Weapon speed is 53 elmos/frame but it has some acceleration.
					-- Add 22 frames for the aim time. It takes about 40 frames for every meteor
					-- to face the right way so an average meteor should take 20 frames.
					-- That was the reasoning, the final equation is just experimentation though.
					local travelTime = dist/80 + 10 -- in frames
					x = x + vx*travelTime
					z = z + vz*travelTime
				end
				x, z = x + vx*50, z + vz*50
				StartThread(LaunchWay, x, z)
				return doblock
			end
		end
	end
	
	return true
end

function script.Killed(recentDamage, maxHealth)
	LoseControlOfMeteors();
	local severity = recentDamage/maxHealth
	if severity < 0.5 then
		Explode(base, SFX.NONE)
		return 1
	else
		Explode(base, SFX.SHATTER)
		return 2
	end
end
