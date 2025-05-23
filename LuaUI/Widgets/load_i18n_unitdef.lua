function widget:GetInfo()
	return {
		name      = "Load i18n by Unitdef",
		desc      = "Load i18n by Unitdef",
		author    = "XNTEABDSC",
		date      = "",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true,
	}
end

local wacky_utils=Spring.Utilities.wacky_utils

local jsonDecode=Spring.Utilities.json.decode

function widget:Initialize()
    local unit_translations=WG.translations.units.i18n
    for udid,ud in pairs(UnitDefs) do
        local udName=ud.name
        local udHumanName=ud.humanName
        local udDescription=ud.tooltip

        local udcp=ud.customParams
        local udtransJson=udcp.translations
        local suc,res=pcall(jsonDecode,udtransJson)
        if suc then
            local t={}
            for locale,trans in pairs(res) do
                t[locale]={
                    [udName]=trans
                }
            end
            unit_translations.load(t)
        end
        local udtransModStr=udcp.translations_modify
        local udtransMod=wacky_utils.justeval_errnil(udtransModStr)
        if udtransMod then 
            local udtransMod_src=udtransMod.srcUnit
            
        end
    end
end