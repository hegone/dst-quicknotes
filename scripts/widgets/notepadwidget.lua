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
    if self.input_handler then
        self.input_handler:UpdateDragging(self.root)
    end
end

--[[
    Handles mouse button events for the entire notepad.
    
    @param button (number) The mouse button being pressed
    @param down (boolean) Whether the button is being pressed down
    @param x (number) Mouse X position
    @param y (number) Mouse Y position
    @return (boolean) True if the input was handled
]]
function NotepadWidget:OnMouseButton(button, down, x, y)
    -- First let the input handler try to handle it (dragging, etc)
    if self.input_handler and self.input_handler:OnMouseButton(button, down, x, y) then
        return true
    end
    
    -- If not handled by input handler, pass to parent class
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
    
    -- Add click handler to detect clicks within editor
    if self.input_handler then
        self.input_handler:AddClickHandler()
    end
    
    -- Activate state management
    if self.state then
        self.state:Activate()
    end
    
    -- Focus editor
    if self.editor then
        self.editor:SetFocus()
    end
end

--[[
    Called when the widget becomes inactive.
    Handles cleanup and saving.
]]
function NotepadWidget:OnBecomeInactive()
    print("[Quick Notes] NotepadWidget becoming inactive")
    NotepadWidget._base.OnBecomeInactive(self)
    
    -- Remove input handlers
    if self.input_handler then
        self.input_handler:RemoveClickHandler()
    end
    
    self:Hide()
    
    -- Deactivate state
    if self.state then
        self.state:Deactivate()
    end
end

--[[
    Closes the notepad widget.
]]
function NotepadWidget:Close()
    print("[Quick Notes] NotepadWidget closing")
    self:SaveNotes()
    
    if self.state then
        self.state:SetOpen(false)
    end
    
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
    
    if self.data_manager:SaveNotes(content) and self.state then
        self.state:ShowSaveIndicator("Saved!")
    end
end

--[[
    Loads saved notes from persistent storage.
]]
function NotepadWidget:LoadNotes()
    if not self.data_manager then return end
    
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
    if self.state then
        self.state:ShowSaveIndicator("Reset!")
    end
    
    -- Save cleared state if requested
    if save_state ~= false then
        self:SaveNotes()
    end
    
    -- Refocus editor
    self.editor:SetFocus()
end

--[[
    Handles keyboard control events.
    
    @param control (number) The control code
    @param down (boolean) Whether the key is being pressed down
    @return (boolean) True if the input was handled
]]
function NotepadWidget:OnControl(control, down)
    if NotepadWidget._base.OnControl(self, control, down) then return true end
    
    if self.input_handler then
        return self.input_handler:OnControl(control, down)
    end
    
    return false
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
    if self.input_handler and self.input_handler:OnRawKey(key, down) then
        return true
    end
    
    return false
end

--[[
    Checks if a point is within the widget's bounds.
    
    @param x (number) X coordinate to check
    @param y (number) Y coordinate to check
    @return (boolean) True if the point is within the widget
]]
function NotepadWidget:IsMouseInWidget(x, y)
    if self.ui then
        return self.ui:IsMouseInWidget(x, y)
    end
    return false
end

--[[
    Checks if the notepad is currently open.
    
    @return (boolean) True if the notepad is open
]]
function NotepadWidget:IsOpen()
    if self.state then
        return self.state:IsOpen()
    end
    return false
end

--[[
    Cleans up the widget and its components.
    Called when the widget is being destroyed.
]]
function NotepadWidget:OnDestroy()
    -- Clean up state and input handlers
    if self.state then
        self.state:Cleanup()
    end
    
    if self.input_handler then
        self.input_handler:RemoveClickHandler()
    end
    
    -- Destroy UI components
    if self.save_indicator then self.save_indicator:Kill() end
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