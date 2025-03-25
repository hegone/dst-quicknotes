--[[
    Notepad Widget Module for DST Quick Notes
    
    This is the main widget module that creates and manages the notepad UI.
    It serves as the coordinator between UI components, state management,
    data persistence, and input handling.
    
    The widget uses DST's screen system and follows the game's UI styling
    to maintain a consistent look and feel. Enhanced to better integrate
    with DST's console system patterns.

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
local FocusManager = require "notepad/focus_manager"
local Config = require "notepad/config"

--[[
    NotepadWidget Class
    
    Main widget class that extends Screen to create a floating notepad interface.
    Manages the visual layout, user interaction, and data persistence of notes.
]]
local NotepadWidget = Class(Screen, function(self)
    Screen._ctor(self, "NotepadWidget")
    print("[Quick Notes] Creating NotepadWidget")
    
    -- Initialize position tracking
    self.position = {x = 0, y = 0}
    
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
    
    -- Set up focus management, similar to ConsoleScreen approach
    FocusManager:SetupWidgetFocus(self, self.editor.editor)
    
    -- Set default focus and load saved notes
    self:LoadNotes()
    
    -- Enable CTRL+A to select all text
    self:SetupShortcuts()
    
    print("[Quick Notes] NotepadWidget created successfully")
    self:Hide()
end)

--[[
    Sets up additional keyboard shortcuts following DST's console patterns.
]]
function NotepadWidget:SetupShortcuts()
    -- We extend the OnRawKey handler to add global shortcuts like
    -- Ctrl+A for select all, similar to how ConsoleScreen handles special keys
    local original_on_raw_key = self.OnRawKey
    
    self.OnRawKey = function(self, key, down)
        -- Handle original first to maintain existing behavior
        if original_on_raw_key and original_on_raw_key(self, key, down) then
            return true
        end
        
        -- Add new shortcut handlers
        if down then
            -- CTRL+A for select all
            if key == KEY_A and TheInput:IsKeyDown(KEY_CTRL) then
                if self.editor and self.editor.editor then
                    local editor = self.editor.editor
                    local text = editor:GetString()
                    
                    -- Set selection to cover entire text
                    editor.selection_active = true
                    editor.selection_start = 0
                    editor.selection_end = #text
                    
                    -- Apply visual highlighting if supported
                    if editor.ShowHighlight then
                        editor:ShowHighlight(0, #text)
                    end
                    
                    return true
                end
            end
            
            -- Handle ESC key directly like ConsoleScreen
            if key == KEY_ESCAPE then
                self:Close()
                return true
            end
        end
        
        return false
    end
end

--[[
    Updates widget state, primarily handling dragging.
]]
function NotepadWidget:OnUpdate()
    self.input_handler:UpdateDragging(self.root)
    
    -- Update position when dragged
    if self.root and not self.position_update_pending then
        local pos = self.root:GetPosition()
        if pos.x ~= self.position.x or pos.y ~= self.position.y then
            self.position = {x = pos.x, y = pos.y}
            
            -- Throttle position updates to avoid excessive saves
            self.position_update_pending = true
            self.inst:DoTaskInTime(1, function()
                self.position_update_pending = false
            end)
        end
    end
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
    Improved to better match ConsoleScreen's approach.
]]
function NotepadWidget:OnBecomeActive()
    print("[Quick Notes] NotepadWidget becoming active")
    NotepadWidget._base.OnBecomeActive(self)
    
    self:Show()
    
    -- Apply saved position
    if self.position then
        self.root:SetPosition(self.position.x, self.position.y)
    end
    
    -- Animate opening
    self.root:ScaleTo(0, 1, Config.SETTINGS.OPEN_ANIMATION_DURATION)
    
    -- Play sound when opening
    SoundManager:PlaySound(SoundManager.SOUNDS.OPEN)
    
    -- Set up click handlers and state
    self.input_handler:AddClickHandler()
    self.state:Activate()
    
    -- Set focus after a short delay to allow animation to complete
    -- This mirrors ConsoleScreen's approach to focus management
    self.inst:DoTaskInTime(0.1, function()
        if self.editor and self.editor.editor then
            self.editor.editor:SetFocus()
            self.editor.editor:SetEditing(true)
        end
    end)
end

--[[
    Called when the widget becomes inactive.
    Handles cleanup and saving.
]]
function NotepadWidget:OnBecomeInactive()
    print("[Quick Notes] NotepadWidget becoming inactive")
    NotepadWidget._base.OnBecomeInactive(self)
    
    -- Explicitly stop editing, mirroring ConsoleScreen's cleanup
    if self.editor and self.editor.editor then
        self.editor.editor:SetEditing(false)
    end
    
    -- Play sound when closing
    SoundManager:PlaySound(SoundManager.SOUNDS.CLOSE)
    
    -- Save notes and clean up
    self:SaveNotes()
    self.input_handler:RemoveClickHandler()
    self:Hide()
    self.state:Deactivate()
end

--[[
    Closes the notepad widget.
]]
function NotepadWidget:Close()
    print("[Quick Notes] NotepadWidget closing")
    
    -- Stop editing explicitly before closing, like ConsoleScreen does
    if self.editor and self.editor.editor then
        self.editor.editor:SetEditing(false)
    end
    
    -- Save and clean up
    self:SaveNotes()
    self.state:SetOpen(false)
    
    -- Pop screen
    if _G.TheFrontEnd:GetActiveScreen() == self then
        _G.TheFrontEnd:PopScreen(self)
    end
end

--[[
    Saves the current notes content and position.
]]
function NotepadWidget:SaveNotes()
    if not self.editor then return end
    
    local content = self.editor:GetText()
    if not content then return end
    
    -- Update position from root widget
    if self.root then
        local pos = self.root:GetPosition()
        self.position = {x = pos.x, y = pos.y}
    end
    
    -- Save content and position
    if self.data_manager:SaveNotes(content, self.position) then
        self.state:ShowSaveIndicator("Saved!")
        -- Play sound when saving
        SoundManager:PlaySound(SoundManager.SOUNDS.SAVE)
    end
end

--[[
    Loads saved notes and position from persistent storage.
]]
function NotepadWidget:LoadNotes()
    self.data_manager:LoadNotes(function(success, content, position)
        if success then
            -- Load content
            if self.editor then
                self.editor:SetText(content)
            end
            
            -- Restore position if available
            if position then
                self.position = position
                if self.root then
                    self.root:SetPosition(position.x, position.y)
                end
            end
        else
            -- No saved notes found
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
    
    -- Before clearing, create a backup
    local content = self.editor:GetText()
    if content and #content > 0 then
        self.data_manager:CreateBackup(content, self.position)
    end
    
    -- Clear editor content
    self.editor:SetText("")
    
    -- Set focus after reset, consistent with ConsoleScreen behavior
    if self.editor.editor then
        self.editor.editor:SetFocus()
        self.editor.editor:SetEditing(true)
    end
    
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
    Updates the widget position.
    
    @param x (number) New X position
    @param y (number) New Y position
]]
function NotepadWidget:UpdatePosition(x, y)
    self.position = {x = x, y = y}
    if self.root then
        self.root:SetPosition(x, y)
    end
