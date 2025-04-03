
VFS.Include("LuaRules/Utilities/ordered_list.lua")
local ordered_list=Spring.Utilities.OrderedList


local ordered_includes=ordered_list.New()


local includes = {
	--"headers/autolocalizer.lua",
	"headers/util.lua",
	"headers/links.lua",
	"headers/backwardcompability.lua",
	"headers/unicode.lua",
	
	"handlers/debughandler.lua",
	"handlers/taskhandler.lua",
	"handlers/skinhandler.lua",
	"handlers/themehandler.lua",
	"handlers/fonthandler.lua",
	"handlers/texturehandler.lua",
  
	"controls/object.lua",
	"controls/font.lua",
	"controls/control.lua",
	"controls/screen.lua",
	"controls/window.lua",
	"controls/label.lua",
	"controls/button.lua",
	"controls/editbox.lua",
	"controls/textbox.lua", -- uses editbox
	"controls/checkbox.lua",
	"controls/trackbar.lua",
	"controls/colorbars.lua",
	"controls/scrollpanel.lua",
	"controls/image.lua",
	"controls/layoutpanel.lua",
	"controls/grid.lua",
	"controls/stackpanel.lua",
	"controls/imagelistview.lua",
	"controls/progressbar.lua",
	"controls/multiprogressbar.lua",
	"controls/scale.lua",
	"controls/panel.lua",
	"controls/treeviewnode.lua",
	"controls/treeview.lua",
	"controls/line.lua",
	"controls/combobox.lua",
	"controls/tabbaritem.lua",
	"controls/tabbar.lua",
}


for i = 1, #includes do
	ordered_includes.Add(
		{
			k=includes[i],
			v=includes[i],
			a={includes[i+1]}
		}
	)
end
---@diagnostic disable-next-line: undefined-global
local CHILI_DIRNAME=CHILI_DIRNAME or (LUAUI_DIRNAME .. "Widgets/chili/")

local includes_order_dir=CHILI_DIRNAME .. "includes_order/"
local luaFiles=VFS.DirList(includes_order_dir, "*.lua") or {}
for i = 1, #luaFiles do

    local res=VFS.Include(luaFiles[i])
	if res==nil then
		Spring.Echo("Error: file " .. luaFiles[i] .. " returns nil")
	else
		for key, value in pairs(res) do
			ordered_includes.Add(value)
		end
	end
end

local final_includes=ordered_includes.GenList()


for i = 1, #final_includes do
	Spring.Echo(final_includes[i])
end



local Chili = widget

Chili.CHILI_DIRNAME = CHILI_DIRNAME
---@diagnostic disable-next-line: undefined-global
Chili.SKIN_DIRNAME  =  SKIN_DIRNAME or (CHILI_DIRNAME .. "skins/")

if (-1>0) then
  Chili = {}
  -- make the table strict
  VFS.Include(Chili.CHILI_DIRNAME .. "headers/strict.lua")(Chili, widget)
end

for _, file in ipairs(final_includes) do
  VFS.Include(Chili.CHILI_DIRNAME .. file, Chili, VFS.RAW_FIRST)
end


return Chili
