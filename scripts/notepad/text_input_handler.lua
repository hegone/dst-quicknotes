--[[
    Text Input Handler Module for DST Quick Notes
    
    This module handles text input processing and automatic line breaking for the notepad.
    It works closely with TextUtils to provide a smooth typing experience with
    automatic formatting and input validation.
    
    Usage:
        local TextInputHandler = require "notepad/text_input_handler"
        local handler = TextInputHandler(text_utils)
        handler:HandleTextInput(editor, char, config)
]]

local TextUtils = require "notepad/text_utils"

--[[
    TextInputHandler Class
    
    Processes text input for the notepad editor, handling special characters,
    automatic line breaking, and input validation.
    
    @param text_utils (TextUtils) Reference to TextUtils instance for utility functions
]]
local TextInputHandler = Class(function(self, text_utils)
    self.text_utils = text_utils or TextUtils()
    
    -- List of invalid characters to filter out
    self.invalid_chars = {
        [string.char(8)] = true,    -- Backspace (handled separately)
        [string.char(22)] = true,   -- Synchronous idle
        [string.char(27)] = true,   -- ESC
    }
    
    -- Track if we're currently pasting
    self.pasting = false
end)

--[[
    Handles text input and automatic line breaking.
    
    @param editor (TextEdit) The text editor widget
    @param char (string) The character being input
    @param config (table) Configuration settings from config.lua
    @return (boolean) True if the input was handled
]]
function TextInputHandler:HandleTextInput(editor, char, config)
    if not char or char == "" or not editor.SetString then
        return false
    end

    -- Filter out control characters
    if self.invalid_chars[char] then
        return true
    end

    -- Handle control characters that might make it through
    if char:byte(1) < 32 and char ~= "\n" then
        -- Allow tab characters for indentation
        if char:byte(1) == 9 then  -- tab
            char = "    "  -- Convert to 4 spaces
        else
            -- Skip other control characters
            return true
        end
    end
    
    -- Handle alternative backspace codes
    if char == "\8" or char == "\127" then
        return self:HandleBackspace(editor)
    end

    -- Handle selection replacement
    if editor.selection_active and editor.selection_start ~= editor.selection_end then
        return self:ReplaceSelection(editor, char)
    end

    -- Handle normal character input
    return self:ProcessCharacterInput(editor, char, config)
end

