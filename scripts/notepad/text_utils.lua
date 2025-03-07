--[[
    Text Utilities Module for DST Quick Notes
    
    This module provides common text editing utilities used across the notepad mod.
    It centralizes text-related functionality to ensure consistent behavior
    and reduce code duplication.

    The module handles:
    - Text editor initialization with standard settings
    - Text width calculation
    - Line splitting and analysis
    - Focus handling for text widgets
    
    Usage:
        local TextUtils = require("notepad/text_utils")
        local utils = TextUtils()
        local width = utils:CalculateTextWidth("Example text", "buttonfont", 25)
]]

local Text = require "widgets/text"
local Widget = require "widgets/widget"
local TextEdit = require "widgets/textedit"

--[[
    TextUtils Class
    
    Provides utility functions for text editing operations and editor setup.
    This class centralizes common text manipulation logic to ensure consistent
    behavior across the mod.
]]
local TextUtils = Class(function(self)
    -- Initialize widget base for text measurement
    self.measuring_widget = Widget("TextMeasurer")
end)

--[[
    Calculates the width of a text string in pixels.
    Uses a temporary Text widget for accurate measurement.
    
    @param str (string) The text string to measure
    @param font (string) The font to use for measurement
    @param font_size (number) Font size to use for measurement
    @return (number) The width of the text in pixels
]]
function TextUtils:CalculateTextWidth(str, font, font_size)
    if not str then return 0 end
    
    -- Create text widget as child of measuring widget
    local measuring_text = self.measuring_widget:AddChild(Text(font or DEFAULTFONT, font_size or 25))
    local w, h
    
    -- Use pcall to ensure cleanup even if SetString fails
    local status, err = pcall(function()
        measuring_text:SetString(str)
        w, h = measuring_text:GetRegionSize()
    end)
    
    -- Clean up the text widget
    if measuring_text then
        measuring_text:Kill()
    end
    
    if not status then
        print("[Quick Notes] Text measurement error:", err)
        return 0
    end
    
    return w
end

--[[
    Splits text into an array of lines.
    
    @param text (string) The text to split
    @return (table) Array of lines
]]
function TextUtils:SplitByLine(text)
    if not text or text == "" then
        return {""}
    end

    local lines = {}
    local current_line = ""
    
    for char in text:gmatch(".") do
        if char == "\n" then
            table.insert(lines, current_line)
            current_line = ""
        else
            current_line = current_line .. char
        end
    end
    table.insert(lines, current_line)
    return lines
end

--[[
    Finds the nearest space from the end of the line for word wrapping.
    
    @param line (string) The line to search in
    @return (number) Index of the last space, or nil if no space found
]]
function TextUtils:FindNearestSpace(line)
    -- Start from end and work backwards to find last space
    for i = #line, 1, -1 do
        if line:sub(i, i) == " " then
            return i
        end
    end
    return nil
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
    
    @param editor (TextEdit) The text editor widget to initialize
    @param config (table) Configuration settings from config.lua
]]
function TextUtils:InitializeEditor(editor, config)
    if not editor then
        return
    end

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
    
    -- Initialize focus handling
    TextUtils:SetupFocusHandlers(editor)
end

return TextUtils