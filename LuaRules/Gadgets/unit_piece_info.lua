---Call TryLoadUnitPieceDrawList at synced gadget to load all drawlists of pieces of a unit.
---GG.UnitsPieceDrawLists at unsynced contains drawlists

function gadget:GetInfo()
	return {
		name      = "Pieces Drawlist",
		desc      = "Create Drawlist for Pieces dynamically",
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


local spGetUnitPieceList=Spring.GetUnitPieceList
local spGetUnitPieceMap=Spring.GetUnitPieceMap
local spGetUnitPieceInfo=Spring.GetUnitPieceInfo
local spGetUnitPieceMatrix=Spring.GetUnitPieceMatrix
local spGetUnitRootPiece=Spring.GetUnitRootPiece

local gtID = Spring.GetGaiaTeamID()
local Pieces=GG.Pieces or {}
GG.Pieces=Pieces
---@type {[UnitDefId]:{[integer]:PieceInfo}}
local UnitsPieceInfos={}

---@type {[UnitDefId]:{[integer]:string}}
local UnitsPieces={}

---@type {[UnitDefId]:integer}
local UnitsPieceRoot={}
---@type {[UnitDefId]:{[string]:integer}}
local UnitsPiecesMap={}


---@type {[UnitDefId]:{[integer]:PieceInfo}}
local UnitsPiecesMatrix={}


---@type {[UnitDefId]:{[integer]:integer}}
local UnitsPiecesParent={}

Pieces.UnitsPieceInfos=UnitsPieceInfos
Pieces.UnitsPieces=UnitsPieces
Pieces.UnitsPieceRoot=UnitsPieceRoot
Pieces.UnitsPiecesMap=UnitsPiecesMap
Pieces.UnitsPiecesMatrix=UnitsPiecesMatrix
Pieces.UnitsPiecesParent=UnitsPiecesParent


---@param uid UnitId
---@param udid UnitDefId
local function LoadUnitPieceDatas(uid,udid)

	--local piecesmap = spGetUnitPieceMap(uid)
	local pieces=spGetUnitPieceList(uid)
	if not pieces then
		Spring.Echo("unit_piece_info.lua: Failed to GetUnitPieceMap for unit " .. UnitDefs[udid].name)
		return
	end
	UnitsPieces[udid]=pieces
	local piecesMap=spGetUnitPieceMap(uid)
	---@cast piecesMap -nil
	UnitsPiecesMap[udid]=piecesMap

	

	local UnitPieceDrawInfos={}
	UnitsPieceInfos[udid]=UnitPieceDrawInfos

	local UnitPiecesMatrix={}
	UnitsPiecesMatrix[udid]=UnitPiecesMatrix
	
	UnitsPieceRoot[udid]=spGetUnitRootPiece(uid)

	for pieceId,pieceIndex in pairs(pieces) do

		local PieceInfo=spGetUnitPieceInfo(uid,pieceId)
		---@cast PieceInfo -nil
		UnitPieceDrawInfos[pieceId]=PieceInfo
		
		UnitPiecesMatrix[pieceId]={spGetUnitPieceMatrix(uid,pieceId)}
		UnitsPiecesParent[pieceId]=piecesMap[PieceInfo.parent or 1]--PieceInfo
		--GetUnitPieceMatrix
		--UnitsPiecesRoot
	end

end

--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
if (gadgetHandler:IsSyncedCode()) then --synced
--------------------------------------------------------------------------------


local spCreateUnit=Spring.CreateUnit
local spSetUnitNeutral=Spring.SetUnitNeutral
local spDestroyUnit=Spring.DestroyUnit

local function LoadUnitPiecesInfos(udid)
	if UnitsPieces[udid] then
		return
	end

	if Debug then Spring.Echo("unit_piece_info.lua: TryLoadUnitPiecesInfos " .. tostring( UnitDefs[udid].name )) end
		
	local uid=spCreateUnit(udid,64,65536,64,0,gtID)
	if not uid then
		Spring.Echo("unit_piece_info.lua: Failed to create temporary unit for udid " .. tostring(udid))
	else
		spSetUnitNeutral(uid,true)
		LoadUnitPieceDatas(uid,udid)
		SendToUnsynced("LoadUnitPieceDatas",uid,udid)
		spDestroyUnit(uid)
	end
	
end

Pieces.LoadUnitPiecesInfos=LoadUnitPiecesInfos

--------------------------------------------------------------------------------
else --unsynced
--------------------------------------------------------------------------------


---UnitsPieceDrawLists[UnitDefId][pieceIdx]=DListID
---@type {[UnitDefId]:{[string|integer]:integer}}
local UnitsPieceDrawLists = {}

Pieces.UnitsPieceDrawLists=UnitsPieceDrawLists


local glCreateList=gl.CreateList
local glPushAttrib=gl.PushAttrib
local glTexture=gl.Texture
local glUnitPiece=gl.UnitPiece
local glPopAttrib=gl.PopAttrib


---@param uid UnitId
---@param udid UnitDefId
local function LoadUnitPieceDrawLists(uid,udid)

	--local piecesmap = spGetUnitPieceMap(uid)
	local pieces=spGetUnitPieceList(uid)
	if not pieces then
		Spring.Echo("unit_piece_info.lua: Failed to GetUnitPieceMap for unit " .. UnitDefs[udid].name)
		return
	end

	local UnitPieceDrawLists={}
	UnitsPieceDrawLists[udid]=UnitPieceDrawLists

	for pieceId,pieceIndex in pairs(pieces) do
		if Debug then Spring.Echo("unit_piece_info.lua: Creating displaylist unit " .. tostring( UnitDefs[udid].name ) .. " 's piece " .. tostring(pieceIndex) ) end
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


--- only unsynced


local surSetPieceList=Spring.UnitRendering.SetPieceList
--[=[
---@param pieceReplaces {[integer|string]:{udid:UnitDefId,pIdx:integer|string}}
local function SetUnitPieceReplace(unitID,pieceReplaces)
	local piecesMap = spGetUnitPieceMap(unitID)
	
	if not piecesMap then
		Spring.Utilities.UnitEcho(unitID,"unit_piece_info.lua: Failed to GetUnitPieceMap for this unit")
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
			
			Spring.Utilities.UnitEcho(unitID,"unit_piece_info.lua: Failed to find piece " .. tostring(pieceIndex) .." for this unit")
		else
			local pieceFromUdid=replaceInfo.udid
			local UnitPieceDrawLists=UnitsPieceDrawLists[pieceFromUdid]
			if not UnitPieceDrawLists then
				Spring.Utilities.UnitEcho(unitID,"unit_piece_info.lua: Missing UnitsPieceDrawLists for unit " .. UnitDefs[pieceFromUdid].name)
			else
				local pieceFrom=replaceInfo.pIdx
				local UnitPieceDrawList=UnitPieceDrawLists[pieceFrom]
				if UnitPieceDrawList==nil then
					Spring.Utilities.UnitEcho(unitID,"unit_piece_info.lua: Missing UnitsPieceDrawList " .. tostring(pieceFrom) .." for unit " .. UnitDefs[pieceFromUdid].name)
				else
					surSetPieceList(unitID,1,pieceId,UnitPieceDrawList)
				end
			end
		end
	end
end
]=]
--GG.SetUnitPieceReplace=SetUnitPieceReplace
--- I'll make a better one at another gadget, allows multiple binding

function gadget:Initialize()
	--gadgetHandler:AddSyncAction("LoadUnitsPieceDrawLists",SyncAction(LoadUnitsPieceDrawLists))
	gadgetHandler:AddSyncAction("LoadUnitPieceDatas",function(msg,uid,udid)
		LoadUnitPieceDatas(uid,udid)
		LoadUnitPieceDrawLists(uid,udid)
	end)
	--gadgetHandler:AddSyncAction("SetUnitPieceReplace",SyncAction(SetUnitPieceReplace))
end --eof


--------------------------------------------------------------------------------
end
--------------------------------------------------------------------------------