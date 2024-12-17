-- Import globals properly
local _G = GLOBAL
local TheInput = _G.TheInput
local require = _G.require

local TOGGLE_KEY = GetModConfigData("TOGGLE_KEY")

Assets = {
    Asset("ATLAS", "images/global.xml"),
    Asset("IMAGE", "images/global.tex"),
    Asset("ATLAS", "modicon.xml"),
    Asset("IMAGE", "modicon.tex"),
}

-- Import into globals
_G.NotepadWidget = require "widgets/notepadwidget"

local notepad = nil

-- Toggle notepad function
local function ToggleNotepad()
    -- Debug print
    print("Toggle Notepad called, key pressed:", TOGGLE_KEY)
    
    -- Wait for player to be fully initialized
    if not _G.ThePlayer or not _G.ThePlayer.HUD then 
        print("No player or HUD found")
        return 
    end
    
    -- Make sure we have access to TheFrontEnd
    if not _G.TheFrontEnd then
        print("TheFrontEnd not found")
        return
    end
    
    if not notepad then
        print("Creating new notepad")
        notepad = _G.NotepadWidget()
    end
    
    if notepad.isOpen then
        print("Closing notepad")
        notepad:Close()
    else
        print("Opening notepad")
        _G.TheFrontEnd:PushScreen(notepad)
    end
end

-- Add key handler with proper global access
TheInput:AddKeyDownHandler(_G[TOGGLE_KEY], function()
    -- Ensure we're in the game state where UI can be shown
    if _G.ThePlayer and _G.ThePlayer.HUD then
        ToggleNotepad()
    end
end)

-- Initialize notepad when player is fully loaded
AddPlayerPostInit(function(player)
    if player == _G.ThePlayer then
        print("Player initialized, waiting for HUD")
        player:DoTaskInTime(0.5, function()
            if player.HUD then
                print("Player fully initialized with HUD")
                notepad = _G.NotepadWidget()
                print("Notepad initialized")
            else
                print("HUD not found after delay")
            end
        end)
    end
end)

-- Additional initialization check
AddSimPostInit(function()
    print("Sim initialized")
end) 