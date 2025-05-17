-- GadgetRunCode:

--Spring.IsCheatingEnabled()

if gadgetHandler:IsSyncedCode() then

    function gadget:GetInfo()
        return {
          name      = "Gadget Run Code",
          desc      = "Run code in gadget",
          author    = "XNTEABSC",
          date      = "",
          license   = "GNU GPL, v2 or later",
          layer     = 0,
          enabled   = true,
        }
    end

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

    local LuaMsgHead="GadgetRunCode:"
    local LuaMsgHeadLen=LuaMsgHead:len()
    ---@param msg string
    function gadget:RecvLuaMsg(msg,playerID)
        if Spring.IsCheatingEnabled() then
            if msg:sub(1,LuaMsgHeadLen)==LuaMsgHead then
                local code=msg:sub(LuaMsgHeadLen+1)
                Spring.Echo("game_message: Gadget Run Code: Running" .. code)
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
                Spring.Echo("game_message: Gadget Run Code: " .. result_str)
            end
        end
    end
end