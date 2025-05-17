function gadget:GetInfo()
    return {
        name    = "Pieces Apply",
        desc    = "Use pieces of one unit to another, dynamically and pretty",
        author  = "XNTEABDSC, inspired by Pressure Lines's unit_changepiece.lua",
        date    = "",
        license = "GNU GPL, v2 or later",
        layer   = 50,
        enabled = false --loaded by default?
    }
end


local Pieces=GG.Pieces or {}
GG.Pieces=Pieces

local jsonencode=Spring.Utilities.json.encode
local jsondecode=Spring.Utilities.json.decode


---@class DynPieceInfoProcessed
---@field matrix {[integer]:number}?
---@field matrix2 {[integer]:number}?
---@field drawList integer?

---@type {[string]:DynPieceInfoProcessed}
local DynPieceInfos={}


local wacky_utils = Spring.Utilities.wacky_utils
local MultMatrix4x4 = wacky_utils.MultMatrix4x4
local NewMatrix4x4Unit = wacky_utils.NewMatrix4x4Unit


local spGetUnitDefID = Spring.GetUnitDefID
local spGetUnitPieceList = Spring.GetUnitPieceList
local spGetUnitPieceMap = Spring.GetUnitPieceMap



if (gadgetHandler:IsSyncedCode()) then
    
    
    ---@param infos DynPieceInfo
    ---@return {[integer]:DynPieceInfoProcessed}
    local function ProcessDynPieceInfos(unitDefId,infos)
        local result={}
        local unitPieces = Pieces.UnitsPieces[unitDefId]
        local unitPiecesMap = Pieces.UnitsPiecesMap[unitDefId]
        local unitPieceInfos = Pieces.UnitsPieceInfos[unitDefId]
        local unitPiecesMatrix = Pieces.UnitsPiecesMatrix[unitDefId]
        local unitPiecesParent = Pieces.UnitsPiecesParent[unitDefId]
        --local unitPieceDrawLists = Pieces.UnitsPieceDrawLists[unitDefId]
        ---@return {[integer]:number}
        local function GetMatrixFromAToB(a, b)
            local Matrix = NewMatrix4x4Unit() --UnitPiecesMatrix[a]
            local cur = a
            while (cur ~= nil and cur ~= b) do
                local Matrix2 = unitPiecesMatrix[cur]
                Matrix = MultMatrix4x4(Matrix, Matrix2)
                cur = unitPiecesParent[cur]
            end
            if cur == nil then
                Spring.Echo("unit_piece_apply: piece " ..
                tostring(unitPieces[a]) .. " dont have parent " .. tostring(unitPieces[b]))
            end
            return Matrix
        end

        ---@param info DynPieceInfo
        local function ProcessDynPieceInfo(info)
            local basePieceId = info.basePiece
            if type(basePieceId) == "string" then
                basePieceId = unitPiecesMap[basePieceId]
            end

            local matrix = info.matrixFromParent
            if type(matrix)=="table" then
            else
                if type(matrix)=="string" then
                    matrix=unitPiecesMap[matrix]
                end
                if type(matrix)=="number" then
                    matrix = GetMatrixFromAToB(basePieceId, matrix)
                end
            end
            ---@cast matrix table|nil
            -- ---@cast Matrix -unknown|nil
            local matrix2 = info.matrix2
            --[=[
        if Matrix2 then
            Matrix=MultMatrix44(Matrix2,Matrix)
        end]=]

            ---@type DynPieceInfoProcessed
            local o2 = {
                basePieceId = basePieceId,
                matrix = matrix,
                matrix2 = matrix2,
            }
            return o2
        end

        for k,v in pairs(infos) do
            result[k]=ProcessDynPieceInfo(v)
        end
        return result
    end
    
    
    local spSetUnitPieceMatrix = Spring.SetUnitPieceMatrix
    local spSetUnitPieceParent = Spring.SetUnitPieceParent
    local spGetUnitPieceMatrix = Spring.GetUnitPieceMatrix

    ---@param unitId UnitId
    ---@param tarPiece integer
    ---@param srcPieceInfo DynPieceInfoProcessed
    local function ApplyDynPieceInfo(unitId,tarPiece,srcPieceInfo)
        
        local matrix = srcPieceInfo.matrix or { spGetUnitPieceMatrix(unitId,tarPiece) }
        local matrix2 = srcPieceInfo.matrix2
        if matrix2 then
            matrix = MultMatrix4x4(matrix2, matrix)
        end
        spSetUnitPieceMatrix(unitId, tarPiece, matrix)
    end

    ---@param unitId UnitId
    ---@param tarPieceToSrcPieceInfo {[integer|string]:DynPieceInfoProcessed}
    local function ApplyDynPieceInfos(unitId,tarPieceToSrcPieceInfo)
        local pieceList = spGetUnitPieceList(unitId)
        local pieceMap = spGetUnitPieceMap(unitId)

        

        for k,v in pairs(tarPieceToSrcPieceInfo) do
            if type(k)=="string" then
                k=pieceMap[k]
            end
            ApplyDynPieceInfo(unitId,k,v)
        end
        
    end

    Pieces.ApplyDynPieceInfo = ApplyDynPieceInfo
    Pieces.ApplyDynPieceInfos = ApplyDynPieceInfos

    ---@class DynPieceInfo
    ---@field basePiece string|integer
    ---@field matrixFromParent {[integer]:number}|string|integer?
    ---@field matrix2 {[integer]:number}?
    ---@field drawPiece fun()|{ [integer]: integer|string|{piece:(integer|string),matrix:{[integer]:number}?,matrix2:{[integer]:number}?} }?

    local TryLoadUnitPiecesInfos=GG.Pieces.LoadUnitPiecesInfos

    function gadget:Initialize()
        TryLoadUnitPiecesInfos=GG.Pieces.LoadUnitPiecesInfos
    end

    ---@param dynPieceInfo {[string]:DynPieceInfo}
    local function CreateDynPieceInfo(unitDefId,dynPieceInfo)
        for k,v in pairs(dynPieceInfo) do
            if DynPieceInfos[k] then
                dynPieceInfo[k]=nil
            end
        end
        if DynPieceInfos[name] then return end
        TryLoadUnitPiecesInfos(unitDefId)
        local result=ProcessDynPieceInfos(unitDefId,dynPieceInfo)
        SendToUnsynced("CreateDynPieceInfos",unitDefId,jsonencode(dynPieceInfo))
        for k,v in pairs(result) do
            DynPieceInfos[k]=v
        end
    end
    Pieces.CreateDynPieceInfo=CreateDynPieceInfo
    
    ---@param unitId UnitId
    ---@param tarPieceToSrcPieceInfoNamed {[integer|string]:string} {[pieceIndex]:srcDynPieceName}
    local function ApplyDynPieceInfosNamed(unitId,tarPieceToSrcPieceInfoNamed)
        local tarPieceToSrcPieceInfo={}
        for k,v in pairs(tarPieceToSrcPieceInfoNamed) do
            tarPieceToSrcPieceInfo[k]=DynPieceInfos[v]
        end
        ApplyDynPieceInfos(unitId,tarPieceToSrcPieceInfo)
        local tarPieceToSrcPieceInfoJson=jsonencode(tarPieceToSrcPieceInfoNamed)
        Spring.Echo("send: " .. tarPieceToSrcPieceInfoJson)
        SendToUnsynced("ApplyDynPieceInfosNamed",unitId,tarPieceToSrcPieceInfoJson)
    end
    Pieces.ApplyDynPieceInfosNamed=ApplyDynPieceInfosNamed
