function gadget:GetInfo()
	return {
		name      = "Dynamic Pieces",
		desc      = "Create DList for Pieces dynamically",
		author    = "XNTEABDSC, inspired by Pressure Lines's unit_changepiece.lua",
		date      = "",
		license   = "GNU GPL, v2 or later",
		layer     = 100,
		enabled   = true --loaded by default?
	}
end

--------------------------------------------------------------------------------

local Debug = true --turn on/off verbose debug messages

--------------------------------------------------------------------------------
--load Drawdefs
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--Displaylist table stuff
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--Stuff
--------------------------------------------------------------------------------

local gtID = Spring.GetGaiaTeamID()

--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
if (gadgetHandler:IsSyncedCode()) then --synced
--------------------------------------------------------------------------------

---UnitPieceDrawListsLoaded[UnitDefId][pieceid]=Loaded
---@type {[UnitDefId]:boolean}
local UnitsPieceDrawListsLoaded={}


---UnitPieceDrawListsLoaded[UnitDefId][pieceid]=needs load
---@type {[UnitDefId]:boolean}
local delayedLoadUnitsPieceDrawLists={}

local spCreateUnit=Spring.CreateUnit
local spSetUnitNeutral=Spring.SetUnitNeutral
local spDestroyUnit=Spring.DestroyUnit

function gadget:GameFrame()
	local temporaryUnitId={}
	for udid, _ in pairs(delayedLoadUnitsPieceDrawLists) do
		local newunitid=spCreateUnit(udid,64,65536,64,0,gtID)
		if not newunitid then
			Spring.Echo("unit_dynamic_piece.lua: Failed to create temporary unit for udid " .. tostring(udid))
		else
			temporaryUnitId[udid]=newunitid
			spSetUnitNeutral(newunitid,true)
		end
	end

	SendToUnsynced("LoadUnitsPieceDrawLists",temporaryUnitId)

	for udid,uid in pairs(temporaryUnitId) do
		UnitsPieceDrawListsLoaded[udid]=true
		spDestroyUnit(uid)
		delayedLoadUnitsPieceDrawLists[udid]=nil
	end
end

local function CheckLoadUnitPieceDrawList(unitDefId)
	local UnitPieceDrawListLoaded=UnitsPieceDrawListsLoaded[unitDefId]
	if not UnitPieceDrawListLoaded then
		return false
	else
		return true
	end
end

local function TryLoadUnitPieceDrawList(unitDefId)
	if CheckLoadUnitPieceDrawList(unitDefId) then
		return
	end
	local delayedLoadUnitPieceDrawLists=delayedLoadUnitsPieceDrawLists[unitDefId]
	if not delayedLoadUnitPieceDrawLists then
		delayedLoadUnitPieceDrawLists=true
		delayedLoadUnitsPieceDrawLists[unitDefId]=delayedLoadUnitPieceDrawLists
	end
end

GG.CheckLoadUnitPieceDrawList=CheckLoadUnitPieceDrawList
GG.TryLoadUnitPieceDrawList=TryLoadUnitPieceDrawList

--------------------------------------------------------------------------------
else --unsynced
--------------------------------------------------------------------------------


---UnitsPieceDrawLists[UnitDefId][pieceIdx]=DListID
---@type {[UnitDefId]:{[string|integer]:integer}}
local UnitsPieceDrawLists = {}
local spGetUnitPieceList=Spring.GetUnitPieceList
local spGetUnitPieceMap=Spring.GetUnitPieceMap
local glCreateList=gl.CreateList
local glPushAttrib=gl.PushAttrib
local glTexture=gl.Texture
local glUnitPiece=gl.UnitPiece
local glPopAttrib=gl.PopAttrib


