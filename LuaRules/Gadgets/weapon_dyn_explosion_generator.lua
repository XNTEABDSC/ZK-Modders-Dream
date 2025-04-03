--SetProjectileExplosionGenerator(projID,ceg,weaponDefID?)


if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name     = "SpawnCEG when ProjectileDestroyed",
		desc     = "SpawnCEG when ProjectileDestroyed",
		author   = "XNTEABDSC",
		date     = "",
		license  = "GNU GPL, v2 or later",
		layer    = 0, -- after `start_waterlevel.lua` (for map height adjustment)
		enabled  = true -- loaded by default?
	}
end

local ProjUseCeg={}

local spGetProjectileDefID=Spring.GetProjectileDefID
local scSetWatchWeapon =Script.SetWatchWeapon

local function SetProjectileExplosionGenerator(projID,ceg,wdid)
    if ceg~=nil and string.len(ceg)>0 then
        wdid=wdid or spGetProjectileDefID(projID)
        scSetWatchWeapon(wdid,true)
        ProjUseCeg[projID]=ceg
    end
end
GG.SetProjectileExplosionGenerator=SetProjectileExplosionGenerator

local spGetProjectilePosition=Spring.GetProjectilePosition
local spGetProjectileDirection=Spring.GetProjectileDirection
local spSpawnCEG=Spring.SpawnCEG

function gadget:ProjectileDestroyed(projID)
    local ceg=ProjUseCeg[projID]
    if ceg then
        local px,py,pz=spGetProjectilePosition(projID)
        local dx,dy,dz=spGetProjectileDirection(projID)
        spSpawnCEG(ceg,px,py,pz,dx,dy,dz)
        ProjUseCeg[projID]=nil
    end
end