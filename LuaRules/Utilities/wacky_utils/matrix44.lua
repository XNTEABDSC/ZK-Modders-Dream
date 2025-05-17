VFS.Include("LuaRules/Utilities/wacky_utils/include.lua")
if not Spring.Utilities.wacky_utils.MultMatrix4x4 then
    local wacky_utils=Spring.Utilities.wacky_utils

    local function NewMatrix44Unit()
        return{
            1,0,0,0,
            0,1,0,0,
            0,0,1,0,
            0,0,0,1,
        }
    end
    wacky_utils.NewMatrix4x4Unit=NewMatrix44Unit
    local function Matrix44rc2i(r,c)
        return (r-1)*4+c
    end
    wacky_utils.Matrix44rc2i=Matrix44rc2i
    local function Matrix44i2rc(i)
        local c=i%4
        if c==0 then c=4 end
        local r=(i-c)/4+1
        return r,c
    end
    wacky_utils.Matrix44i2rc=Matrix44i2rc
    ---Mult 2 4x4 matrix
    ---@param a {[integer]:number}
    ---@param b {[integer]:number}
    ---@return {[integer]:number}
    local function MultMatrix44(a,b)
        local v={}
        for r=1,4 do
            local r2i=(r-1)*4
            for c=1,4 do
                v[r2i+c]=
                    a[r2i+1]*b[0+c]+
                    a[r2i+2]*b[4+c]+
                    a[r2i+3]*b[8+c]+
                    a[r2i+4]*b[12+c]
            end
        end
        return v
    end
    wacky_utils.MultMatrix4x4=MultMatrix44

    Spring.Utilities.wacky_utils=wacky_utils
end