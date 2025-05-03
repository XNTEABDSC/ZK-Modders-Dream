VFS.Include("LuaRules/Utilities/wacky_utils/include.lua")
if not Spring.Utilities.wacky_utils.step_to_section_swap then
    local wacky_utils=Spring.Utilities.wacky_utils
    local function step_to_section_swap(value,step,target,section_left,section_right)
        local section_len=section_right-section_left
        
        local target_norm_dist=target-value
        local section_len_half=section_len/2

        while target_norm_dist>section_len_half do
            target_norm_dist=target_norm_dist-section_len
        end
        
        while target_norm_dist<-section_len_half do
            target_norm_dist=target_norm_dist+section_len
        end
        
        if target_norm_dist>0 then
            if target_norm_dist<step then
                return target_norm_dist
            else
                return step
            end
        else
            if -target_norm_dist<step then
                return target_norm_dist
            else
                return -step
            end
        end
        
    end

    wacky_utils.step_to_section_swap=step_to_section_swap

    local pi2=math.pi*2
    wacky_utils.angle_step_to=function(value,step,target)
        return step_to_section_swap(value,step,target,0,pi2)
    end
    Spring.Utilities.wacky_utils=wacky_utils
end