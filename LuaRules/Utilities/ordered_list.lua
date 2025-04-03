if Spring==nil then
    Spring={}
end
if Spring.Utilities==nil then
    Spring.Utilities={}
end
if not Spring.Utilities.OrderedList then
    VFS.Include("LuaRules/Utilities/wacky_utils/loop_until_finish_all.lua")
    
    local LoopUntilFinishAllTable=Spring.Utilities.wacky_utils.loop_until_finish_all_table
    local empty={}
    local OrderedList={}
    function OrderedList.New()
        ---@class ValueAndOrder<T>:{k:string,v:T|nil,b:list<string>|nil,a:list<string>|nil}

        ---@class OrderedList
        local self={}
        local kvlist={}
        self.kvlist=kvlist

        local Add

        local function GetOrNew(key)
            if not kvlist[key] then
                Add({k=key})
            end
            return kvlist[key]
        end
        self.GetOrNew=GetOrNew

        local function AddOrder(k1,k2)
            local k1a=GetOrNew(k1).afters
            k1a[#k1a+1] = k2
            local k2o=GetOrNew(k2)
            k2o.before_count=k2o.before_count+1
        end
        self.AddOrder=AddOrder

        Add=function (order)
            local key,value,befores,afters=order.k,order.v,order.b,order.a
            if not kvlist[key] then
                kvlist[key]={
                    value=value,
                    before_count=0,
                    afters={}
                }
            end
            if value then
                kvlist[key].value=value
            end
            if befores then
                for _, before in pairs(befores) do
                    AddOrder(before,key)
                end
            end
            if afters then
                for _, after in pairs(afters) do
                    AddOrder(key,after)
                end
            end
        end
        self.Add=Add

        local function ForEach(fn)
            local before_count={}
            for key, value in pairs(kvlist) do
                before_count[key]=value.before_count
            end
            local unfinished= LoopUntilFinishAllTable(kvlist,function (k,v)
                if before_count[k]==0 then
                    fn(v.value,k)
                    for _, key in pairs(v.afters) do
                        before_count[key]=before_count[key]-1
                    end
                    return nil
                end
                return v
            end)

            return unfinished
        end

        local function GenList()
            local l={}
            local count=0
            ForEach(function (v,k)
                if v~=nil then
                    count=count+1
                    l[count]=v
                end
            end)
            return l
        end
        self.ForEach=ForEach
        self.GenList=GenList

        return self
    end

    Spring.Utilities.OrderedList=OrderedList

    ---add ordered value, automatically append a number to make key no overlap
    function OrderedList.AddMult(list,ordered)
        local append=0
        local key=ordered.k
        while list.kvlist[key] do
            append=append+1
            key=ordered.k .. append
        end
        ordered.k=key
        list.Add(ordered)
        
    end
    ---merge 2 order's `b` and `a`, `ordera` will be changed
    ---@param ordera {k:string,v:any,b:list<string>|nil,a:list<string>|nil}
    ---@param orderb {k:string,v:any,b:list<string>|nil,a:list<string>|nil}
    ---@return {k:string,v:any,b:list<string>|nil,a:list<string>|nil}
    function OrderedList.MergeOrder(ordera,orderb)
        if not ordera.a then
            ordera.a={}
        end
        local ordera_a=ordera.a
        if orderb.a then
            for key, value in pairs(orderb.a) do
                ordera_a[#ordera_a+1] = value
            end
        end
        if not ordera.b then
            ordera.b={}
        end
        local ordera_b=ordera.b
        if orderb.b then
            for key, value in pairs(orderb.b) do
                ordera_b[#ordera_b+1] = value
            end
        end
        ordera.v=ordera.v or orderb.v
        ordera.k=ordera.k or orderb.k
        return ordera
    end

    ---@param pos -1|"pre"|0|"in"|1|"post"
    function OrderedList.MakeOrder(key,pos)
        if type(pos)=="string" then
            pos=({pre=-1,["in"]=0,post=1})[pos]
        end
        if pos==-1 then
            return {a={key .. "_pre"}}
        elseif pos == 0 then
            return {b={key .. "_pre"},a={key.."_post"}}
        elseif pos==1 then
            return {b={key .. "_post"}}
        end
    end

end
return Spring.Utilities.OrderedList