--[[
    Focus Manager Module for DST Quick Notes
    
    This module centralizes focus-related functionality for UI components.
    It provides consistent focus behavior for text editors and other widgets.
    
    Usage:
        local FocusManager = require("notepad/focus_manager")
        FocusManager:SetupEditorFocusHandlers(editor, colors)
]]


local TextEdit = require "widgets/textedit"

local FocusManager = {}

--[[
    Sets up focus gain and loss handlers for a text editor.
    
    @param editor (TextEdit) The text editor widget to set up handlers for
    @param colors (table) Optional colors for focused/unfocused states {r, g, b, a}
]]
function FocusManager:SetupEditorFocusHandlers(editor, colors)
    colors = colors or {r=1, g=1, b=1, a=1}
    
    function editor:OnGainFocus()
        TextEdit.OnGainFocus(self)
        self:SetEditing(true)
        self:SetColour(colors.r, colors.g, colors.b, colors.a)
    end
    
    function editor:OnLoseFocus()
        TextEdit.OnLoseFocus(self)
        -- Maintain same color when unfocused for consistency
        self:SetColour(colors.r, colors.g, colors.b, colors.a)
    end
end

return FocusManager