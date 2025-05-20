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

    local none=wacky_utils.None

    local track_multiple_table

    local function track_multiple_table_get(maintable,tables,k)
        local newMainTable= rawget(maintable,k)

        if newMainTable==none then
            return nil
        end

        if newMainTable ~= nil and type(newMainTable)~="table" then
            return newMainTable
        end

        local newTables={}
        for id, atable in ipairs(tables) do
            local v=atable[k]
            if v==none then
                return nil
            elseif v~=nil then
                if type(v)~="table" then
                    return v
                else
                    newTables[#newTables+1] = v
                end
            end
        end
        if newMainTable==nil then
            if #newTables==0 then
                return nil
            else
                newMainTable={}
                rawset(maintable,k,newMainTable)
            end
        end
        return track_multiple_table(newMainTable,newTables)
    end

    track_multiple_table= function (maintable,tables)
        local o={
            __maintable=maintable,
            __tables=tables,
        }
        setmetatable(o,{
            __index=function (_,k)
                return track_multiple_table_get(maintable,tables,k)
            end,
            __newindex=function (_,k,v)
                local getres=track_multiple_table_get(maintable,tables,k)
                if getres==nil then
                    rawset(maintable,k,v)
                elseif type(v)~="table" then
                    if v==nil then
                        rawset(maintable,k,none)
                    else
                        if v==getres and v~=rawget(maintable,k) then
                            rawset(maintable,k,nil)
                        else
                            rawset(maintable,k,v)
                        end
                    end
                else
                    for key, value in pairs(v) do
                        getres[key]=value
                    end
                end
            end,
            __unm=function (t)
                
            end
        })
        return o
    end

    wacky_utils.track_multiple_table=track_multiple_table

    local CopyTable=Spring.Utilities.CopyTable

    local function track_multiple_table_get_all(o)
        local maintable,tables=o.__maintable,o.__tables
        local result={}
        for i=#tables,1,-1 do
            local value=tables[i]
            do 
                local maintable_,tables_=value.__maintable,value.__tables
                if maintable_~=nil and tables_~=nil then
                    value=track_multiple_table_get_all(value)
                end
            end
            CopyTable(value,true,result)
        end
        CopyTable(maintable,true,result)
        return result
    end
    wacky_utils.track_multiple_table_get_all=track_multiple_table_get_all
    Spring.Utilities.wacky_utils=wacky_utils
    
end