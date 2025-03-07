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

    -- Filter out ESC key sequences (may show as "?" or other characters)
    -- Only filter if ESC key is actually being pressed
    if TheInput:IsKeyDown(KEY_ESCAPE) then
        return true
    end
    
    -- ESC key sequences in terminal environments often start with these codes
    -- Only check for actual ESC character (byte 27), not "?" character
    if char:byte(1) == 27 then
        print("[Quick Notes] Filtered ESC key sequence")
        return true
    end
    
    -- Handle alternative backspace codes
    if char == "\8" or char == "\127" then
        return self:HandleBackspace(editor)
    end

    -- Handle normal character input
    return self:ProcessCharacterInput(editor, char, config)
end

--[[
    Handles backspace key input.
    
    @param editor (TextEdit) The text editor widget
    @return (boolean) True if handled, false otherwise
]]
function TextInputHandler:HandleBackspace(editor)
    local text = editor:GetString() or ""
    local cursor_pos = editor.GetEditCursorPos and editor:GetEditCursorPos() or #text
    if cursor_pos > 0 then
        local new_text = text:sub(1, cursor_pos - 1) .. text:sub(cursor_pos + 1)
        editor:SetString(new_text)
        editor:SetEditing(true)
        if editor.SetEditCursorPos then
            editor:SetEditCursorPos(cursor_pos - 1)
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
    local cursor_pos = editor.GetEditCursorPos and editor:GetEditCursorPos() or #text
    
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
    end
    
    return true
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
        
        local new_text = text:sub(1, cursor_pos) .. "\n" .. text:sub(cursor_pos + 1)
        editor:SetString(new_text)
        editor:SetEditing(true)
        
        if editor.SetEditCursorPos then
            editor:SetEditCursorPos(cursor_pos + 1)
        end
        return true
    end
    return false
end

return TextInputHandler