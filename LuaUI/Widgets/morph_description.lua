function widget:GetInfo()
	return {
		name      = "Morph Description",
		desc      = "Put Moeph data in description so people can see it",
		author    = "XNTEABDSC",
		date      = "",
		license   = "GNU GPL, v2 or later",
		layer     = -10000,
		enabled   = true,
	}
end

local morphDefs

local function onLangChanged(locale)
    locale=locale or "en"
    
    local unit_translations=WG.translations.units.i18n
    local t={}
    local tlocale={}
    t[locale]=tlocale
    for udid,morphData in pairs(morphDefs) do
        local udName=UnitDefs[udid].name
        local descstr=WG.Translate("units",udName .. ".description") or UnitDefs[udid].description
        --[=[
        for _,tarmorphData in pairs(morphData) do
            local tarUdid=tarmorphData.into
            local tarudHumanname=Spring.Utilities.GetHumanName(UnitDefs[tarUdid])
            descstr=descstr .. ". Can morph to " .. tarudHumanname
        end
        ]=]
        descstr=descstr .. ". Can morph"
        tlocale[udName]={}
        tlocale[udName].description=descstr
    end
    unit_translations.load(t)
end



function widget:Initialize()
    morphDefs, MAX_MORPH = VFS.Include("LuaRules/Configs/morph_defs.lua",Spring.Utilities.wacky_utils.getenv_merge({GG={}}))
	if (not morphDefs) then
		gadgetHandler:RemoveGadget()
		return
	end
    WG.InitializeTranslation (onLangChanged, widget:GetInfo().name)
end