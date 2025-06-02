function widget:GetInfo()
	return {
		name      = "Load i18n by Unitdef",
		desc      = "Load i18n by Unitdef",
		author    = "XNTEABDSC",
		date      = "",
		license   = "GNU GPL, v2 or later",
		layer     = math.huge,
		enabled   = true,
	}
end

local wacky_utils=Spring.Utilities.wacky_utils

local jsonDecode=Spring.Utilities.json.decode

local translationCopyKeys={"name","description","helptext"}

local udsTranslationCopy={}

local udsTranslationModify={}

for udid,ud in pairs(UnitDefs) do
    local udName=ud.name
    local udcp=ud.customParams
    local udtransCopy=udcp.translations_copy_from
    if udtransCopy then
        local srcUnit=UnitDefNames[udtransCopy]
        udsTranslationCopy[udName]=srcUnit.name
    end

    local udTranslationModifyStr=udcp.translations
    if udTranslationModifyStr then
        local udTranslationModify=wacky_utils.justeval_errnil(udTranslationModifyStr)
        if udTranslationModify then
            udsTranslationModify[udName]=udTranslationModify
            Spring.Echo("Debug: Setting unit " .. udName .. "'s udTranslationModify")
        else
            Spring.Log(widget:GetInfo().name,LOG.WARNING, "Failed to load translation of unit " .. udName)
        end
    end

end

local table_repalce=Spring.Utilities.wacky_utils.table_replace

local function onLangChanged(locale)
    locale=locale or 'en'
    Spring.Echo("Debug: onLangChanged " .. locale)
    local unit_translations=WG.translations.units.i18n
    local t={}
    local tlocale={}
    t[locale]=tlocale
    for toUnitName, srcUnitName in pairs(udsTranslationCopy) do
        
        local a={}
        for _,transKey in pairs(translationCopyKeys) do
            a[transKey]=WG.Translate("units",srcUnitName .. "." .. transKey)
        end
        tlocale[toUnitName]=a
        
    end
    for toUnitName, translations in pairs(udsTranslationModify) do
        Spring.Echo("Debug: using translations for unit " .. toUnitName)
        local translationLocale=translations[locale]
        if translationLocale then
            local a=tlocale[toUnitName] or {}
            for _,transKey in pairs(translationCopyKeys) do
                a[transKey]=a[transKey] or WG.Translate("units",toUnitName .. "." .. transKey)
            end
            table_repalce(translationLocale)(a)
            tlocale[toUnitName]=a
        else
            
            Spring.Echo("Debug: no locale" .. locale)
        end
    end
    unit_translations.load(t)
end

function widget:Initialize()
    WG.InitializeTranslation (onLangChanged, widget:GetInfo().name)
end

