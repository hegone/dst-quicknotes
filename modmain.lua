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

local function ToggleNotepad()
    print("Toggle Notepad called, key pressed:", TOGGLE_KEY)
    
    if not _G.ThePlayer or not _G.ThePlayer.HUD then
        print("No player or HUD found")
        return
    end
    
    if notepad and notepad.isOpen then
        print("Closing notepad")
        notepad:Close()
        notepad = nil
    else
        print("Creating new notepad")
        notepad = _G.NotepadWidget()
        print("Opening notepad")
        _G.TheFrontEnd:PushScreen(notepad)
    end
end

-- Key handler
TheInput:AddKeyDownHandler(_G[TOGGLE_KEY], function()
    if _G.ThePlayer and _G.ThePlayer.HUD and not _G.ThePlayer.HUD:HasInputFocus() then
        ToggleNotepad()
    end
end)
