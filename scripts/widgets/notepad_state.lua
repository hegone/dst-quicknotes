--[[
    Notepad State Module for DST Quick Notes
    
    This module manages the state and lifecycle of the notepad widget.
    It handles auto-saving, indicators, focus management, and other
    state-related functionality. This module helps keep the main widget
    code clean by abstracting away state management details.
    
    Usage:
        local NotepadState = require "widgets/notepad_state"
        local state = NotepadState(parent_widget)
        state:StartAutoSave()
]]

local Config = require "notepad/config"

--[[
    NotepadState Class
    
    Manages the state and lifecycle of the notepad widget, including
    auto-saving, indicators, and focus management.
    
    @param parent (Widget) Parent widget that owns the state
]]
local NotepadState = Class(function(self, parent)
    self.parent = parent
    
    -- Initialize state
    self.isOpen = false
    
    -- Initialize timers
    self.save_timer = nil          -- Controls save indicator visibility
    self.auto_save_timer = nil     -- Handles periodic auto-saving
    self.focus_task = nil          -- Manages focus delay on open
end)

--[[
    Sets the open state of the notepad.
    
    @param isOpen (boolean) Whether the notepad is open
]]
function NotepadState:SetOpen(isOpen)
    self.isOpen = isOpen
end

--[[
    Checks if the notepad is currently open.
    
    @return (boolean) True if the notepad is open
]]
function NotepadState:IsOpen()
    return self.isOpen
end

--[[
    Starts the auto-save timer.
]]
function NotepadState:StartAutoSave()
    self:StopAutoSave()  -- Clean up any existing timer
    
    self.auto_save_timer = self.parent.inst:DoPeriodicTask(
        Config.SETTINGS.AUTO_SAVE_INTERVAL, 
        function()
            if self.parent.editor and self.parent.editor:GetText() then
                self.parent:SaveNotes()
            end
        end
    )
end

--[[
    Stops the auto-save timer.
]]
function NotepadState:StopAutoSave()
    if self.auto_save_timer then
        self.auto_save_timer:Cancel()
        self.auto_save_timer = nil
    end
end

--[[
    Shows the save indicator with a message.
    
    @param message (string) Message to display (optional)
]]
function NotepadState:ShowSaveIndicator(message)
    if not self.parent.save_indicator then return end
    
    self.parent.save_indicator:SetString(message or "")
    
    if self.save_timer then
        self.save_timer:Cancel()
        self.save_timer = nil
    end
    
    self.save_timer = self.parent.inst:DoTaskInTime(
        Config.SETTINGS.SAVE_INDICATOR_DURATION, 
        function()
            if self.parent.save_indicator then
                self.parent.save_indicator:SetString("")
            end
            self.save_timer = nil
        end
    )
end

--[[
    Handles focus management when the notepad becomes active.
    Sets up delayed focus and starts auto-save.
]]
function NotepadState:SetupFocus()
    if self.focus_task then
        self.focus_task:Cancel()
        self.focus_task = nil
    end
    
    self.focus_task = self.parent.inst:DoTaskInTime(
        Config.SETTINGS.FOCUS_DELAY, 
        function()
            if self.parent.editor then
                self.parent.editor:SetFocus()
                self:StartAutoSave()
            end
            self.focus_task = nil
        end
    )
end

--[[
    Cleans up all state timers and tasks.
    Called when the notepad is closing or being destroyed.
]]
function NotepadState:Cleanup()
    -- Cancel all timers
    self:StopAutoSave()
    
    if self.save_timer then
        self.save_timer:Cancel()
        self.save_timer = nil
    end
    
    if self.focus_task then
        self.focus_task:Cancel()
        self.focus_task = nil
    end
end

--[[
    Activates the notepad, setting up focus and state.
]]
function NotepadState:Activate()
    self:SetOpen(true)
    self:SetupFocus()
end

--[[
    Deactivates the notepad, cleaning up timers and saving.
]]
function NotepadState:Deactivate()
    self:SetOpen(false)
    self:StopAutoSave()
    self.parent:SaveNotes()  -- Save on close
    
    if self.focus_task then
        self.focus_task:Cancel()
        self.focus_task = nil
    end
end

return NotepadState