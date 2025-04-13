local Attributes=GG.Attributes
if not Attributes then
    Attributes={}
    GG.Attributes=Attributes
end

---@class AttributesDataHandler
---@field fold fun(domainData:table)
---@field apply fun()

---@class AttributesHandler
---@field newDataHandler fun(frame:number):AttributesDataHandler
---@field clear fun()

---@class AttributesHandlerFactory
---@field new fun(unitID:UnitId,unitDefID:UnitDefId):AttributesHandler

---@type list<AttributesHandlerFactory>
local HandlersFactory=Attributes.HandlersFactory
if not HandlersFactory then
    HandlersFactory={}
    local HandlersFiles=VFS.DirList("LuaRules/Configs/UnitAttributeHandlers", "*.lua") or {}
    for i = 1, #HandlersFiles do
        ---@type {[string|number]:AttributesHandlerFactory}
        local HandlersDefs = VFS.Include(HandlersFiles[i])
        for key, value in pairs(HandlersDefs) do
            if type(key)=="number" then
                HandlersFactory[#HandlersFactory+1]=value
            else
                HandlersFactory[key]=value
            end
        end
    end
    Attributes.HandlersFactory=HandlersFactory
end

return HandlersFactory
