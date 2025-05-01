---[=[
--- different from scripts/scriptreload.lua
--- this gadget stores charge, that 
--- increase when units' weapons are not reloading ,
--- while shift to units' reloadFrame when weapons need it, with the rate canShiftChargePerFrame
--- you can set wd.customParams.use_unit_weapon_charging_salvo=true to let it works automatically,
--- 
--- ChargeExtra = wdcp.script_burst-1 
--- canShiftChargePerFrame = 30/wdcp.script_burst_rate
--- reloadBurstPerSecont = spGetUnitWeaponState(uid,wpnnum,"reloadTime")
--- 
---]=]


VFS.Include("LuaRules/Utilities/wacky_utils.lua")
local utils=Spring.Utilities.wacky_utils

local INLOS_ACCESS={
    inlos=true
}
if not gadgetHandler:IsSyncedCode() then
	return
end

function gadget:GetInfo()
	return {
		name      = "Unit Weapon Charging Salvo",
		desc      = "Implement Unit Weapon Charge via gadget to avoid script spam",
		author    = "XNTEABDSC",
		date      = "",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true,  --  loaded by default?
	}
end

---ChargeDataWDs[wdid]={chargeExtra,canShiftChargePerFrame,reloadTimePerBurst}?
---@type {[WeaponDefId]:{chargeExtra:integer,canShiftChargePerFrame:integer}}
local ChargeDataWDs={}

---ChargeDataUDsHas[udid]=list<[wpnnum,wdid]>
---@type {[UnitDefId]:list<[integer,WeaponDefId]>}
local ChargeDataUDsHas={}

---ChargeDatas[uid][wpnnum]={chargeExtra,canShiftChargePerFrame,reloadTimePerBurst,currentCharge,lastFrame}
---@type {[UnitId]:{[integer]:{chargeExtra:integer,canShiftChargePerFrame:integer,currentCharge:number,lastFrame:integer}}}
local ChargeDatas={}

---@type {[UnitId]:string}
local ChargeDatas_UWCHas={}

local spGetGameFrame=Spring.GetGameFrame
local spSetUnitWeaponState=Spring.SetUnitWeaponState
local spGetUnitWeaponState=Spring.GetUnitWeaponState
local spGetUnitIsStunned=Spring.GetUnitIsStunned
local spGetUnitRulesParam=Spring.GetUnitRulesParam
local spSetUnitRulesParam=Spring.SetUnitRulesParam

---commented
---@param unitId UnitId
---@param wpnnum integer
---@return {chargeExtra:integer,canShiftChargePerFrame:integer,currentCharge:number}|nil
local function GetUnitWeaponChargeState(unitId,wpnnum)
    local sdu=ChargeDatas[unitId]
    if not sdu then
        return nil
    end
    local sduw=sdu[wpnnum]
    if not sduw then
        return nil
    end
    return sduw
end

GG.GetUnitWeaponChargeState=GetUnitWeaponChargeState

for wdid, wd in pairs(WeaponDefs) do -- set ChargeDataWDs
    local wdcp=wd.customParams
    if wdcp.use_unit_weapon_charging_salvo then
        local script_burst=tonumber( wdcp.script_burst )
        local script_burst_rate=tonumber(wdcp.script_burst_rate)
        
        if script_burst and script_burst_rate then
            ChargeDataWDs[wdid]={
                chargeExtra=script_burst-1,
                canShiftChargePerFrame=1/script_burst_rate/30,
            }
            --Spring.Echo("unit_weapon_charging_salvo.lua: loaded weapondef " .. tostring(wd.name) .. " wdid " .. wdid .. " chargeExtra: " .. script_burst-1 .. " canShiftChargePerFrame: " .. (1/script_burst_rate/30))
        else
            Spring.Echo("Warning: unit_weapon_charging_salvo.lua: Bad unit_weapon_charging_salvo def for weapondef " .. tostring( wd.name))
        end
    end
end

