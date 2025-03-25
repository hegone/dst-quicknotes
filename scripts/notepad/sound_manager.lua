--[[
    Sound Manager Module for DST Quick Notes
    
    This module centralizes sound effect handling for the notepad mod.
    It provides named constants for all sound effects and a single method
    to play sounds, ensuring consistency across the mod.
    
    Usage:
        local SoundManager = require("notepad/sound_manager")
        
        -- Play a predefined sound
        SoundManager:PlaySound(SoundManager.SOUNDS.POSITIVE)
        
        -- Play a custom sound
        SoundManager:PlaySound("dontstarve/HUD/custom_sound")
]]

--[[
    SoundManager Class
    
    Manages sound effect playback, providing named constants
    for sounds used throughout the mod.
]]
local SoundManager = {}

-- Define constants for all sounds used in the mod
SoundManager.SOUNDS = {
    -- UI feedback sounds
    CLICK = "dontstarve/HUD/click_move",
    POSITIVE = "dontstarve/HUD/click_move", 
    NEGATIVE = "dontstarve/HUD/click_negative",
    
    -- Widget open/close sounds
    OPEN = "dontstarve/HUD/craft_open",
    CLOSE = "dontstarve/HUD/craft_close",
    
    -- Interaction sounds
    SAVE = "dontstarve/HUD/click_move",
    RESET = "dontstarve/HUD/click_negative"
}

--[[
    Plays a sound effect if the game sound system is available.
    
    @param sound (string) The sound path to play
    @return (boolean) True if sound was successfully played, false otherwise
]]
function SoundManager:PlaySound(sound)
    if not sound then return false end
    
    -- Safely check if sound system is available
    if TheFrontEnd and TheFrontEnd:GetSound() then
        TheFrontEnd:GetSound():PlaySound(sound)
        return true
    end
    
    return false
end

return SoundManager