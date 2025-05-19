--[=[

local TrackMultipleTable

local function TrackMultipleTable_Get(maintable,tables,k)
	local newMainTable= rawget(maintable,k)
    
	if newMainTable==nil then
		newMainTable={}
		rawset(maintable,k,newMainTable)
	end

	if type(newMainTable)~="table" then
		return newMainTable
	end
	local newTables={}
	for id, atable in pairs(tables) do
		local v=atable[k]
        if v~=nil then
            if type(v)=="table" then
                newTables[#newTables+1] = v
            else
                return v
            end
        end
	end
	return TrackMultipleTable(newMainTable,newTables)
end

TrackMultipleTable= function (maintable,tables)
	local o=maintable
	setmetatable(o,{
		__index=function (_,k)
			return TrackMultipleTable_Get(maintable,tables,k)
		end,
		__newindex=function (_,k,v)
			local getres=TrackMultipleTable_Get(maintable,tables,k)
			if type(v)~="table" and v~=getres then
				rawset(maintable,k,v)
			else
				for key, value in pairs(v) do
					getres[key]=value
				end
			end
		end
	})
	return o
end
]=]
VFS.Include("LuaRules/Utilities/wacky_utils/include.lua")
if not Spring.Utilities.wacky_utils.track_multiple_table then
    local wacky_utils=Spring.Utilities.wacky_utils

    
    local track_multiple_table

    local function track_multiple_table_get(maintable,tables,k)
        local newMainTable= rawget(maintable,k)
        
        if newMainTable==nil then
            newMainTable={}
            rawset(maintable,k,newMainTable)
        end

        if type(newMainTable)~="table" then
            return newMainTable
        end
        local newTables={}
        for id, atable in pairs(tables) do
            local v=atable[k]
            if v~=nil then
                if type(v)=="table" then
                    newTables[#newTables+1] = v
                else
                    return v
                end
            end
        end
        return track_multiple_table(newMainTable,newTables)
    end

    track_multiple_table= function (maintable,tables)
        local o={}
        setmetatable(o,{
            __index=function (_,k)
                return track_multiple_table_get(maintable,tables,k)
            end,
            __newindex=function (_,k,v)
                local getres=track_multiple_table_get(maintable,tables,k)
                if type(v)~="table" and v~=getres then
                    rawset(maintable,k,v)
                else
                    for key, value in pairs(v) do
                        getres[key]=value
                    end
                end
            end
        })
        return o
    end

    wacky_utils.track_multiple_table=track_multiple_table

    Spring.Utilities.wacky_utils=wacky_utils
    
end