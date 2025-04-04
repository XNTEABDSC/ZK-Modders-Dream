VFS.Include("LuaRules/Utilities/wacky_utils/include.lua")
if not Spring.Utilities.wacky_utils.may_lower_key_proxy then
    local wacky_utils = Spring.Utilities.wacky_utils

    local may_lower_key_proxy
    local maylowerkeyutils = {}


    ---`t[k] or t[string.lower(k)]`
    local function maylowerkeyget(t, k)
        return t[k] or t[string.lower(k)]
    end
    ---`t[string.lower(k)] or t[k]`
    local function maylowerkeyget_lower(t, k)
        return t[string.lower(k)] or t[k]
    end
    ---`t[k] or t[k:lower()] or t[k] = v`
    local function maylowerkeyset(t, k, v)
        if t[k] ~= nil then
            t[k] = v
        else
            local k2 = string.lower(k)
            if t[k2] ~= nil then
                t[k2] = v
            else
                t[k] = v
            end
        end
    end
    --- `t[k:lower()] or t[k] or t[k:lower()]= v`
    local function maylowerkeyset_lower(t, k, v)
        local k2 = string.lower(k)
        if t[k2] ~= nil then
            t[k2] = v
        else
            if t[k] then
                t[k] = v
            else
                t[k2] = v
            end
        end
    end

    ---`t[k] or t[string.lower(k)]`
    local function maylowerkeyget_deep(t, k)
        local v = t[k] or t[string.lower(k)]
        if type(v) == table then
            return may_lower_key_proxy(v,false,true)
        else
            return v
        end
    end
    ---`t[string.lower(k)] or t[k]`
    local function maylowerkeyget_lower_deep(t, k)
        local v =t[string.lower(k)] or t[k]
        if type(v) == table then
            return may_lower_key_proxy(v,true,true)
        else
            return v
        end
    end

    wacky_utils.maylowerkeyget = maylowerkeyget
    wacky_utils.maylowerkeyset = maylowerkeyset
    wacky_utils.maylowerkeyget_lower = maylowerkeyget_lower
    wacky_utils.maylowerkeyset_lower = maylowerkeyset_lower
    wacky_utils.maylowerkeyget_deep = maylowerkeyget_deep
    wacky_utils.maylowerkeyget_lower_deep = maylowerkeyget_lower_deep

    --- returns a table `o` that acts like `tb` e.g. `o.customParams`, but if `tb==lowerkey(tb)`, then `o` may do key:lower() when get and set <br>
    --- if checkKeys cant determines whether lower, this function will enumerate all keys to find whether any key is uppercase
    ---@param checkKeys boolean|string[]? keys to check whether `tb=lowerkey(tb)`
    ---@param deep boolean|nil if true, make proxy for table got
    may_lower_key_proxy = function(tb, checkKeys, deep)
        if deep==nil then
            deep=false
        end
        local lower = nil
        local tcheckKeys = type(checkKeys)
        if tcheckKeys == "boolean" then
            lower = checkKeys
        elseif tcheckKeys == "table" then
            for _, checkKey in pairs(checkKeys) do
                if tb[checkKey] ~= nil then
                    lower = false
                    break
                elseif tb[string.lower(checkKey)] ~= nil then
                    lower = true
                    break
                end
            end
        end
        if lower == nil then
            lower = true
            for key, _ in pairs(tb) do
                if key ~= string.lower(key) then
                    lower = false
                    break
                end
            end
        end
        local maylowermt
        if lower then
            maylowermt = {
                __index = 
                deep and function(_, k)
                    return maylowerkeyget_lower_deep(tb, k)
                end or function(_, k)
                    return maylowerkeyget_lower(tb, k)
                end,
                __newindex = function(_, k, v)
                    maylowerkeyset_lower(tb, k, v)
                end
            }
            local o = {}
            setmetatable(o, maylowermt)
            return o
        else
            maylowermt = {
                __index =
                deep and
                function(_, k)
                    return maylowerkeyget_deep(tb, k)
                end
                or
                function(_, k)
                    return maylowerkeyget(tb, k)
                end,
                __newindex = function(_, k, v)
                    maylowerkeyset(tb, k, v)
                end
            }
            local o = {}
            setmetatable(o, maylowermt)
            return o
        end
    end
    wacky_utils.may_lower_key_proxy = may_lower_key_proxy
    local may_lower_key_proxy_wd_checkkeys = {
        "weaponType"
    }
    wacky_utils.may_lower_key_proxy_wd_checkkeys = may_lower_key_proxy_wd_checkkeys
    local may_lower_key_proxy_ud_checkkeys = {
        "objectName"
    }
    wacky_utils.may_lower_key_proxy_ud_checkkeys = may_lower_key_proxy_ud_checkkeys

    Spring.Utilities.wacky_utils = wacky_utils
end
