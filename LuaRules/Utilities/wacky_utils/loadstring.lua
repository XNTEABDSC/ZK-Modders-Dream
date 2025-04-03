VFS.Include("LuaRules/Utilities/wacky_utils/include.lua")
if not Spring.Utilities.wacky_utils.justeval then
    local wacky_utils=Spring.Utilities.wacky_utils
    wacky_utils.wacky_utils_include("mt_union")
    --VFS.Include("LuaRules/Utilities/wacky_utils/mt_union.lua")

    local mt_union=wacky_utils.mt_union
    
    --- protective load string
    ---@return 0|1|2 state 0: success, 1: loadstring error, 2: call error
    ---@return any result
    local function pjustloadstring(str,env)
        local postfunc, err = loadstring(str)
		if postfunc then
            local _gr=getfenv(1)
            if env then
                setfenv(postfunc,mt_union(env,_gr))
            else
                setfenv(postfunc,_gr)
            end
			local suc,res=pcall(postfunc)
            if suc then
                return 0,res
            else
                return 2,res
            end
            --return postfunc()
		else
            return 1,tostring(err)
            --error("failed to load string: " .. str .. " with error: " .. tostring(err))
            --return nil
		end
    end
    wacky_utils.ploadstring=pjustloadstring
    
    local function justloadstring(str,_gextra,_glevel)
        _glevel=_glevel or 1
        local postfunc, err = loadstring(str)
		if postfunc then
            local _gr=getfenv(_glevel)
            if _gextra then
                setfenv(postfunc,mt_union(_gextra,_gr))
            else
                setfenv(postfunc,_gr)
            end
			return postfunc()
		else
            error("failed to load string: " .. str .. " with error: " .. tostring(err))
            --return nil
		end
    end
    wacky_utils.justloadstring=justloadstring

    local function justeval2(str,_gextra,_glevel)
        if type(str)~="string" then
            return str
        end
        str="return " .. str
        _glevel=_glevel or 1
        local postfunc, err = loadstring(str)
		if postfunc then
            local _gr=getfenv(_glevel)
            if _gextra then
                setfenv(postfunc,mt_union(_gextra,_gr))
            else
                setfenv(postfunc,_gr)
            end
			return postfunc()
		else
            error("failed to load string: " .. str .. " with error: " .. tostring(err))
            --return nil
		end
    end
    wacky_utils.justeval2=justeval2

    local function justeval(str)
        local postfunc, err = loadstring("return " .. str)
		if postfunc then
            local suc,res=pcall(postfunc)
			return suc and res or nil
		else
            return nil
		end
    end
    wacky_utils.justeval=justeval

    Spring.Utilities.wacky_utils=wacky_utils
end