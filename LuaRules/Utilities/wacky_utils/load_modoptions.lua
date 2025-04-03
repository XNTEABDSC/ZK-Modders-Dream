VFS.Include("LuaRules/Utilities/wacky_utils/include.lua")
if not Spring.Utilities.wacky_utils.load_modoptions then
    local utils=Spring.Utilities.wacky_utils

    utils.wacky_utils_include("tweak_fns")
    local wacky_utils=Spring.Utilities.wacky_utils
    local AddFnToUnitDefsTweakFns=utils.AddFnToUnitDefsTweakFns
    local unit_defs_tweak_fns=utils.unit_defs_tweak_fns
    
    local function tweak_units(tweaks)
        for name, _ in pairs(tweaks) do
            if UnitDefs[name] then
                Spring.Echo("Loading tweakunits for " .. name)
                Spring.Utilities.OverwriteTableInplace(UnitDefs[name], wacky_utils.lowerkeys(tweaks[name]), true)
            end
        end
        --[=[
        for name, ud in pairs(UnitDefs) do
            if tweaks[name] then
                Spring.Echo("Loading tweakunits for " .. name)
                Spring.Utilities.OverwriteTableInplace(ud, wacky_utils.lowerkeys(tweaks[name]), true)
            end
        end]=]
    end

    utils.tweak_units=tweak_units


    local function tweak_defs(postsFuncStr)
        local postfunc, err = loadstring(postsFuncStr)
        if postfunc then
            postfunc()
        else
            Spring.Log("defs.lua", LOG.ERROR, "tweakdefs", err)
        end
    end
    utils.tweak_defs=tweak_defs

    --- load modOptions
    function wacky_utils.load_modoptions()

        local luamods={}
        for i, filename in pairs(VFS.DirList("gamedata/lua_mods", "*.lua") or {}) do
            --Spring.Utilities.CopyTable(VFS.Include(filename),luamods)
            local fileluamods=VFS.Include(filename)
            if fileluamods and type (fileluamods )=="table" then
                for key, value in pairs(fileluamods) do
                    if type(value)=="function" then
                        value={
                            fn=value
                        }
                    end
                    if type(value)=="table" then
                        if not value.name then
                            value.name=key
                        end
                        luamods[value.name]=value
                        Spring.Echo("find luamod: " .. value.name .. " from file: " .. filename)
                    else
                        Spring.Log("defs.lua", LOG.ERROR, "load lua mods", "wrong return of file " .. tostring(filename) .. " key: " .. tostring(key) .. " value: " .. tostring(value))
                    end
                end
            else
                Spring.Log("defs.lua", LOG.ERROR, "load lua mods", "wrong return of file " .. tostring(filename))
            end
        end

        --do_lua_mods=do_lua_mods or false
        local modOptions = {}
        local utils=wacky_utils
        local toload={}
        if (Spring.GetModOptions) then
            toload = Spring.GetModOptions()
        end
        if toload.did_load_mod then
            Spring.Echo("modoptions already loaded")
            return
        end
        Spring.GetModOptions=function ()
            return modOptions
        end

        if not toload.mods then
            toload.mods =VFS.Include("gamedata/modoption_mod_default.lua")
        end
        local option_mult=utils.list_to_set( {"metalmult","energymult","terracostmult","cratermult","hpmult",
        "team_1_econ","team_2_econ","team_3_econ","team_4_econ","team_5_econ","team_6_econ","team_7_econ","team_8_econ",
        "wavesizemult","queenhealthmod","techtimemult"
        } )
        local option_add_withdef={
        }
        local option_mult_withdef={
            innatemetal=2,
            innateenergy=2,
            zombies_delay=10,
            zombies_rezspeed=12
        }
        local option_bindstr={
            disabledunits="+ ",
            option_notes="\n---\n",
            mods=" "
        }
        local json_mods_dir="gamedata/mods/"
        local lua_mods_dir="gamedata/lua_mods/"

        local mod_count=0
        local last_order="load_modoptions_begin"
        

        local load_mod
        local function load_modoption(loaded_mod_options)
            for key, value in pairs(loaded_mod_options) do
                if  modOptions[key] then
                    if option_mult[key] then
                        modOptions[key]=modOptions[key]*value
                    elseif option_add_withdef[key] then
                        modOptions[key]=modOptions[key]+value-option_add_withdef[key]
                    elseif option_mult_withdef[key] then
                        modOptions[key]=modOptions[key]*value/option_mult_withdef[key]
                    elseif option_bindstr[key] then
                        modOptions[key]=modOptions[key] .. option_bindstr[key] .. value
                    elseif string.find(key,"tweakdefs") then
                    elseif string.find(key,"tweakunits") then
                    else
                        modOptions[key]=value
                    end
                else
                    modOptions[key]=value
                end
            end

            AddFnToUnitDefsTweakFns({
                v=function ()
                    ---@type boolean|number
                    local append = false
                    local name = "tweakdefs"
                    while loaded_mod_options[name] and loaded_mod_options[name] ~= "" do
                        local postsFuncStr = Spring.Utilities.Base64Decode(loaded_mod_options[name])
                        Spring.Echo("Loading tweakdefs modoption ".. (append or 0) .. "\n" .. postsFuncStr)
                        tweak_defs(postsFuncStr)
                        append = (append or 0) + 1
                        name = "tweakdefs" .. append
                    end
                end,
                k="modoption " .. mod_count .. " tweakdefs",
                b={last_order}
            })
            AddFnToUnitDefsTweakFns({
                v=function ()
                    ---@type boolean|number
                    local append = false
                    local modoptName = "tweakunits"
                    while loaded_mod_options[modoptName] and loaded_mod_options[modoptName] ~= "" do
                        local tweaks = Spring.Utilities.CustomKeyToUsefulTable(loaded_mod_options[modoptName])
                        if type(tweaks) == "table" then
                            Spring.Echo("Loading tweakunits modoption", append or 0)
                            tweak_units(tweaks)
                        end
                        append = (append or 0) + 1
                        modoptName = "tweakunits" .. append
                    end
                end,
                k="modoption " .. mod_count .. " tweakunits",
                b={"modoption " .. mod_count .. " tweakdefs"}
            })
            last_order="modoption " .. mod_count .. " tweakunits"
            mod_count=mod_count+1
            if loaded_mod_options.mods then
                load_mod(loaded_mod_options.mods)
            end
            
            --[==[
            do_fns("tweakdefs")
            do_fns("tweakunits")
            do_fns("mods")
            ]==]
        end
        --local update_mod;
        local function load_json_mod(mod,moddir)
            Spring.Echo("SW: Load mod " .. mod)
            local dataRaw=VFS.LoadFile(moddir)
            local mod_data=Spring.Utilities.json.decode(dataRaw)
            if mod_data then
                local themodoptions=mod_data.options
                if themodoptions then
                    load_modoption(themodoptions)
                end
            else
                Spring.Echo("Warning: SW: failed to load mod " .. mod)
            end
        end
        local function load_lua_mod(mod,moddir,env)
            Spring.Echo("SW: Run luamod " .. mod)
            local themodoptions=luamods[mod].fn(env)--VFS.Include(moddir,env)
            if themodoptions then
                load_modoption(themodoptions)
            end
        end
        
        local load_mod_env={}
        --[==[
        local load_mod_env_mt={__index=function (table,key)
            
            local mod=key
            local jsonmoddir=mods_dir .. mod .. ".json"
            local lua_mod_dir=lua_mods_dir .. mod .. ".lua"
            if VFS.FileExists(jsonmoddir) then
                return function ()
                    load_json_mod(mod,jsonmoddir)
                end
            elseif VFS.FileExists(lua_mod_dir) then
                return function (env)
                    env=wacky_utils.meta_union(env,getfenv(0))
                    load_lua_mod(mod,lua_mod_dir,env)
                end
            else
                Spring.Echo("Warning: SW: mod " .. mod .. " don't exist")
                return function ()
                    return nil
                end
            end
        end}
        setmetatable(load_mod_env,load_mod_env_mt)]==]
        for modname, mod in pairs(luamods) do
            load_mod_env[modname]=function (...)
                local suc,err=pcall(mod.fn,...)
                if suc then
                    local themodoptions=err
                    if themodoptions then
                        load_modoption(themodoptions)
                    end
                else
                    Spring.Log("defs.lua", LOG.ERROR, "run_lua_mod", "Failed to run mod " .. modname .. " with error " .. err)
                end
            end
        end
        --[==[
        for key, value in pairs(VFS.DirList(lua_mods_dir,"*.lua")) do
            local mod=string.match(value,[[([a-zA-Z_]+)%.lua]])
            Spring.Echo("find luamod: " .. value .. " modname: " .. tostring( mod))
            if mod then
                load_mod_env[mod]=
                luamods[mod].fn
                --[=[
                function (env)
                    env=env or {}
                    env=utils.mt_union(env,getfenv(0))
                    load_lua_mod(mod,value,env)
                end]=]
            end
        end ]==]

        for key, value in pairs(VFS.DirList(json_mods_dir,"*.json")) do
            local mod=string.match(value,[[([a-zA-Z_]+)%.json]])
            Spring.Echo("find jsonmod: " .. value .. " modname: " .. tostring( mod))
            if mod then
                load_mod_env[mod]=function ()
                    load_json_mod(mod,value)
                end
            end
        end
        setmetatable(load_mod_env,{__index=function (t,k)
            Spring.Log("defs.lua", LOG.ERROR, "load_mod", "Mod " .. k .. " don't exist")
            return function() end
        end})
        
        load_mod=function(modstr)
            local chunk,errmsg=loadstring(modstr)
            if chunk then
                setfenv(chunk,load_mod_env)
                local suc,res=pcall(chunk)
                if not suc then
                    Spring.Log("defs.lua", LOG.ERROR, "load_mod", "Failed to run string " .. modstr .. " with error ".. res)
                end
            else
                Spring.Log("defs.lua", LOG.ERROR, "load_mod", "Failed to load string " .. modstr .. " with error ".. errmsg)
            end
            --wacky_utils.justloadstring(modstr,load_mod_env)
        end

        --load_mod(mods)

        load_modoption(toload)

        unit_defs_tweak_fns.AddOrder(last_order,"load_modoptions_end")

        modOptions.did_load_mod=true
        Spring.Echo("modOptions result: ")
        Spring.Utilities.TableEcho(modOptions,"modOptions")
    end


    Spring.Utilities.wacky_utils=utils
end
