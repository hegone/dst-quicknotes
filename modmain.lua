--[[
    Quick Notes - Main Module
    
    This is the entry point for the Quick Notes mod. It handles:
    - Global imports and setup
    - Asset registration
    - Key binding configuration
    - Notepad widget creation and toggling
    - Test command for development
    
    The module sets up the necessary environment and provides the core
    functionality to show/hide the notepad in response to key presses.
]]

-- Import required globals into local scope for better performance
-- and to avoid potential naming conflicts
local _G = GLOBAL
local TheInput = _G.TheInput
local require = _G.require

-- Load user configuration
local TOGGLE_KEY = GetModConfigData("TOGGLE_KEY")
local TEXT_COLOR = GetModConfigData("TEXT_COLOR")
local BG_COLOR = GetModConfigData("BG_COLOR")
local BG_OPACITY = GetModConfigData("BG_OPACITY")

--[[
    Asset Registration
    
    Register required textures and atlases for the mod.
    These assets are used for UI elements like buttons and frames.
]]
Assets = {
    Asset("ATLAS", "images/global.xml"),    -- Global UI elements atlas
    Asset("IMAGE", "images/global.tex"),    -- Global UI elements texture
    Asset("ATLAS", "images/global_redux.xml"),    -- Global redux UI elements atlas
    Asset("IMAGE", "images/global_redux.tex"),    -- Global redux UI elements texture
    Asset("ATLAS", "modicon.xml"),
    Asset("IMAGE", "modicon.tex"),
}

-- Load configuration module and update it with user settings
_G.CONFIG_INITIALIZED = false
_G.InitializeConfig = function()
    if not _G.CONFIG_INITIALIZED then
        local Config = require "notepad/config"
        Config.UpdateConfig(TEXT_COLOR, BG_COLOR, BG_OPACITY)
        _G.CONFIG_INITIALIZED = true
    end
end

-- Make the notepad widget accessible globally
_G.NotepadWidget = require "widgets/notepadwidget"

-- Track the current notepad instance
local notepad = nil

--[[
    Toggles the notepad's visibility.
    
    This function:
    1. Checks if the player and HUD exist
    2. If notepad is open, closes it
    3. If notepad is closed, creates and shows a new one
    
    The function includes debug logging to help track the notepad's state
    and any potential issues.
]]
local function ToggleNotepad()
    print("[Quick Notes] Toggle Notepad called, key pressed:", TOGGLE_KEY)
    
    -- Initialize config before creating notepad
    _G.InitializeConfig()
    
    -- Safety check: ensure player and HUD exist
    if not _G.ThePlayer or not _G.ThePlayer.HUD then
        print("[Quick Notes] No player or HUD found")
        return
    end
    
    -- Check if notepad exists and is open
    if notepad then
        -- Check if the notepad is still valid and has an IsOpen method
        local is_open = false
        
        -- Defensively check if we can call IsOpen
        if notepad.IsOpen and type(notepad.IsOpen) == "function" then
            -- Try to check if it's open directly
            -- This is safer than using pcall which might not be available
            if notepad.state then
                is_open = notepad:IsOpen()
            end
        end
        
        if is_open then
            -- Close existing notepad
            print("[Quick Notes] Closing notepad")
            notepad:Close()
            return
        else
            -- Reset the notepad reference if it exists but isn't open
            print("[Quick Notes] Notepad exists but is not open, creating new one")
            notepad = nil
        end
    end
    
    -- If we get here, either notepad was nil, invalid, or closed
    -- Create and show new notepad
    print("[Quick Notes] Creating new notepad")
    notepad = _G.NotepadWidget()
    print("[Quick Notes] Opening notepad")
    _G.TheFrontEnd:PushScreen(notepad)
end

--[[
    Key Handler Setup
    
    Registers the toggle key handler that shows/hides the notepad.
    Only triggers when:
    1. The player exists
    2. The HUD exists
    3. No other UI element has input focus
]]
TheInput:AddKeyDownHandler(_G[TOGGLE_KEY], function()
    if _G.ThePlayer and _G.ThePlayer.HUD and not _G.ThePlayer.HUD:HasInputFocus() then
        ToggleNotepad()
    end
end)