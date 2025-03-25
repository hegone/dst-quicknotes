--[[
    Focus Manager Module for DST Quick Notes
    
    This module centralizes focus-related functionality for UI components.
    It provides consistent focus behavior for text editors and other widgets.
    Enhanced to better mimic the DST console focus system.
    
    Usage:
        local FocusManager = require("notepad/focus_manager")
        FocusManager:SetupEditorFocusHandlers(editor, colors)
]]


local TextEdit = require "widgets/textedit"

local FocusManager = {}

--[[
    Sets up focus gain and loss handlers for a text editor.
    This approach mirrors DST's ConsoleScreen focus handling.
    
    @param editor (TextEdit) The text editor widget to set up handlers for
    @param colors (table) Optional colors for focused/unfocused states {r, g, b, a}
]]
function FocusManager:SetupEditorFocusHandlers(editor, colors)
    colors = colors or {r=1, g=1, b=1, a=1}
    
    -- Store original handlers to chain them
    local original_gain_focus = editor.OnGainFocus
    local original_lose_focus = editor.OnLoseFocus
    
    -- Set up improved focus gain handler
    function editor:OnGainFocus()
        -- Call original handler first
        if original_gain_focus then
            original_gain_focus(self)
        else
            TextEdit.OnGainFocus(self)
        end
        
        -- Set editing state (following ConsoleScreen pattern)
        self:SetEditing(true)
        
        -- Apply active text color
        self:SetColour(colors.r, colors.g, colors.b, colors.a)
        
        -- Show edit cursor (explicit call mimicking ConsoleScreen)
        if self.inst and self.inst.TextWidget then
            self.inst.TextWidget:ShowEditCursor(true)
        end
    end
    
    -- Set up improved focus loss handler
    function editor:OnLoseFocus()
        -- Call original handler first
        if original_lose_focus then
            original_lose_focus(self)
        else
            TextEdit.OnLoseFocus(self)
        end
        
        -- Maintain same color when unfocused for consistency
        self:SetColour(colors.r, colors.g, colors.b, colors.a)
        
        -- Only hide cursor if not actively editing
        if not self.editing and self.inst and self.inst.TextWidget then
            self.inst.TextWidget:ShowEditCursor(false)
        end
    end
    
    -- Add ConsoleScreen-like behavior for stopping editing
    function editor:StopEditing()
        self:SetEditing(false)
        if self.inst and self.inst.TextWidget then
            self.inst.TextWidget:ShowEditCursor(false)
        end
    end
end

--[[
    Sets up a widget to handle focus properly similar to ConsoleScreen approach.
    
    @param widget (Widget) The widget to set up focus handlers for
    @param default_focus (Widget) The widget that should receive focus by default
]]
function FocusManager:SetupWidgetFocus(widget, default_focus)
    -- Store the default focus target
    widget.default_focus = default_focus
    
    -- Set focus forwarding to ensure proper tab behavior
    widget.focus_forward = default_focus
    
    -- Extend the widget's OnBecomeActive to set focus automatically
    local original_become_active = widget.OnBecomeActive
    
    function widget:OnBecomeActive()
        if original_become_active then
            original_become_active(self)
        end
        
        -- Focus the default widget after a small delay
        self.inst:DoTaskInTime(0.1, function()
            if self.default_focus then
                self.default_focus:SetFocus()
            end
        end)
    end
end

--[[
    Sets up keyboard focus cycling between widgets, similar to 
    ConsoleScreen's tab behavior.
    
    @param widgets (table) Array of widgets to cycle focus between
]]
function FocusManager:SetupFocusCycling(widgets)
    if not widgets or #widgets < 2 then return end
    
    for i, widget in ipairs(widgets) do
        -- Determine the next widget in the cycle
        local next_widget = widgets[i % #widgets + 1]
        
        -- Set up the widget's OnRawKey to handle tab
        local original_on_raw_key = widget.OnRawKey
        
        widget.OnRawKey = function(self, key, down)
            -- Handle tab key to move focus forward
            if down and key == KEY_TAB then
                self:SetEditing(false)
                next_widget:SetFocus()
                next_widget:SetEditing(true)
                return true
            end
            
            -- Chain to original handler
            if original_on_raw_key then
                return original_on_raw_key(self, key, down)
            end
            return false
        end
        
        -- Ensure TAB is in validrawkeys
        widget.validrawkeys = widget.validrawkeys or {}
        widget.validrawkeys[KEY_TAB] = true
    end
end

return FocusManager