local function LoadUnitPieceDrawLists(uid,udid)

	--local piecesmap = spGetUnitPieceMap(uid)
	local pieces=spGetUnitPieceList(uid)
	if not pieces then
		Spring.Echo("unit_dynamic_piece.lua: Failed to GetUnitPieceMap for unit " .. UnitDefs[udid].name)
		return
	end

	local UnitPieceDrawLists=UnitsPieceDrawLists[uid]
	if not UnitPieceDrawLists then
		UnitPieceDrawLists={}
		UnitsPieceDrawLists[uid]=UnitPieceDrawLists
	end

	for pieceId,pieceIndex in pairs(pieces) do

		if pieceId~=nil then
			
			---@cast pieceIndex -nil
			if Debug then Spring.Echo("unit_dynamic_piece.lua: Creating displaylist unit " .. UnitDefs[udid].name .. " 's piece " .. pieces[pieceIndex] ) end
			local DListId = glCreateList(function()
				glPushAttrib(GL.TEXTURE_BIT)
					glTexture(0,'%'..udid..":1")
					glUnitPiece(uid,pieceId)
					glTexture(0,'%'..udid..":0")
					glTexture(1,'%'..udid..":1")
					glUnitPiece(uid,pieceId)
				glPopAttrib()
			end)
			UnitPieceDrawLists[pieceId]=DListId
			UnitPieceDrawLists[pieceIndex]=DListId
		
		end
		
	end

end

local function SyncAction(fn)
	return function (msg,...)
		fn(...)
	end
end

local function LoadUnitsPieceDrawLists(temporaryUnitIds)
	for udid, uid in pairs(temporaryUnitIds) do
		LoadUnitPieceDrawLists(uid,udid)
	end
end

--- only unsynced
GG.UnitsPieceDrawLists=UnitsPieceDrawLists


local surSetPieceList=Spring.UnitRendering.SetPieceList

---@param pieceReplaces {[integer|string]:{udid:UnitDefId,pIdx:integer|string}}
local function SetUnitPieceReplace(unitID,pieceReplaces)
	local piecesMap = spGetUnitPieceMap(unitID)
	
	if not piecesMap then
		Spring.Utilities.UnitEcho(unitID,"unit_dynamic_piece.lua: Failed to GetUnitPieceMap for this unit")
		return
	end
	for pieceIndex,replaceInfo in pairs(pieceReplaces) do

		local pieceId
		if type(pieceIndex)=="string" then
			pieceId=piecesMap[pieceIndex]
		else
			pieceId=pieceIndex
		end
		if pieceId==nil then
			
			Spring.Utilities.UnitEcho(unitID,"unit_dynamic_piece.lua: Failed to find piece " .. tostring(pieceIndex) .." for this unit")
		else
			local pieceFromUdid=replaceInfo.udid
			local UnitPieceDrawLists=UnitsPieceDrawLists[pieceFromUdid]
			if not UnitPieceDrawLists then
				Spring.Utilities.UnitEcho(unitID,"unit_dynamic_piece.lua: Missing UnitsPieceDrawLists for unit " .. UnitDefs[pieceFromUdid].name)
			else
				local pieceFrom=replaceInfo.pIdx
				local UnitPieceDrawList=UnitPieceDrawLists[pieceFrom]
				if UnitPieceDrawList==nil then
					Spring.Utilities.UnitEcho(unitID,"unit_dynamic_piece.lua: Missing UnitsPieceDrawList " .. tostring(pieceFrom) .." for unit " .. UnitDefs[pieceFromUdid].name)
				else
					surSetPieceList(unitID,1,pieceId,UnitPieceDrawList)
				end
			end
		end
	end
end

--GG.SetUnitPieceReplace=SetUnitPieceReplace
--- I'll make a better one at another gadget, allows multiple binding

function gadget:Initialize()
	if Debug then
		Spring.Echo("unit_changepiece.lua: Initializing in debug mode")
		Spring.Echo("unit_changepiece.lua: To deactivate debug mode set 'Debug' to false in unit_changepiece.lua")
	else
		Spring.Echo("unit_changepiece.lua: Initializing in game mode")
		Spring.Echo("unit_changepiece.lua: To activate debug mode set 'Debug' to true in unit_changepiece.lua")
	end
	gadgetHandler:AddSyncAction("LoadUnitsPieceDrawLists",SyncAction(LoadUnitsPieceDrawLists))
	--gadgetHandler:AddSyncAction("SetUnitPieceReplace",SyncAction(SetUnitPieceReplace))
	Spring.Echo("unit_changepiece.lua: Initialization complete")
end --eof


--------------------------------------------------------------------------------
end
--------------------------------------------------------------------------------