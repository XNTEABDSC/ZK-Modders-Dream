if Spring==nil then
    Spring={}
end
if Spring.Utilities==nil then
    Spring.Utilities={}
end
if Spring.Utilities.unordered_list==nil then
    --- when remove one, the latest will be moved to the vacancy
    local unordered_list= {}
    Spring.Utilities.unordered_list=unordered_list

    unordered_list.metatable={}
    unordered_list.metatable.__index=function (tb,index)
        return unordered_list.metatable[index]
    end
    ---@class unordered_list<T>:{ [integer]:T, add:(fun(self:unordered_list<T>,item:T):integer),remove:(fun(self:unordered_list<T>,index:integer):T),enum:(fun(self:unordered_list<T>):(fun():(T,integer)))}
    ---@generic T
    ---@param o any
    ---@return unordered_list<T>
    function unordered_list.new(o)
        o=o or {}
        setmetatable(o,unordered_list.metatable)
        return o
    end

    ---@generic T
    ---@param self unordered_list<T>
    ---@param item T
    ---@return integer
    function unordered_list.metatable:add(item)
        self[#self+1]=item
        return #self
    end

    ---@generic T
    ---@param self unordered_list<T>
    ---@param index integer
    ---@return T
    function unordered_list.metatable:remove(index)
        local res=self[index]
        self[index]=self[#self]
        self[#self]=nil
        return res
    end

end