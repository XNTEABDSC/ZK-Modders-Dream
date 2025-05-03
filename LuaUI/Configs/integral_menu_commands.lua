VFS.Include("LuaRules/Configs/customcmds.h.lua")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Order and State Panel Positions

-- Commands are placed in their position, with conflicts resolved by pushng those
-- with less priority (higher number = less priority) along the positions if
-- two or more commands want the same position.
-- The command panel is propagated left to right, top to bottom.
-- The state panel is propagate top to bottom, right to left.
-- * States can use posSimple to set a different position when the panel is in
--   four-row mode.
-- * Missing commands have {pos = 1, priority = 100}

---@diagnostic disable: undefined-global

local cmdPosDef = include("Configs/integral_menu_commands_orders.lua", nil, VFS.RAW_FIRST)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local factoryUnitPosDef = include("Configs/integral_menu_commands_factory.lua", nil, VFS.RAW_FIRST)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Construction Panel Structure Positions

-- These positions must be distinct

local factory_commands, econ_commands, defense_commands, special_commands = include("Configs/integral_menu_commands_build.lua", nil, VFS.RAW_FIRST)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------



VFS.Include("LuaRules/Utilities/wacky_utils.lua")
local utils=Spring.Utilities.wacky_utils

local tabs={
	ECON=econ_commands,
	DEFENSE=defense_commands,
	SPECIAL=special_commands,
	FACTORY=factory_commands,
}
for udid, ud in pairs(UnitDefs) do
	local udcp=ud.customParams
	if udcp then
		--[==[
		if udcp.integral_menu_factory_AddBuildQueue and tonumber(udcp.integral_menu_factory_AddBuildQueue)==1 then
			--AddBuildQueue(ud.name)
		end]==]
		if udcp.integral_menu_be_in_tab then
			local t=utils.justeval2(udcp.integral_menu_be_in_tab)
			local tab=t.tab
			local pos=t.pos
			tabs[tab][ud.name]=pos
		end
	end
end


local function AddBuildQueue(name)
	factoryUnitPosDef[name] = {}
	local ud = UnitDefNames[name]
	if ud and ud.buildOptions then
		local row = 1
		local col = 1
		local order = 1
		for i = 1, #ud.buildOptions do
			local buildName = UnitDefs[ud.buildOptions[i]].name
			if not factory_commands[buildName] and not econ_commands[buildName] and not defense_commands[buildName] and not special_commands[buildName] then
				factoryUnitPosDef[name][buildName] = {row = row, col = col, order = order}
				col = col + 1
				if col == 7 then
					col = 1
					row = row + 1
				end
				order = order + 1
			end
		end
	end
end

AddBuildQueue("striderhub")
AddBuildQueue("staticmissilesilo")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
---



local typeNames = {
	"CONSTRUCTOR",
	"RAIDER",
	"SKIRMISHER",
	"RIOT",
	"ASSAULT",
	"ARTILLERY",
	"WEIRD_RAIDER",
	"ANTI_AIR",
	"HEAVY_SOMETHING",
	"SPECIAL",
	"UTILITY",
}

-- Replicated here rather than included from integral_menu_commands to reduce
-- enduser footgun via local integral_menu_commands.
local unitTypes = {
	CONSTRUCTOR     = {order = 1, row = 1, col = 1},
	RAIDER          = {order = 2, row = 1, col = 2},
	SKIRMISHER      = {order = 3, row = 1, col = 3},
	RIOT            = {order = 4, row = 1, col = 4},
	ASSAULT         = {order = 5, row = 1, col = 5},
	ARTILLERY       = {order = 6, row = 1, col = 6},

	-- note: row 2 column 1 purposefully skipped, since
	-- that allows giving facs Attack orders via hotkey
	WEIRD_RAIDER    = {order = 7, row = 2, col = 2},
	ANTI_AIR        = {order = 8, row = 2, col = 3},
	HEAVY_SOMETHING = {order = 9, row = 2, col = 4},
	SPECIAL         = {order = 10, row = 2, col = 5},
	UTILITY         = {order = 11, row = 2, col = 6},
}

local typeNamesLower = {}
for i = 1, #typeNames do
	typeNamesLower[i] = "pos_" .. typeNames[i]:lower()
end

-- Tweakunits support
for unitName, factoryData in pairs(factoryUnitPosDef) do
	local ud = UnitDefNames[unitName]
	if ud then
		local cp = ud.customParams
		for i = 1, #typeNamesLower do
			local value = cp[typeNamesLower[i]]
			if value then
				factoryData[value] = unitTypes[typeNames[i]]
			end
		end
	end
end

return cmdPosDef, factoryUnitPosDef, factory_commands, econ_commands, defense_commands, special_commands

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
