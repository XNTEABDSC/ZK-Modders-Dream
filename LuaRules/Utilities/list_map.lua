
if Spring==nil then
    Spring={}
end
if Spring.Utilities==nil then
    Spring.Utilities={}
end

if not Spring.Utilities.list_map then
    VFS.Include("LuaRules/Utilities/unordered_list.lua")
    local unordered_list=Spring.Utilities.unordered_list
    local list_map={}
    Spring.Utilities.list_map=list_map
    local uo_list_add=unordered_list.metatable.add
    local uo_list_remove=unordered_list.metatable.remove
    function list_map.new()
        ---@class list_map
        local o={}
        local list={}
        local map={}
        local function Add(v)
            local index=uo_list_add(list,v)
            map[v]=index
        end
        local function RemoveByIndex(index)
            local repalcedV=list[#list]
            local v=uo_list_remove(list,index)
            if repalcedV then
                map[repalcedV]=index
            end
            if v then
                map[v]=nil
            end
        end
        local function RemoveByValue(v)
            local index=map[v]
            if index then
                RemoveByIndex(index)
                
            end
        end
        o.list=list
        o.map=map
        o.Add=Add
        o.RemoveByValue=RemoveByValue
        o.RemoveByIndex=RemoveByIndex
        return o
    end
end