local cmdPosDef, factoryUnitPosDef, factory_commands, econ_commands, defense_commands, special_commands = include("Configs/integral_menu_commands.lua")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Panel Configuration Loading



--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Support for tweakunits changing panel orders.

-- test case:
--e2ZhY3Rvcnl0YW5rID0gewpidWlsZG9wdGlvbnMgPSB7CltbY2xvYWtjb25dXSwKW1tzcGlkZXJzY291dF1dLApbW3ZlaHJhaWRdXSwKW1tob3ZlcnNraXJtXV0sCltbanVtcGJsYWNraG9sZV1dLApbW2d1bnNoaXBhYV1dLApbW2Nsb2Frc25pcGVdXSwKW1tndW5zaGlwaGVhdnlza2lybV1dLApbW3NwaWRlcmNyYWJlXV0sCltbYm9tYmVyZGlzYXJtXV0sCltbcGxhbmVmaWdodGVyXV0sCn0sCmN1c3RvbVBhcmFtcyA9IHsKcG9zX2NvbnN0cnVjdG9yPVtbY2xvYWtjb25dXSwKcG9zX3JhaWRlcj1bW3ZlaHJhaWRdXSwKcG9zX3dlaXJkX3JhaWRlcj1bW3NwaWRlcnNjb3V0XV0sCnBvc19za2lybWlzaGVyPVtbaG92ZXJza2lybV1dLApwb3NfcmlvdD1bW2p1bXBibGFja2hvbGVdXSwKcG9zX2FudGlfYWlyPVtbZ3Vuc2hpcGFhXV0sCnBvc19hc3NhdWx0PVtbY2xvYWtzbmlwZV1dLApwb3NfYXJ0aWxsZXJ5PVtbZ3Vuc2hpcGhlYXZ5c2tpcm1dXSwKcG9zX2hlYXZ5X3NvbWV0aGluZz1bW3NwaWRlcmNyYWJlXV0sCnBvc19zcGVjaWFsPVtbYm9tYmVyZGlzYXJtXV0sCnBvc191dGlsaXR5PVtbcGxhbmVmaWdodGVyXV0sCn19LH0K


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Translate to unitDefIDs

local buildCmdFactory = {}
local buildCmdEconomy = {}
local buildCmdDefence = {}
local buildCmdSpecial = {}
local buildCmdUnits   = {}

local function ProcessBuildArray(source, target)
	for name, value in pairs(source) do
		local udef = (UnitDefNames[name])
		if udef then
			target[-udef.id] = value
		elseif type(name) == "number" then
			-- Terraform
			target[name] = value
		end
	end
end

ProcessBuildArray(factory_commands, buildCmdFactory)
ProcessBuildArray(econ_commands, buildCmdEconomy)
ProcessBuildArray(defense_commands, buildCmdDefence)
ProcessBuildArray(special_commands, buildCmdSpecial)

for name, listData in pairs(factoryUnitPosDef) do
	local unitDefID = UnitDefNames[name]
	unitDefID = unitDefID and unitDefID.id
	if unitDefID then
		buildCmdUnits[unitDefID] = {}
		ProcessBuildArray(listData, buildCmdUnits[unitDefID])
	end
end


local tabs={
	ECON=buildCmdEconomy,
	DEFENSE=buildCmdDefence,
	SPECIAL=buildCmdSpecial,
	FACTORY=buildCmdFactory,
}

local modCommands = VFS.Include("LuaRules/Configs/modCommandsDefs.lua")
for i = 1, #modCommands do
	local cmd = modCommands[i]
	local needtab=cmd.at_integral_menu_tab
	if needtab and tabs[needtab] then
		tabs[needtab][cmd.cmdID]=cmd.position
	end
end

return buildCmdFactory, buildCmdEconomy, buildCmdDefence, buildCmdSpecial, buildCmdUnits, cmdPosDef, factoryUnitPosDef
