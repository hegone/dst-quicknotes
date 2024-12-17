-- Import globals
local _G = GLOBAL
local TheInput = _G.TheInput
local TheFrontEnd = _G.TheFrontEnd
local ThePlayer = _G.ThePlayer
local require = _G.require

local TOGGLE_KEY = GetModConfigData("TOGGLE_KEY")

Assets = {
    Asset("ATLAS", "images/global.xml"),
    Asset("IMAGE", "images/global.tex"),
    Asset("ATLAS", "modicon.xml"),
    Asset("IMAGE", "modicon.tex"),
}

-- Import into globals
local NotepadWidget = require "widgets/notepadwidget"
_G.NotepadWidget = NotepadWidget

local notepad = nil

-- Toggle notepad function
local function ToggleNotepad()
    if not ThePlayer or not ThePlayer.HUD then return end
    
    if not notepad then
        notepad = NotepadWidget()
    end
    
    if notepad.shown then
        notepad:Close()
    else
        TheFrontEnd:PushScreen(notepad)
    end
end

-- Add key handler
TheInput:AddKeyDownHandler(_G[TOGGLE_KEY], ToggleNotepad)

-- Initialize notepad when player spawns
AddPlayerPostInit(function(player)
    if player == ThePlayer then
        notepad = NotepadWidget()
    end
end) 