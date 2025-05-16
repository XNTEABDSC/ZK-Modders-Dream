
--Spring.IsCheatingEnabled()


function gadget:GetInfo()
    return {
        name      = "Gadget Run Code Unsynced",
        desc      = "Run code in Unsynced gadget",
        author    = "XNTEABSC",
        date      = "",
        license   = "GNU GPL, v2 or later",
        layer     = 0,
        enabled   = true,
    }
end

if gadgetHandler:IsSyncedCode() then
    
    local LuaMsgHead="GadgetRunCodeUnsynced:"
    local LuaMsgHeadLen=LuaMsgHead:len()
    ---@param msg string
    function gadget:RecvLuaMsg(msg,playerID)
        if Spring.IsCheatingEnabled() then
            if msg:sub(1,LuaMsgHeadLen)==LuaMsgHead then
                local code=msg:sub(LuaMsgHeadLen+1)
                SendToUnsynced("GadgetRunCodeUnsynced",code)
            end
        end
    end

else


    local function pack(...)
        return select("#",...),{...}
    end
    local function dostring(str)
        local f,err=loadstring(str)
        if not f then
            return -1,err
        else
            setfenv(f,_G)
            local suc,res1,res2=pcall(function ()
                return pack(f())
            end)
            if not suc then
                return -2,res1
            else
                return res1,res2
            end
        end
    end

    ---@param code string
    local function GadgetRunCodeUnsynced(dwad,code)
        if Spring.IsCheatingEnabled() then
            Spring.Echo("game_message: Gadget Run Code Unsynced: Running " .. code)
            local result_str=""
            local c,res=dostring(code)
            if c==-1 then
                result_str="Error: " .. res
            elseif c==-2 then
                result_str="Error: " .. res
            else
                for i = 1, c do
                    result_str=result_str .. tostring( res[i] ) .. "; "
                end
            end
            Spring.Echo("game_message: Gadget Run Code Unsynced: " .. result_str)
        end
    end

    
    function gadget:Initialize()
        
	    gadgetHandler:AddSyncAction("GadgetRunCodeUnsynced", GadgetRunCodeUnsynced)
    end
end