for udid, ud in pairs(UnitDefs) do -- set ChargeDataUDHas
    local wpns=ud.weapons
    if wpns then
        for wpnnum, value in pairs(wpns) do
            local wdid=value.weaponDef
            local wd=WeaponDefs[wdid]
            if ChargeDataWDs[wdid] then
                local ChargeDataUDHas=ChargeDataUDsHas[udid] or {}
                ChargeDataUDsHas[udid]=ChargeDataUDHas
                ChargeDataUDHas[#ChargeDataUDHas+1] = {wpnnum,wdid}
                --Spring.Echo("unit_weapon_charging_salvo.lua: loaded unitdef " .. tostring(ud.name) .. " which has gbs weapon slot " .. wpnnum)
            end
        end
        
    end
end


---Add GoodBurstChargeData for unit's weapon, 
---@param uid UnitId
---@param wpnnum integer
---@param chargeDataW {chargeExtra:integer,canShiftChargePerFrame:integer,currentCharge:number,lastFrame:integer}|nil
---@param currentCharge number?
---@param lastFrame number?
---@param chargeExtra number?
---@param canShiftChargePerFrame number?
local function SetUnitWeaponChargeData(uid,wpnnum,chargeDataW,currentCharge,lastFrame,chargeExtra,canShiftChargePerFrame)
    local chargeData
    if not chargeDataW then
        chargeData=ChargeDatas[uid]
        if not chargeData then -- create chargeData for unit
            chargeData={}
            ChargeDatas[uid]=chargeData
            ChargeDatas_UWCHas[uid]=""
        end
        chargeDataW = chargeData[wpnnum]
    end
    if not chargeDataW then -- create a chargeDataW for unit weapon

        local rulesParamStr=ChargeDatas_UWCHas[uid]
        rulesParamStr=rulesParamStr .. tostring(wpnnum) .. " "
        ChargeDatas_UWCHas[uid]=rulesParamStr
        spSetUnitRulesParam(uid,"UWCHas",rulesParamStr,INLOS_ACCESS)

        if chargeExtra==nil then
            Spring.Utilities.UnitEcho(uid,"Error: unit_weapon_charging_salvo.lua: SetUnitGoodBurstChargeData: While Creating, Missing chargeExtra for unit wpnnum " .. wpnnum .. " fn blocked")
            return
        end

        if canShiftChargePerFrame==nil then
            Spring.Utilities.UnitEcho(uid,"Error: unit_weapon_charging_salvo.lua: SetUnitGoodBurstChargeData: While Creating, Missing canShiftChargePerFrame for unit wpnnum " .. wpnnum .. " fn blocked")
            return
        end

        if lastFrame==nil then
            --Spring.Utilities.UnitEcho(uid,"Warning: unit_weapon_charging_salvo.lua: SetUnitGoodBurstChargeData: Missing lastFrame for unit wpnnum " .. wpnnum .. ", use gameframe")
            --Spring.Echo("Warning: unit_weapon_charging_salvo.lua: SetUnitGoodBurstChargeData: Missing lastFrame for unit")
            lastFrame=spGetGameFrame()
        end

        if currentCharge==nil then
            currentCharge=chargeExtra
        end
        chargeDataW={
            lastFrame=lastFrame,
            chargeExtra=chargeExtra,
            canShiftChargePerFrame=canShiftChargePerFrame,
            currentCharge=currentCharge,
        }
        chargeData[wpnnum]=chargeDataW
        spSetUnitRulesParam(uid,"UWCLastFrameOnWpn"..wpnnum,lastFrame,INLOS_ACCESS)
        spSetUnitRulesParam(uid,"UWCChargeExtraOnWpn"..wpnnum,chargeExtra,INLOS_ACCESS)
        spSetUnitRulesParam(uid,"UWCShiftChargeOnWpn"..wpnnum,canShiftChargePerFrame,INLOS_ACCESS)
        spSetUnitRulesParam(uid,"UWCChargeOnWpn"..wpnnum,currentCharge,INLOS_ACCESS)
    else
        if lastFrame then
            chargeDataW.lastFrame=lastFrame
            spSetUnitRulesParam(uid,"UWCLastFrameOnWpn"..wpnnum,lastFrame,INLOS_ACCESS)
        end
        if chargeExtra then
            chargeDataW.chargeExtra=chargeExtra
            spSetUnitRulesParam(uid,"UWCChargeExtraOnWpn"..wpnnum,chargeExtra,INLOS_ACCESS)
        end
        if canShiftChargePerFrame then
            chargeDataW.canShiftChargePerFrame=canShiftChargePerFrame
            spSetUnitRulesParam(uid,"UWCShiftChargeOnWpn"..wpnnum,canShiftChargePerFrame,INLOS_ACCESS)
        end
        if currentCharge then
            chargeDataW.currentCharge=currentCharge
            spSetUnitRulesParam(uid,"UWCChargeOnWpn"..wpnnum,currentCharge,INLOS_ACCESS)
        end
    end
end


local function RemoveUnitGoodBurstSalvo(uid,wpnnum)
    local chargeData=ChargeDatas[uid]
    chargeData[wpnnum]=nil
    spSetUnitRulesParam(uid,"UWCLastFrameOnWpn"..wpnnum,nil,INLOS_ACCESS)
    spSetUnitRulesParam(uid,"UWCChargeExtraOnWpn"..wpnnum,nil,INLOS_ACCESS)
    spSetUnitRulesParam(uid,"UWCShiftChargeOnWpn"..wpnnum,nil,INLOS_ACCESS)
    spSetUnitRulesParam(uid,"UWCChargeOnWpn"..wpnnum,nil,INLOS_ACCESS)

    local rulesParamStr=""
    for k, _ in pairs(chargeData) do
        rulesParamStr=rulesParamStr .. tostring(k) .. " "
    end
    ChargeDatas_UWCHas[uid]=rulesParamStr
    spSetUnitRulesParam(uid,"UWCHas",rulesParamStr,INLOS_ACCESS)
end

function gadget:UnitCreated(unitId,unitDefId,unitTeamId)
    local ChargeDataUDHas=ChargeDataUDsHas[unitDefId]
    if ChargeDataUDHas then
        for _, v in pairs(ChargeDataUDHas) do
            local wpnnum,wdid=v[1],v[2]
            local ChargeDataWD=ChargeDataWDs[wdid]
            if not ChargeDataWD then
                Spring.Echo("Error: unit_weapon_charging_salvo.lua: Wrong ChargeDataUDsHas for unitdefid " .. tonumber(unitDefId) .. " wpnnum: " .. tonumber(wpnnum) .. " wdid: " .. tonumber(wdid) .. " is not a good_burst_salvo")
                --break
            else
                SetUnitWeaponChargeData(unitId,wpnnum,nil,ChargeDataWD.chargeExtra,spGetGameFrame(),ChargeDataWD.chargeExtra,ChargeDataWD.canShiftChargePerFrame)
                --[=[
                ChargeData[wpnnum]={
                    chargeExtra=ChargeDataWD.chargeExtra,
                    canShiftChargePerFrame=ChargeDataWD.canShiftChargePerFrame,
                    --reloadChargePerFrame=ChargeDataWD.reloadChargePerFrame,
                    currentCharge=ChargeDataWD.chargeExtra,
                    lastFrame=spGetGameFrame()
                }]=]
            end
        end
    end
end

function gadget:UnitDestroyed(unitId)
    ChargeDatas[unitId]=nil
end


local spGetAllUnits=Spring.GetAllUnits
local str_explode=utils.str_explode
function gadget:Initialize()
    for _, uid in pairs(spGetAllUnits()) do
        local UWCHas=spGetUnitRulesParam(uid,"UWCHas")
        if UWCHas and type(UWCHas)=="string" then
            local ChargeData={}
            ChargeDatas[uid]=ChargeData
            ChargeDatas_UWCHas[uid]=UWCHas
            local tb=str_explode(" ",UWCHas)
            if tb then
                for _, wpnnum in pairs(tb) do
                    wpnnum=tonumber(wpnnum)
                    if wpnnum~=nil then
                        local lastFrame=spGetUnitRulesParam(uid,"UWCLastFrameOnWpn"..wpnnum)
                        local chargeExtra=spGetUnitRulesParam(uid,"UWCChargeExtraOnWpn"..wpnnum)
                        local canShiftChargePerFrame=spGetUnitRulesParam(uid,"UWCShiftChargeOnWpn"..wpnnum)
                        local currentCharge=spGetUnitRulesParam(uid,"UWCChargeOnWpn"..wpnnum)
    
                        ChargeData[wpnnum]={
                            lastFrame=lastFrame,
                            chargeExtra=chargeExtra,
                            canShiftChargePerFrame=canShiftChargePerFrame,
                            currentCharge=currentCharge
                        }
                    else
                        Spring.Utilities.UnitEcho(uid,"Error: unit_weapon_charging_salvo.lua: Bad UnitRulesParam UWCHas for unit, UWCHas: " .. tostring(UWCHas))
                    end
                end
            else
                Spring.Utilities.UnitEcho(uid,"Error: unit_weapon_charging_salvo.lua: Bad UnitRulesParam UWCHas for unit, UWCHas: " .. tostring(UWCHas))
            end
        else
            --Spring.Utilities.UnitEcho(uid,"Error: unit_weapon_charging_salvo.lua: Bad UnitRulesParam UWCHas for unit, UWCHas: " .. tostring(UWCHas))
        end
    end
end

local mmax=math.max
local mmin=math.min
local floor=math.floor

local ALLY_ACCESS = {allied = true}

---commented
---@param uid UnitId
-- ---@param chargeData {[integer]:{chargeExtra:integer,canShiftChargePerFrame:integer,reloadChargePerFrame:integer,currentCharge:number,lastFrame:integer}}
---@param wpnnum integer
---@param reloadMult number
---@param chargeDataW {chargeExtra:integer,canShiftChargePerFrame:integer,currentCharge:number,lastFrame:integer}
---@param f integer
local function ProcessChargeData(uid,wpnnum, chargeDataW,reloadMult,f)
    local deltaFrame=f-chargeDataW.lastFrame

    local chargeExtra=chargeDataW.chargeExtra
    local canShiftChargePerFrame=chargeDataW.canShiftChargePerFrame
    local currentCharge=chargeDataW.currentCharge
    local chargeFull= (currentCharge>=chargeExtra)

    
    local currentReloadFrame=spGetUnitWeaponState(uid,wpnnum,"reloadFrame")

    local reloadFramePerBurst=spGetUnitWeaponState(uid,wpnnum,"reloadTime")*30 -- notes that this contains reloadMult already

    local reloadChargePerFrame=1/reloadFramePerBurst

    local reloadFrameLast=currentReloadFrame-f

    --[=[
    Spring.Echo("DEBUG: unit_weapon_charging_salvo.lua: reloadFrameLast: " .. tostring(reloadFrameLast))
    Spring.Echo("DEBUG: unit_weapon_charging_salvo.lua: currentCharge: " .. tostring(currentCharge))
    ]=]



    if reloadFrameLast<0 then -- reload finish
        if not chargeFull then-- +charge
            currentCharge=currentCharge+reloadChargePerFrame*deltaFrame
        else
        end
    else -- reload not finish, 
        if currentCharge>0 then-- charge -> reload
            --Convert some Charge into reloadFrame
            --
            local canShiftCharge=mmin( deltaFrame*reloadMult*canShiftChargePerFrame,currentCharge)
            local canShiftReloadFrame=canShiftCharge*reloadFramePerBurst-1
            local ShiftReloadFrame=mmin(canShiftReloadFrame,reloadFrameLast)
            local ShiftCharge=ShiftReloadFrame*reloadChargePerFrame
            --[=[
            Spring.Echo("DEBUG: unit_weapon_charging_salvo.lua: reloadFramePerBurst: " .. tostring(reloadFramePerBurst))
            Spring.Echo("DEBUG: unit_weapon_charging_salvo.lua: canShiftChargePerFrame: " .. tostring(canShiftChargePerFrame))
            Spring.Echo("DEBUG: unit_weapon_charging_salvo.lua: canShiftCharge: " .. tostring(canShiftCharge))
            Spring.Echo("DEBUG: unit_weapon_charging_salvo.lua: ShiftCharge: " .. tostring(ShiftCharge))
            ]=]

            
            spSetUnitWeaponState(uid,wpnnum,"reloadFrame",currentReloadFrame-ShiftReloadFrame)
            currentCharge=currentCharge-ShiftCharge
            
            
        end
    end

    
    local scriptLoaded=currentCharge + (1-mmax(reloadFrameLast,0)*reloadChargePerFrame)
    ---@type number|nil
    local scriptReloadFrame=f+mmax(reloadFrameLast,0)+(chargeExtra-currentCharge)*reloadFramePerBurst
    if currentCharge>=chargeExtra then
        currentCharge=chargeExtra
        scriptReloadFrame=nil
    end

    spSetUnitRulesParam(uid, "scriptLoaded", scriptLoaded, ALLY_ACCESS)
    spSetUnitRulesParam(uid, "scriptReloadFrame", scriptReloadFrame, ALLY_ACCESS)


    SetUnitWeaponChargeData(uid,wpnnum,chargeDataW,currentCharge,f)
    --[=[
    chargeDataW.currentCharge=currentCharge
    chargeDataW.lastFrame=f
    spSetUnitRulesParam(uid,"UWCLastFrame",f)
    spSetUnitRulesParam(uid,"UWCCharge",currentCharge)
    --]=]
    
    --[=[
    spSetUnitRulesParam(uid,"UWCChargeExtra",chargeExtra)
    spSetUnitRulesParam(uid,"UWCCanShiftChargePerFrame",canShiftChargePerFrame)
    ]=]
end

function gadget:GameFrame(f)
    --local chooosenum=f%3
    for uid, chargeData in pairs(ChargeDatas) do
        do
            local isStunned=spGetUnitIsStunned(uid)
            if not isStunned then
                local reloadMult = (spGetUnitRulesParam(uid, "totalReloadSpeedChange") or 1)
                ---@cast reloadMult number
                for wpnnum, chargeDataW in pairs(chargeData) do 
                    ProcessChargeData(uid, wpnnum,chargeDataW, reloadMult,f)
                end
            end
        end
    end
end

GG.GoodBurstSalvo={
    SetUnitWeaponChargeData=SetUnitWeaponChargeData,
    ChargeDatas=ChargeDatas,
    ChargeDataWDs=ChargeDataWDs,
    ChargeDataUDsHas=ChargeDataUDsHas
}

--[=[
---commented
---@param pid ProjectileId
---@param uid UnitId
---@param wdid WeaponDefId
function gadget:ProjectileCreated(pid,uid,wdid)
    
end
]=]