else
    
    local glCreateList = gl.CreateList
    local glPushMatrix = gl.PushMatrix
    local glPopMatrix = gl.PopMatrix
    local glLoadMatrix = gl.LoadMatrix
    local glCallList = gl.CallList


    ---@param infos DynPieceInfo
    ---@return {[integer]:DynPieceInfoProcessed}
    local function ProcessDynPieceInfosUnsynced(unitDefId,infos)
        local result={}
        local unitPieces = Pieces.UnitsPieces[unitDefId]
        local unitPiecesMap = Pieces.UnitsPiecesMap[unitDefId]
        local unitPieceInfos = Pieces.UnitsPieceInfos[unitDefId]
        local unitPiecesMatrix = Pieces.UnitsPiecesMatrix[unitDefId]
        local unitPiecesParent = Pieces.UnitsPiecesParent[unitDefId]
        local unitPieceDrawLists = Pieces.UnitsPieceDrawLists[unitDefId]
        ---@return {[integer]:number}
        local function GetMatrixFromAToB(a, b)
            local Matrix = NewMatrix4x4Unit() --UnitPiecesMatrix[a]
            local cur = a
            while (cur ~= nil and cur ~= b) do
                local Matrix2 = unitPiecesMatrix[cur]
                Matrix = MultMatrix4x4(Matrix, Matrix2)
                cur = unitPiecesParent[cur]
            end
            if cur == nil then
                Spring.Echo("unit_piece_apply: piece " ..
                tostring(unitPieces[a]) .. " dont have parent " .. tostring(unitPieces[b]))
            end
            return Matrix
        end

        ---@param info DynPieceInfo
        local function ProcessDynPieceInfo(info)
            local basePieceId = info.basePiece
            if type(basePieceId) == "string" then
                basePieceId = unitPiecesMap[basePieceId]
            end

            local matrix = info.matrixFromParent
            if type(matrix)=="table" then
            else
                if type(matrix)=="string" then
                    matrix=unitPiecesMap[matrix]
                end
                if type(matrix)=="number" then
                    matrix = GetMatrixFromAToB(basePieceId, matrix)
                end
            end
            ---@cast matrix table|nil
            -- ---@cast Matrix -unknown|nil
            local matrix2 = info.matrix2
            --[=[
        if Matrix2 then
            Matrix=MultMatrix44(Matrix2,Matrix)
        end]=]
            local drawPieces = info.drawPiece
            local dList=nil
            if type(drawPieces)=="table" then
                dList=glCreateList(function()
                    for _, p in pairs(drawPieces) do
                        local pidx
                        local pMatrix
                        local pMatrix2
                        if type(p)=="table" then
                            pidx = p.piece
                            pMatrix = p.matrix
                            pMatrix2 = p.matrix2
                        else
                            pidx=p
                        end
                        if type(pidx) == "string" then
                            pidx = unitPiecesMap[pidx]
                        end
                        if not pMatrix then
                            pMatrix = GetMatrixFromAToB(pidx, basePieceId)
                        end
                        if pMatrix2 then
                            pMatrix = MultMatrix4x4(pMatrix2, pMatrix)
                        end
                        glPushMatrix()
                        glLoadMatrix(pMatrix)
                        glCallList(unitPieceDrawLists[pidx])
                        glPopMatrix()
                    end
                end)
            elseif type(drawPieces)=="function" then
                dList=glCreateList(drawPieces())
            elseif type(drawPieces)=="number" then
                dList=drawPieces
            else
                dList=nil
            end

            ---@type DynPieceInfoProcessed
            local o2 = {
                basePieceId = basePieceId,
                matrix = matrix,
                matrix2 = matrix2,
                drawList = dList,
            }
            return o2
        end

        for k,v in pairs(infos) do
            result[k]=ProcessDynPieceInfo(v)
        end
        return result
    end






    Pieces.ProcessDynPieceInfosUnsynced = ProcessDynPieceInfosUnsynced


    local SetupRendering
    do
        local surSetLODCount = Spring.UnitRendering.SetLODCount
        local surSetLODLength = Spring.UnitRendering.SetLODLength
        local surSetMaterial = Spring.UnitRendering.SetMaterial
        SetupRendering = function(unitID, unitDefID)
            --- why?
            surSetLODCount(unitID, 1)
            surSetLODLength(unitID, 1, -1000)
            -- ]=]
            -- [=[
            surSetMaterial(unitID, 1, "opaque",
                { shader = "s3o", texunit0 = '%' .. unitDefID .. ":0", texunit1 = '%' .. unitDefID .. ":1" })
            surSetMaterial(unitID, 1, "shadow", { shader = "s3o" })
            surSetMaterial(unitID, 1, "alpha", { shader = "s3o" })
        end
    end
    Pieces.SetupRendering=SetupRendering

    local surSetPieceList = Spring.UnitRendering.SetPieceList


    ---@param unitId UnitId
    ---@param tarPiece integer
    ---@param srcPieceInfo DynPieceInfoProcessed
    local function ApplyDynPieceInfoUnsynced(unitId,tarPiece,srcPieceInfo)
        
        local dList = srcPieceInfo.drawList
        if dList then
            Spring.Echo("Setting dList")
            surSetPieceList(unitId, 1, tarPiece, dList)
        end
    end

    ---@param unitId UnitId
    ---@param tarPieceToSrcPieceInfo {[integer|string]:DynPieceInfoProcessed}
    local function ApplyDynPieceInfosUnsynced(unitId,tarPieceToSrcPieceInfo)
        local pieceList = spGetUnitPieceList(unitId)
        local pieceMap = spGetUnitPieceMap(unitId)

        
        ---@cast pieceMap -nil
        SetupRendering(unitId, spGetUnitDefID(unitId))
        
        for pID,pName in pairs(pieceList) do --set all piece displaylists to default
            Spring.UnitRendering.SetPieceList(unitId,1,pID,nil)
        end

        for k,v in pairs(tarPieceToSrcPieceInfo) do
            if type(k)=="string" then
                k=pieceMap[k]
            end
            ApplyDynPieceInfoUnsynced(unitId,k,v)
        end
        
    end

    Pieces.ApplyDynPieceInfoUnsynced = ApplyDynPieceInfoUnsynced
    Pieces.ApplyDynPieceInfosUnsynced = ApplyDynPieceInfosUnsynced


    function gadget:Initialize()
        gadgetHandler:AddSyncAction("CreateDynPieceInfos",function(msg,unitDefId,dynPieceInfo)
            --ProcessDynPieceInfo
            local res=ProcessDynPieceInfosUnsynced(unitDefId,jsondecode(dynPieceInfo))
            for k,v in pairs(res) do
                DynPieceInfos[k]=v
            end
        end)
        gadgetHandler:AddSyncAction("ApplyDynPieceInfosNamed",
        
        ---@param msg string
        ---@param unitId UnitId 
        ---@param tarPieceToSrcPieceInfoJson string
        function(msg,unitId,tarPieceToSrcPieceInfoJson)
            Spring.Echo("receive: " .. tostring(tarPieceToSrcPieceInfoJson))
            local tarPieceToSrcPieceInfo=jsondecode(tarPieceToSrcPieceInfoJson)
            
            for k,v in pairs(tarPieceToSrcPieceInfo) do
                tarPieceToSrcPieceInfo[k]=DynPieceInfos[v]
            end
            Spring.Utilities.TableEcho(tarPieceToSrcPieceInfo)
            ApplyDynPieceInfosUnsynced(unitId,tarPieceToSrcPieceInfo)
        end)
    end
end
