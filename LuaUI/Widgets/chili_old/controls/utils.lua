Utils={
    BetterGetChildrenMinimumExtents=function (self)
        local minWidth  = 0
        local minHeight = 0
    
        local cn = self.children
        for i = 1, #cn do
            local c = cn[i]
            local width, height=0,0
            if (c.GetMinimumExtents) then
                width, height = c:GetMinimumExtents()
            else
                width=math.max(width,c.width)+c.x
                height=math.max(height,c.height)+c.y
                --[=[
                local padding = c.padding
                if padding then
                    width=width+padding[1]+padding[3]
                    height=height+padding[1]+padding[3]
                end
                ]=]
            end
            width=width
            height=height
            minWidth  = math.max(minWidth,  width)
            minHeight = math.max(minHeight, height)
        end
    
        if (minWidth + minHeight > 0) then
            local padding = self.padding
            minWidth  = minWidth + padding[1] + padding[3]
            minHeight = minHeight + padding[2] + padding[4]
        end
    
        return minWidth, minHeight
    end,
    --[=[]=]
    MoveChild=function (self,index,offset)
        local children=self.children
        local tomove_start
        local tomove_end
        if offset>0 then
            tomove_start=index+1
            tomove_end=tomove_start+offset
        else

        end
        for i, v in pairs(children) do -- remap hardlinks and objects
			if type(v) == "number" and v >= index then
				children[i] = v + 1
			end
		end
    end,
    --[=[
    MoveChildren=function (self,start,count,offset)
        local children=self.children
        local tomove_start
        local tomove_end
        local tomove_offset
        local tomove_min
        local tomove_max
        if offset>0 then
            tomove_start=start+count
            tomove_end=tomove_start+offset
            tomove_offset=-count
            tomove_min=tomove_start
            tomove_max=tomove_end
        else
            tomove_start=start-1
            tomove_end=tomove_start-offset
            tomove_offset=count
            tomove_min=tomove_end
            tomove_max=tomove_start
        end
        for i, v in pairs(children) do -- remap hardlinks and objects
			if type(v) == "number" and tomove_min<=v and v<=tomove_max then
				children[i] = v + tomove_offset
			end
		end
		table.insert(children, index, objDirect)
    end,]=]

    SetChildIndex=function (self,child,id)
	    local objDirect =  WG.Chili.UnlinkSafe(child)
	    local hobj = WG.Chili.MakeHardLink(objDirect)
        self.children[id]=objDirect
        self.children[objDirect]=id
        self.children[hobj]=id
    end,
    HitTestSelf=function (self,x,y)
        return self
    end
      
}
if false then
    WG.Chili.Utils=Utils
end