end

--[[
    Handles keyboard control events.
    
    @param control (number) The control code
    @param down (boolean) Whether the key is being pressed down
    @return (boolean) True if the input was handled
]]
function NotepadWidget:OnControl(control, down)
    -- Following ConsoleScreen's pattern for control handling
    if self.runtask ~= nil or NotepadWidget._base.OnControl(self, control, down) then 
        return true 
    end
    
    -- Handle cancel control directly, like ConsoleScreen
    if not down and (control == CONTROL_CANCEL) then
        self:Close()
        return true
    end
    
    return self.input_handler:OnControl(control, down)
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
    -- Save notes one last time
    self:SaveNotes()
    
    -- Stop editing explicitly before destroying, like ConsoleScreen
    if self.editor and self.editor.editor then
        self.editor.editor:SetEditing(false)
    end
    
    -- Clean up state and input handlers
    self.state:Cleanup()
    self.input_handler:RemoveClickHandler()
    
    -- Clean up components in a more thorough way
    if self.editor then
        self.editor:Kill()
        self.editor = nil
    end
    
    if self.ui then
        -- Let UI handle component cleanup
        self.ui = nil
    end
    
    -- Explicitly set component references to nil
    self.root = nil
    self.data_manager = nil
    self.state = nil
    self.input_handler = nil
    
    -- Call base OnDestroy
    NotepadWidget._base.OnDestroy(self)
end

return NotepadWidget