--[[
    Replaces the current selection with input text.
    
    @param editor (TextEdit) The text editor widget
    @param char (string) The character to replace selection with
    @return (boolean) True if handled
]]
function TextInputHandler:ReplaceSelection(editor, char)
    local text = editor:GetString()
    local start_pos = math.min(editor.selection_start, editor.selection_end)
    local end_pos = math.max(editor.selection_start, editor.selection_end)
    
    -- Replace selection with new character
    local new_text = text:sub(1, start_pos) .. char .. text:sub(end_pos + 1)
    editor:SetString(new_text)
    
    -- Position cursor after inserted character
    editor:SetEditCursorPos(start_pos + #char)
    
    -- Clear selection
    editor.selection_active = false
    
    -- Notify editor to scroll if needed
    if editor.parent and editor.parent.ScrollToCursor then
        editor.parent:ScrollToCursor()
    end
    
    return true
end

--[[
    Handles backspace key input.
    
    @param editor (TextEdit) The text editor widget
    @return (boolean) True if handled, false otherwise
]]
function TextInputHandler:HandleBackspace(editor)
    local text = editor:GetString() or ""
    
    -- Safely get cursor position
    local cursor_pos = 0
    if editor.GetEditCursorPos then
        cursor_pos = editor:GetEditCursorPos()
    elseif editor.inst and editor.inst.TextEditWidget then
        cursor_pos = editor.inst.TextEditWidget:GetEditCursorPos()
    end
    
    -- Handle selection-based deletion if active
    if editor.selection_active and editor.selection_start ~= editor.selection_end then
        local start_pos = math.min(editor.selection_start, editor.selection_end)
        local end_pos = math.max(editor.selection_start, editor.selection_end)
        
        local new_text = text:sub(1, start_pos) .. text:sub(end_pos + 1)
        editor:SetString(new_text)
        
        -- Safely set cursor position
        if editor.SetEditCursorPos then
            editor:SetEditCursorPos(start_pos)
        elseif editor.inst and editor.inst.TextEditWidget then
            editor.inst.TextEditWidget:SetEditCursorPos(start_pos)
        end
        
        -- Clear selection
        editor.selection_active = false
        
        -- Notify editor to scroll if needed
        if editor.parent and editor.parent.ScrollToCursor then
            editor.parent:ScrollToCursor()
        end
        return true
    end
    
    if cursor_pos > 0 then
        local new_text = text:sub(1, cursor_pos - 1) .. text:sub(cursor_pos + 1)
        editor:SetString(new_text)
        editor:SetEditing(true)
        
        -- Safely set cursor position
        if editor.SetEditCursorPos then
            editor:SetEditCursorPos(cursor_pos - 1)
        elseif editor.inst and editor.inst.TextEditWidget then
            editor.inst.TextEditWidget:SetEditCursorPos(cursor_pos - 1)
        end
        
        -- Notify editor to scroll if needed
        if editor.parent and editor.parent.ScrollToCursor then
            editor.parent:ScrollToCursor()
        end
        return true
    end
    return false
end

--[[
    Processes a normal character input, including automatic line breaking.
    
    @param editor (TextEdit) The text editor widget
    @param char (string) The character being input
    @param config (table) Configuration settings
    @return (boolean) True if handled
]]
function TextInputHandler:ProcessCharacterInput(editor, char, config)
    local text = editor:GetString() or ""
    
    -- Safely get cursor position
    local cursor_pos = 0
    if editor.GetEditCursorPos then
        cursor_pos = editor:GetEditCursorPos()
    elseif editor.inst and editor.inst.TextEditWidget then
        cursor_pos = editor.inst.TextEditWidget:GetEditCursorPos()
    end
    
    -- Insert character at cursor position
    local new_text = text:sub(1, cursor_pos) .. char .. text:sub(cursor_pos + 1)
    local new_cursor_pos = cursor_pos + #char
    
    -- Check if line breaking is needed
    new_text, new_cursor_pos = self:CheckLineBreaking(new_text, new_cursor_pos, cursor_pos, editor, config)
    
    -- Update editor content and cursor
    editor:SetString(new_text)
    editor:SetEditing(true)
    
    -- Set cursor position if the method exists
    if editor.SetEditCursorPos then
        editor:SetEditCursorPos(new_cursor_pos)
    elseif editor.inst and editor.inst.TextEditWidget then
        editor.inst.TextEditWidget:SetEditCursorPos(new_cursor_pos)
    end
    
    -- Notify editor to scroll if needed
    if editor.parent and editor.parent.ScrollToCursor then
        editor.parent:ScrollToCursor()
    end
    
    return true
end

--[[
    Sets up paste handling, modeling after ConsoleScreen's approach.
    
    @param editor (TextEdit) The text editor widget
]]
function TextInputHandler:SetupPasteHandler(editor)
    -- Store original OnRawKey to chain it
    local original_on_raw_key = editor.OnRawKey
    
    editor.OnRawKey = function(widget, key, down)
        -- Check for paste key combo
        if down and TheInput:IsPasteKey(key) then
            self.pasting = true
            
            -- Get clipboard data
            local clipboard = TheSim:GetClipboardData()
            
            -- Process the clipboard text character by character
            for i = 1, #clipboard do
                local char = clipboard:sub(i, i)
                self:HandleTextInput(widget, char, editor.config)
            end
            
            self.pasting = false
            return true
        end
        
        -- Chain to original handler if not paste
        return original_on_raw_key(widget, key, down)
    end
end

--[[
    Checks if the text needs automatic line breaking and applies it if needed.
    
    @param text (string) The current text with new character
    @param cursor_pos (number) The current cursor position
    @param old_cursor_pos (number) The cursor position before input
    @param editor (TextEdit) The editor widget
    @param config (table) Configuration settings
    @return (string, number) The updated text and cursor position
]]
function TextInputHandler:CheckLineBreaking(text, cursor_pos, old_cursor_pos, editor, config)
    -- Split into lines and get the current line
    local lines = self.text_utils:SplitByLine(text)
    local current_line_num = 1
    local pos = 0
    
    -- Find which line the cursor is on
    for i, line in ipairs(lines) do
        pos = pos + #line + 1  -- +1 for newline
        if pos > old_cursor_pos then
            current_line_num = i
            break
        end
    end
    
    local current_line = lines[current_line_num]
    
    -- Check if the current line exceeds max width
    local width = self.text_utils:CalculateTextWidth(current_line, editor.font or DEFAULTFONT, editor.size or config.FONT_SIZES.EDITOR)
    
    if width > config.SETTINGS.MAX_LINE_WIDTH then
        -- Find nearest space for word wrap
        local break_index = self.text_utils:FindNearestSpace(current_line)
        
        if break_index then
            -- Break at space
            local before_break = current_line:sub(1, break_index - 1)
            local after_break = current_line:sub(break_index + 1)
            lines[current_line_num] = before_break
            table.insert(lines, current_line_num + 1, after_break)
            
            -- Adjust cursor position if it was after the break point
            if old_cursor_pos > pos - #current_line + break_index then
                cursor_pos = cursor_pos + 1  -- Account for added newline
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
                if old_cursor_pos > pos - #current_line + force_break_pos then
                    cursor_pos = cursor_pos + 1  -- Account for added newline
                end
            end
        end
        
        -- Reconstruct text with proper line breaks
        text = table.concat(lines, "\n")
    end
    
    return text, cursor_pos
end

--[[
    Handles the Enter key press for adding line breaks.
    
    @param editor (TextEdit) The text editor widget
    @param key (number) The key code being pressed
    @param down (boolean) Whether the key is being pressed down
    @return (boolean) True if Enter was handled, false otherwise
]]
function TextInputHandler:HandleEnterKey(editor, key, down)
    if not editor or not editor.SetString then
        return false
    end

    if down and (key == KEY_ENTER or key == KEY_KP_ENTER) then
        local text = editor:GetString()
        local cursor_pos = editor.GetEditCursorPos and editor:GetEditCursorPos() or #text
        
        -- Handle selection replacement
        if editor.selection_active and editor.selection_start ~= editor.selection_end then
            local start_pos = math.min(editor.selection_start, editor.selection_end)
            local end_pos = math.max(editor.selection_start, editor.selection_end)
            
            local new_text = text:sub(1, start_pos) .. "\n" .. text:sub(end_pos + 1)
            editor:SetString(new_text)
            editor:SetEditCursorPos(start_pos + 1)
            
            -- Clear selection
            editor.selection_active = false
        else
            -- Regular enter - insert newline
            local new_text = text:sub(1, cursor_pos) .. "\n" .. text:sub(cursor_pos + 1)
            editor:SetString(new_text)
            editor:SetEditCursorPos(cursor_pos + 1)
        end
        
        editor:SetEditing(true)
        
        -- Notify editor to scroll if needed
        if editor.parent and editor.parent.ScrollToCursor then
            editor.parent:ScrollToCursor()
        end
        
        return true
    end
    return false
end

return TextInputHandler