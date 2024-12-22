--[[
    Text Utilities Module for DST Quick Notes
    
    This module provides common text editing utilities and initialization
    functions used across the notepad mod. It centralizes text-related
    functionality to ensure consistent behavior and reduce code duplication.

    The module handles:
    - Text editor initialization with standard settings
    - Enter key handling for line breaks
    - Focus management and visual feedback
    - Text width calculation for line breaking
    
    Usage:
        local TextUtils = require("notepad/text_utils")
        local utils = TextUtils()
        utils:InitializeEditor(my_editor, config)
]]

local Text = require "widgets/text"
local Widget = require "widgets/widget"
local TextEdit = require "widgets/textedit"

--[[
    TextUtils Class
    
    Provides utility functions for text editing operations and editor setup.
    This class centralizes common text manipulation and editor initialization
    logic to ensure consistent behavior across the mod.
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
    Handles the Enter key press for adding line breaks.
    
    @param editor (TextEdit) The text editor widget
    @param key (number) The key code being pressed
    @param down (boolean) Whether the key is being pressed down
    @return (boolean) True if Enter was handled, false otherwise
]]
function TextUtils:HandleEnterKey(editor, key, down)
    if not editor or not editor.SetString then
        return false
    end

    if down and (key == KEY_ENTER or key == KEY_KP_ENTER) then
        local text = editor:GetString()
        local cursor_pos = #text + 1
        editor:SetString(text .. "\n")
        editor:SetEditing(true)
        if editor.SetEditCursorPos then
            editor:SetEditCursorPos(cursor_pos)
        end
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
    Handles text input and automatic line breaking.
    
    @param editor (TextEdit) The text editor widget
    @param char (string) The character being input
    @param config (table) Configuration settings from config.lua
    @return (boolean) True if the input was handled
]]
function TextUtils:HandleTextInput(editor, char, config)
    if not char or char == "" or not editor.SetString then
        return false
    end

    local text = editor:GetString() or ""
    local cursor_pos = editor.GetEditCursorPos and editor:GetEditCursorPos() or #text
    
    -- Insert character at cursor position
    local new_text = text:sub(1, cursor_pos) .. char .. text:sub(cursor_pos + 1)
    local new_cursor_pos = cursor_pos + #char
    
    -- Split into lines and get the current line
    local lines = self:SplitByLine(new_text)
    local current_line_num = 1
    local pos = 0
    
    -- Find which line the cursor is on
    for i, line in ipairs(lines) do
        pos = pos + #line + 1  -- +1 for newline
        if pos > cursor_pos then
            current_line_num = i
            break
        end
    end
    
    local current_line = lines[current_line_num]
    
    -- Check if the current line exceeds max width
    local width = self:CalculateTextWidth(current_line, editor.font or DEFAULTFONT, editor.size or config.FONT_SIZES.EDITOR)
    
    if width > config.SETTINGS.MAX_LINE_WIDTH then
        -- Find nearest space for word wrap
        local break_index = self:FindNearestSpace(current_line)
        
        if break_index then
            -- Break at space
            local before_break = current_line:sub(1, break_index - 1)
            local after_break = current_line:sub(break_index + 1)
            lines[current_line_num] = before_break
            table.insert(lines, current_line_num + 1, after_break)
            
            -- Adjust cursor position if it was after the break point
            if cursor_pos > pos - #current_line + break_index then
                new_cursor_pos = new_cursor_pos + 1  -- Account for added newline
            end
        else
            -- Force break if no space found (long word)
            local force_break_pos = math.floor(#current_line * (config.SETTINGS.MAX_LINE_WIDTH / width))
            if force_break_pos > 0 then
                local first_part = current_line:sub(1, force_break_pos)
                local second_part = current_line:sub(force_break_pos + 1)
                lines[current_line_num] = first_part
                table.insert(lines, current_line_num + 1, second_part)
                
                -- Adjust cursor position if it was after the break point
                if cursor_pos > pos - #current_line + force_break_pos then
                    new_cursor_pos = new_cursor_pos + 1  -- Account for added newline
                end
            end
        end
        
        -- Reconstruct text with proper line breaks
        new_text = table.concat(lines, "\n")
    end
    
    -- Update editor content and cursor
    editor:SetString(new_text)
    editor:SetEditing(true)
    
    -- Set cursor position if the method exists
    if editor.SetEditCursorPos then
        editor:SetEditCursorPos(new_cursor_pos)
    end
    
    return true
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
    
    -- Set up text input handling with auto line break
    function editor:OnTextInput(text)
        if TextUtils:HandleTextInput(self, text, config) then
            return true
        end
        return TextEdit.OnTextInput(self, text)
    end
    
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