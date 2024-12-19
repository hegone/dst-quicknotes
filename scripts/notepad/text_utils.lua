--[[
    Text Utilities Module for DST Quick Notes
    
    This module provides common text editing utilities and initialization
    functions used across the notepad mod. It centralizes text-related
    functionality to ensure consistent behavior and reduce code duplication.

    The module handles:
    - Text editor initialization with standard settings
    - Enter key handling for line breaks
    - Focus management and visual feedback
    
    Usage:
        local TextUtils = require("notepad/text_utils")
        local utils = TextUtils()
        utils:InitializeEditor(my_editor, config)
]]

--[[
    TextUtils Class
    
    Provides utility functions for text editing operations and editor setup.
    This class centralizes common text manipulation and editor initialization
    logic to ensure consistent behavior across the mod.
]]
local TextUtils = Class(function(self)
    -- No initialization needed currently
end)

--[[
    Handles the Enter key press for adding line breaks.
    
    @param editor (TextEdit) The text editor widget
    @param key (number) The key code being pressed
    @param down (boolean) Whether the key is being pressed down
    @return (boolean) True if Enter was handled, false otherwise
]]
function TextUtils:HandleEnterKey(editor, key, down)
    if down and (key == KEY_ENTER or key == KEY_KP_ENTER) then
        local text = editor:GetString()
        editor:SetString(text .. "\n")
        editor:SetEditing(true)
        return true
    end
    return false
end

--[[
    Sets up focus gain and loss handlers for the editor.
    Manages visual feedback when the editor gains or loses focus.
    
    @param editor (TextEdit) The text editor widget to set up handlers for
]]
function TextUtils:SetupFocusHandlers(editor)
    function editor:OnGainFocus()
        TextEdit.OnGainFocus(self)
        self:SetEditing(true)
        -- Set text color to white when focused
        self:SetColour(1, 1, 1, 1)
    end
    
    function editor:OnLoseFocus()
        TextEdit.OnLoseFocus(self)
        -- Maintain white color when unfocused for consistency
        self:SetColour(1, 1, 1, 1)
    end
end

--[[
    Initializes a text editor with standard settings and handlers.
    
    Sets up common properties including:
    - Position and size
    - Text alignment
    - Scrolling and word wrap
    - Text length limits
    - Color settings
    - Key handlers
    - Focus handlers
    
    @param editor (TextEdit) The text editor widget to initialize
    @param config (table) Configuration settings from config.lua
]]
function TextUtils:InitializeEditor(editor, config)
    -- Set basic position and dimensions
    editor:SetPosition(0, 0)
    editor:SetRegionSize(config.DIMENSIONS.EDITOR.WIDTH, config.DIMENSIONS.EDITOR.HEIGHT)
    
    -- Configure text alignment
    editor:SetHAlign(ANCHOR_LEFT)
    editor:SetVAlign(ANCHOR_TOP)
    
    -- Enable editor features
    editor:EnableScrollEditWindow(true)
    editor:EnableWordWrap(true)
    editor:SetTextLengthLimit(config.SETTINGS.TEXT_LENGTH_LIMIT)
    
    -- Set text color from config
    editor:SetColour(
        config.COLORS.EDITOR_TEXT.r,
        config.COLORS.EDITOR_TEXT.g,
        config.COLORS.EDITOR_TEXT.b,
        config.COLORS.EDITOR_TEXT.a
    )
    
    -- Initialize with empty content
    editor:SetString("")
    editor.allow_newline = true
    
    -- Set up key handling for special keys (e.g., Enter)
    function editor:OnRawKey(key, down)
        if TextUtils:HandleEnterKey(self, key, down) then
            return true
        end
        return TextEdit.OnRawKey(self, key, down)
    end
    
    -- Initialize focus handling
    TextUtils:SetupFocusHandlers(editor)
end

return TextUtils