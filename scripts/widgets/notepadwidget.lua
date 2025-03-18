--[[
    Notepad Widget Module for DST Quick Notes
    
    This is the main widget module that creates and manages the notepad UI.
    It serves as the coordinator between UI components, state management,
    data persistence, and input handling.
    
    The widget uses DST's screen system and follows the game's UI styling
    to maintain a consistent look and feel.

    Usage:
        local NotepadWidget = require("widgets/notepadwidget")
        local notepad = NotepadWidget()
        notepad:OnBecomeActive()  -- Show the notepad
]]

local Screen = require "widgets/screen"
local Widget = require "widgets/widget"
local DataManager = require "notepad/data_manager"
local InputHandler = require "notepad/input_handler"
local NotepadEditor = require "notepad/notepad_editor"
local NotepadUI = require "widgets/notepad_ui"
local NotepadState = require "widgets/notepad_state"
local SoundManager = require "notepad/sound_manager"
local Config = require "notepad/config"

--[[
    NotepadWidget Class
    
    Main widget class that extends Screen to create a floating notepad interface.
    Manages the visual layout, user interaction, and data persistence of notes.
]]
local NotepadWidget = Class(Screen, function(self)
    Screen._ctor(self, "NotepadWidget")
    print("[Quick Notes] Creating NotepadWidget")
    
    -- Initialize core components
    self.data_manager = DataManager()
    self.state = NotepadState(self)
    
    -- Initialize UI components
    self.ui = NotepadUI(self)
    self.ui:InitializeBackground()
    self.ui:InitializeRootWidget()
    self.ui:InitializeUIComponents()
    
    -- Initialize input handling
    self.input_handler = InputHandler(self)
    
    -- Initialize editor after UI is set up
    self.editor = NotepadEditor(self.root, DEFAULTFONT, Config.FONT_SIZES.EDITOR)
    
    -- Initialize focus management using DST's standard approach
    self.focus_forward = self.editor.editor
    
    -- Set default focus and load saved notes
    self.default_focus = self.editor
    self:LoadNotes()
    
    print("[Quick Notes] NotepadWidget created successfully")
    self:Hide()
end)

--[[
    Updates widget state, primarily handling dragging.
]]
function NotepadWidget:OnUpdate()
    self.input_handler:UpdateDragging(self.root)
end

--[[
    Handles mouse button events.
    
    @param button (number) The mouse button being pressed
    @param down (boolean) Whether the button is being pressed down
    @param x (number) Mouse X position
    @param y (number) Mouse Y position
    @return (boolean) True if the input was handled
]]
function NotepadWidget:OnMouseButton(button, down, x, y)
    if self.input_handler:OnMouseButton(button, down, x, y) then
        return true
    end
    return NotepadWidget._base.OnMouseButton(self, button, down, x, y)
end

--[[
    Called when the widget becomes active.
    Handles showing the widget and setting up timers.
]]
function NotepadWidget:OnBecomeActive()
    print("[Quick Notes] NotepadWidget becoming active")
    NotepadWidget._base.OnBecomeActive(self)
    
    self:Show()
    self.root:ScaleTo(0, 1, Config.SETTINGS.OPEN_ANIMATION_DURATION)
    
    -- Play sound when opening using SoundManager
    SoundManager:PlaySound(SoundManager.SOUNDS.OPEN)
    
    self.input_handler:AddClickHandler()
    self.state:Activate()
end

--[[
    Called when the widget becomes inactive.
    Handles cleanup and saving.
]]
function NotepadWidget:OnBecomeInactive()
    print("[Quick Notes] NotepadWidget becoming inactive")
    NotepadWidget._base.OnBecomeInactive(self)
    
    -- Play sound when closing using SoundManager
    SoundManager:PlaySound(SoundManager.SOUNDS.CLOSE)
    
    self.input_handler:RemoveClickHandler()
    self:Hide()
    self.state:Deactivate()
end

--[[
    Closes the notepad widget.
]]
function NotepadWidget:Close()
    print("[Quick Notes] NotepadWidget closing")
    self:SaveNotes()
    self.state:SetOpen(false)
    if _G.TheFrontEnd:GetActiveScreen() == self then
        _G.TheFrontEnd:PopScreen(self)
    end
end

--[[
    Saves the current notes content.
]]
function NotepadWidget:SaveNotes()
    if not self.editor then return end
    local content = self.editor:GetText()
    if not content then return end
    
    if self.data_manager:SaveNotes(content) then
        self.state:ShowSaveIndicator("Saved!")
        -- Play sound when saving using SoundManager
        SoundManager:PlaySound(SoundManager.SOUNDS.SAVE)
    end
end

--[[
    Loads saved notes from persistent storage.
]]
function NotepadWidget:LoadNotes()
    self.data_manager:LoadNotes(function(success, content)
        if success and self.editor then
            self.editor:SetText(content)
        else
            if self.editor then
                self.editor:SetText("")
            end
        end
    end)
end

--[[
    Resets the notepad by clearing all content.
    Optionally saves the cleared state.
    
    @param save_state (boolean) Whether to save the cleared state (optional, defaults to true)
]]
function NotepadWidget:Reset(save_state)
    if not self.editor then return end
    
    -- Clear editor content
    self.editor:SetText("")
    
    -- Show feedback
    self.state:ShowSaveIndicator("Reset!")
    
    -- Play sound when resetting
    SoundManager:PlaySound(SoundManager.SOUNDS.RESET)
    
    -- Save cleared state if requested
    if save_state ~= false then
        self:SaveNotes()
    end
end

--[[
    Handles keyboard control events.
    
    @param control (number) The control code
    @param down (boolean) Whether the key is being pressed down
    @return (boolean) True if the input was handled
]]
function NotepadWidget:OnControl(control, down)
    if NotepadWidget._base.OnControl(self, control, down) then return true end
    return self.input_handler:OnControl(control, down)
end

--[[
    Handles raw key events for global shortcuts.
    
    @param key (number) The key code
    @param down (boolean) Whether the key is being pressed down
    @return (boolean) True if the key was handled
]]
function NotepadWidget:OnRawKey(key, down)
    -- Handle reset shortcut (Ctrl+R)
    if down and key == KEY_R and TheInput:IsKeyDown(KEY_CTRL) then
        self:Reset()
        return true
    end
    
    -- Forward to input handler for other shortcuts (like Ctrl+S)
    if self.input_handler:OnRawKey(key, down) then
        return true
    end
    
    return false
end

--[[
    Checks if the notepad is currently open.
    
    @return (boolean) True if the notepad is open
]]
function NotepadWidget:IsOpen()
    return self.state:IsOpen()
end

--[[
    Cleans up the widget and its components.
    Called when the widget is being destroyed.
]]
function NotepadWidget:OnDestroy()
    -- Clean up state and input handlers
    self.state:Cleanup()
    self.input_handler:RemoveClickHandler()
    
    -- Destroy UI components
    if self.save_indicator then self.save_indicator:Kill() end
    
    -- Clean up text utils inside editor
    if self.editor and self.editor.text_utils then
        self.editor.text_utils:Kill()
    end
    
    if self.editor then
        self.editor:Kill()
        self.editor = nil
    end
    
    if self.close_btn then self.close_btn:Kill() end
    if self.title then self.title:Kill() end
    if self.frame then self.frame:Kill() end
    if self.bg then self.bg:Kill() end
    
    NotepadWidget._base.OnDestroy(self)
end

return NotepadWidget