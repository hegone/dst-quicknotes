-- scripts/notepad/editor_key_handler.lua
--[[
    Editor Key Handler Module for DST Quick Notes
    
    This module handles keyboard input for the notepad editor.
    It manages special key combinations, cursor movement,
    and text editing operations. The module separates key handling
    logic from the main editor code for better organization.
    
    Usage:
        local EditorKeyHandler = require "notepad/editor_key_handler"
        local handler = EditorKeyHandler(editor)
        handler:HandleKeyCommand(key, down)
]]

local TextEdit = require "widgets/textedit"

-- Helper function to check if a character is whitespace
local function IsWhitespace(char)
    return char == " " or char == "\n" or char == "\t" -- Added tab just in case
end

--[[
    EditorKeyHandler Class
    
    Manages keyboard input for the notepad editor, providing custom
    key handling for special keys and operations.
    
    @param editor (NotepadEditor) The editor instance this handler works with
]]
local EditorKeyHandler = Class(function(self, editor)
    self.editor = editor
    
    -- Track selection state
    self.selection_active = false
    self.selection_start = 0
    self.selection_end = 0
end)

--[[
    Sets up the OnRawKey handler for a TextEdit widget.
    
    @param text_edit (TextEdit) The text edit widget to set up
]]
function EditorKeyHandler:SetupKeyHandler(text_edit)
    -- Store reference to the original OnRawKey method
    local original_on_raw_key = text_edit.OnRawKey
    
    -- Replace with our custom handler
    text_edit.OnRawKey = function(widget, key, down)
        -- Use self from the outer scope (the EditorKeyHandler instance)
        local result = self:ProcessKey(widget, key, down)
        if result ~= nil then
            return result
        end
        -- Fall back to original handler if we didn't handle the key
        if original_on_raw_key then
            return original_on_raw_key(widget, key, down)
        else
            -- If original doesn't exist, provide default TextEdit behavior as fallback
            return TextEdit.OnRawKey(widget, key, down)
        end
    end
    
    -- Setup validrawkeys for special keys, mirroring ConsoleScreen approach
    text_edit.validrawkeys = text_edit.validrawkeys or {}
    text_edit.validrawkeys[KEY_HOME] = true
    text_edit.validrawkeys[KEY_END] = true
    text_edit.validrawkeys[KEY_PAGEUP] = true
    text_edit.validrawkeys[KEY_PAGEDOWN] = true
    text_edit.validrawkeys[KEY_LEFT] = true
    text_edit.validrawkeys[KEY_RIGHT] = true
    text_edit.validrawkeys[KEY_UP] = true
    text_edit.validrawkeys[KEY_DOWN] = true
    text_edit.validrawkeys[KEY_CTRL] = true
    text_edit.validrawkeys[KEY_SHIFT] = true
    text_edit.validrawkeys[KEY_BACKSPACE] = true -- Ensure backspace is valid
    text_edit.validrawkeys[KEY_DELETE] = true    -- Add delete key
    text_edit.validrawkeys[KEY_ENTER] = true     -- Ensure enter is valid
    text_edit.validrawkeys[KEY_KP_ENTER] = true  -- Ensure keypad enter is valid
end

--[[
    Processes a key press and determines how to handle it.
    This is the main entry point for key handling.
    
    @param widget (TextEdit) The text widget receiving the key
    @param key (number) The key code being pressed
    @param down (boolean) Whether the key is being pressed down
    @return (boolean or nil) True if the key was handled, nil to pass to original handler
]]
function EditorKeyHandler:ProcessKey(widget, key, down)
    -- Handle ESC key to prevent text input
    if key == KEY_ESCAPE and down then
        -- Let the parent widget handle the ESC key for closing
        if widget.parent and widget.parent.parent and widget.parent.parent.Close then
            widget.parent.parent:Close()
        end
        return true
    end
    
    -- Skip processing for key up events
    if not down then
        return nil
    end

    -- Handle global shortcuts even when editor is focused
    -- Ctrl+S: Save
    if key == KEY_S and TheInput:IsKeyDown(KEY_CTRL) then
        if widget.parent and widget.parent.parent and widget.parent.parent.SaveNotes then
            widget.parent.parent:SaveNotes()
            return true
        end
    end
    -- Ctrl+R: Reset
    if key == KEY_R and TheInput:IsKeyDown(KEY_CTRL) then
        if widget.parent and widget.parent.parent and widget.parent.parent.Reset then
           widget.parent.parent:Reset()
           return true
       end
    end

    -- Check Delete key *before* HandleCursorMovement
    if key == KEY_DELETE then
        return self:HandleDelete(widget) -- Call new handler
    end

    -- Handle backspace explicitly
    if key == KEY_BACKSPACE then
        return self:HandleBackspace(widget)
    end

    -- Handle Enter key for line breaks
    if key == KEY_ENTER or key == KEY_KP_ENTER then
        return self:HandleEnterKey(widget)
    end

    -- Handle cursor movement and selection keys
    if self:HandleCursorMovement(widget, key) then
        return true
    end

    -- Let original handler process other keys
    return nil
end

--[[ NEW HELPER FUNCTION ]]
-- Finds the position of the start of the previous word.
function EditorKeyHandler:FindPreviousWordPosition(text, current_pos)
    if current_pos <= 0 then return 0 end

    local pos = current_pos - 1 -- Start checking from the character before the cursor

    -- 1. Skip backwards over any initial whitespace right before the cursor
    while pos >= 0 and IsWhitespace(text:sub(pos + 1, pos + 1)) do
        pos = pos - 1
    end

    -- 2. Skip backwards over the non-whitespace characters of the word
    while pos >= 0 and not IsWhitespace(text:sub(pos + 1, pos + 1)) do
        pos = pos - 1
    end

    -- The new position is after the last character skipped (which was either whitespace or start of text)
    return pos + 1
end

--[[ NEW HELPER FUNCTION ]]
-- Finds the position of the start of the next word.
function EditorKeyHandler:FindNextWordPosition(text, current_pos)
    local text_len = #text
    if current_pos >= text_len then return text_len end

    local pos = current_pos

    -- 1. Skip forwards over the non-whitespace characters of the current word (if any)
    while pos < text_len and not IsWhitespace(text:sub(pos + 1, pos + 1)) do
        pos = pos + 1
    end

    -- 2. Skip forwards over any whitespace characters after the word (or where the cursor started)
    while pos < text_len and IsWhitespace(text:sub(pos + 1, pos + 1)) do
        pos = pos + 1
    end

    -- The new position is at the start of the next word (or end of text)
    return pos
end

--[[
    Splits text into lines for cursor navigation.
    
    @param text (string) The text to split
    @return (table) Array of line strings
]]
function EditorKeyHandler:SplitTextIntoLines(text)
    if not text or text == "" then
        return {""}
    end
    
    local lines = {}
    local start = 1
    while true do
        local nl_pos = string.find(text, "\n", start, true) -- Find next newline, literal search
        if nl_pos then
            table.insert(lines, text:sub(start, nl_pos - 1))
            start = nl_pos + 1
        else
            table.insert(lines, text:sub(start)) -- Add the rest of the text
            break
        end
    end
    -- If the text ends with a newline, find adds an empty string at the end, which is correct.
    return lines
end

--[[ MODIFIED FUNCTION ]]
-- Handles cursor movement keys (arrows, home, end, page up/down, Ctrl+Arrows).
function EditorKeyHandler:HandleCursorMovement(widget, key)
    -- Ensure the widget has the needed methods
    if not widget.GetString then
        return false
    end
    
    local text = widget:GetString() or "" -- Ensure text is not nil
    
    -- Safely get cursor position
    local cursor_pos = 0
    if widget.GetEditCursorPos then
        cursor_pos = widget:GetEditCursorPos()
    elseif widget.inst and widget.inst.TextEditWidget then
        cursor_pos = widget.inst.TextEditWidget:GetEditCursorPos()
    end
    
    local lines = self:SplitTextIntoLines(text)
    local current_line, line_start, line_end = self:GetCurrentLineInfo(text, cursor_pos, lines)
    
    -- Check if selection modifier is active
    local selecting = TheInput:IsKeyDown(KEY_SHIFT)
    
    -- Initialize selection if shift is pressed and selection isn't active
    if selecting and not self.selection_active then
        self.selection_active = true
        self.selection_start = cursor_pos
        self.selection_end = cursor_pos
    -- Clear selection if shift isn't pressed AND we are moving cursor (not just pressing shift)
    elseif not selecting and self.selection_active then
       -- Check if it's a movement key that should clear selection
       if key == KEY_LEFT or key == KEY_RIGHT or key == KEY_UP or key == KEY_DOWN or 
          key == KEY_HOME or key == KEY_END or key == KEY_PAGEUP or key == KEY_PAGEDOWN then
          self.selection_active = false
          -- REMOVED: Non-functional call to widget:ClearHighlight()
       end
    end
    
    local new_pos = cursor_pos
    local handled = false -- Flag to track if a specific key logic was executed

    -- Check for Ctrl modifier for word jumps
    if TheInput:IsKeyDown(KEY_CTRL) then
        if key == KEY_LEFT then
            new_pos = self:FindPreviousWordPosition(text, cursor_pos)
            handled = true
        elseif key == KEY_RIGHT then
            new_pos = self:FindNextWordPosition(text, cursor_pos)
            handled = true
        end
        -- NOTE: Ctrl+Up/Down could be added later for paragraph jump or scroll without moving cursor
    end

    -- If Ctrl wasn't held or didn't handle the key, use standard navigation
    if not handled then
        if key == KEY_LEFT then
            if cursor_pos > 0 then
                new_pos = cursor_pos - 1
            end
            handled = true
        elseif key == KEY_RIGHT then
            if cursor_pos < #text then
                new_pos = cursor_pos + 1
            end
            handled = true
        elseif key == KEY_UP then
            if current_line > 1 then
                -- Calculate previous line's start safely
                local prev_line_start = 0
                for i = 1, current_line - 2 do
                    if i <= #lines then -- Check bounds
                        prev_line_start = prev_line_start + #lines[i] + 1
                    end
                end
                -- Use previously calculated line_start for current line column
                local current_column = cursor_pos - line_start
                local prev_line_text = lines[current_line - 1] or ""
                new_pos = prev_line_start + math.min(current_column, #prev_line_text)
            end
            handled = true
        elseif key == KEY_DOWN then
             if current_line < #lines then
                 local current_column = cursor_pos - line_start
                 -- line_end is the end of the current line content
                 local next_line_start = line_end + 1 -- Position after the current line's newline
                 local next_line_text = lines[current_line + 1] or ""
                 new_pos = next_line_start + math.min(current_column, #next_line_text)
            end
            handled = true
        elseif key == KEY_HOME then
            -- Recalculate line info reliably on Home/End press
            local home_line_num, home_line_start, _ = self:GetCurrentLineInfo(text, cursor_pos, lines)
            new_pos = home_line_start
            handled = true
        elseif key == KEY_END then
            -- Recalculate line info reliably on Home/End press
            local end_line_num, _, end_line_end = self:GetCurrentLineInfo(text, cursor_pos, lines)
            new_pos = end_line_end
            handled = true
        elseif key == KEY_PAGEUP then
            if current_line == 1 then
                new_pos = 0
            else
                local target_line = math.max(1, current_line - 10)
                local current_column = cursor_pos - line_start
                local target_line_pos = 0
                for i = 1, target_line - 1 do
                    if i <= #lines then
                        target_line_pos = target_line_pos + #lines[i] + 1
                    end
                end
                local target_line_text = lines[target_line] or ""
                local target_column = math.min(current_column, #target_line_text)
                new_pos = target_line_pos + target_column
            end
            handled = true
        elseif key == KEY_PAGEDOWN then
             if current_line == #lines then
                 new_pos = #text
             else
                 local target_line = math.min(#lines, current_line + 10)
                 local current_column = cursor_pos - line_start
                 local target_line_pos = 0
                 for i = 1, target_line - 1 do
                     if i <= #lines then
                         target_line_pos = target_line_pos + #lines[i] + 1
                     end
                 end
                 local target_line_text = lines[target_line] or ""
                 local target_column = math.min(current_column, #target_line_text)
                 new_pos = target_line_pos + target_column
            end
            handled = true
        end
    end
    
    -- If no movement key was handled, return false
    if not handled then
        return false
    end

    -- Do nothing if position hasn't changed
    if new_pos == cursor_pos then
        return true -- Still handled, just no change
    end
    
    -- Clamp new_pos just in case
    new_pos = math.max(0, math.min(#text, new_pos))

    -- Update cursor position safely
    if widget.SetEditCursorPos then
        widget:SetEditCursorPos(new_pos)
    elseif widget.inst and widget.inst.TextEditWidget then
        widget.inst.TextEditWidget:SetEditCursorPos(new_pos)
    end
    
    -- Update selection end if selecting
    if selecting then
        self.selection_end = new_pos
        -- REMOVED: Non-functional highlighting code block
        -- if widget.ShowHighlight then
        --      if widget.inst and widget.inst.TextWidget and widget.inst.TextWidget.SetHighlightColour then
        --           widget.inst.TextWidget:SetHighlightColour(0, 0.5, 1, 1) -- Blue
        --      end
        --     widget:ShowHighlight(math.min(self.selection_start, self.selection_end), math.max(self.selection_start, self.selection_end))
        -- end
    end
    
    -- Notify editor to scroll if needed
    if self.editor and self.editor.ScrollToCursor then
        self.editor:ScrollToCursor()
    end
    
    return true -- Indicate key was handled
end


--[[
    Handles backspace key press.
    
    @param widget (TextEdit) The text widget
    @return (boolean) True if handled, false otherwise
]]
function EditorKeyHandler:HandleBackspace(widget)
    local current_text = widget:GetString() or ""

    -- Safely get cursor position
    local cursor_pos = 0
    if widget.GetEditCursorPos then
        cursor_pos = widget:GetEditCursorPos()
    elseif widget.inst and widget.inst.TextEditWidget then
        cursor_pos = widget.inst.TextEditWidget:GetEditCursorPos()
    end

    local new_cursor_pos = cursor_pos
    local new_text = current_text
    local selection_was_active = self.selection_active and self.selection_start ~= self.selection_end

    -- Handle selection-based deletion if active
    if selection_was_active then
        local start_pos = math.min(self.selection_start, self.selection_end)
        local end_pos = math.max(self.selection_start, self.selection_end)
        new_text = current_text:sub(1, start_pos) .. current_text:sub(end_pos + 1)
        new_cursor_pos = start_pos
    -- Handle normal backspace if cursor is not at the beginning
    elseif cursor_pos > 0 then
        new_text = current_text:sub(1, cursor_pos - 1) .. current_text:sub(cursor_pos + 1)
        new_cursor_pos = cursor_pos - 1
    else
        -- At beginning of text and no selection, do nothing
        return false
    end

    -- Update text and cursor if changes were made
    if new_text ~= current_text then
        widget:SetString(new_text)

        -- Safely set cursor position
        if widget.SetEditCursorPos then
            widget:SetEditCursorPos(new_cursor_pos)
        elseif widget.inst and widget.inst.TextEditWidget then
            widget.inst.TextEditWidget:SetEditCursorPos(new_cursor_pos)
        end

        -- Clear selection state here if it was active
        if selection_was_active then
             self.selection_active = false
             -- REMOVED: Non-functional call to widget:ClearHighlight()
        end

        -- Notify editor to scroll if needed
        if self.editor and self.editor.ScrollToCursor then
            self.editor:ScrollToCursor()
        end
        return true
    end

    return false
end


--[[ Handles delete key press. ]]
function EditorKeyHandler:HandleDelete(widget)
    local current_text = widget:GetString() or ""

    -- Safely get cursor position
    local cursor_pos = 0
    if widget.GetEditCursorPos then
        cursor_pos = widget:GetEditCursorPos()
    elseif widget.inst and widget.inst.TextEditWidget then
        cursor_pos = widget.inst.TextEditWidget:GetEditCursorPos()
    end

    local new_cursor_pos = cursor_pos
    local new_text = current_text
    local selection_was_active = self.selection_active and self.selection_start ~= self.selection_end

    -- Handle selection-based deletion if active
    if selection_was_active then
        local start_pos = math.min(self.selection_start, self.selection_end)
        local end_pos = math.max(self.selection_start, self.selection_end)
        new_text = current_text:sub(1, start_pos) .. current_text:sub(end_pos + 1)
        new_cursor_pos = start_pos -- Cursor stays at the start of the deleted selection
    -- Handle normal delete if cursor is not at the end
    elseif cursor_pos < #current_text then
        new_text = current_text:sub(1, cursor_pos) .. current_text:sub(cursor_pos + 2)
        new_cursor_pos = cursor_pos -- Cursor position doesn't change
    else
        -- At end of text and no selection, do nothing
        return false
    end

    -- Update text and cursor if changes were made
    if new_text ~= current_text then
        widget:SetString(new_text)

        -- Safely set cursor position
        if widget.SetEditCursorPos then
            widget:SetEditCursorPos(new_cursor_pos)
        elseif widget.inst and widget.inst.TextEditWidget then
            widget.inst.TextEditWidget:SetEditCursorPos(new_cursor_pos)
        end

        -- Clear selection state here if it was active
        if selection_was_active then
             self.selection_active = false
             -- REMOVED: Non-functional call to widget:ClearHighlight()
        end

        -- Notify editor to scroll if needed
        if self.editor and self.editor.ScrollToCursor then
            self.editor:ScrollToCursor()
        end
        return true
    end

    return false
end

--[[ RESTORED FUNCTION ]]
-- Handles enter key press for line breaks.
function EditorKeyHandler:HandleEnterKey(widget)
    local text = widget:GetString() or ""
    local cursor_pos = 0
    if widget.GetEditCursorPos then cursor_pos = widget:GetEditCursorPos()
    elseif widget.inst and widget.inst.TextEditWidget then cursor_pos = widget.inst.TextEditWidget:GetEditCursorPos() end

    local new_text
    local new_cursor_pos
    local selection_was_active = self.selection_active and self.selection_start ~= self.selection_end

    if selection_was_active then
        local start_pos = math.min(self.selection_start, self.selection_end)
        local end_pos = math.max(self.selection_start, self.selection_end)
        new_text = text:sub(1, start_pos) .. "\n" .. text:sub(end_pos + 1)
        new_cursor_pos = start_pos + 1
    else
        new_text = text:sub(1, cursor_pos) .. "\n" .. text:sub(cursor_pos + 1)
        new_cursor_pos = cursor_pos + 1
    end

    widget:SetString(new_text)
    if widget.SetEditCursorPos then widget:SetEditCursorPos(new_cursor_pos)
    elseif widget.inst and widget.inst.TextEditWidget then widget.inst.TextEditWidget:SetEditCursorPos(new_cursor_pos) end

    if selection_was_active then
        self.selection_active = false
        -- REMOVED: Non-functional call to widget:ClearHighlight()
    end

    widget:SetEditing(true) -- May not be needed if SetString sets editing state
    if self.editor and self.editor.ScrollToCursor then self.editor:ScrollToCursor() end
    return true
end


--[[ Gets information about the line containing the cursor. ]]
-- Returns line number (1-based), line start position (0-based), line end position (0-based, inclusive of last char).
function EditorKeyHandler:GetCurrentLineInfo(text, cursor_pos, lines)
    lines = lines or self:SplitTextIntoLines(text)

    if #lines == 0 then return 1, 0, 0 end
    if #lines == 1 and #lines[1] == 0 and cursor_pos == 0 then return 1, 0, 0 end

    local current_char_pos = 0
    for i = 1, #lines do
        local line_start = current_char_pos
        local line_len = #lines[i]
        local line_end = line_start + line_len -- Position *after* the last character of the line content

        -- Case 1: Cursor is strictly within the line's content characters
        if cursor_pos >= line_start and cursor_pos < line_end then
            return i, line_start, line_end
        end

        -- Case 2: Cursor is exactly at the end of the line's content
        if cursor_pos == line_end then
            -- If it's the last line OR the next char isn't a newline, it belongs to this line
            if i == #lines or text:sub(line_end + 1, line_end + 1) ~= "\n" then
                 return i, line_start, line_end
            -- If it's exactly at the end of content AND followed by a newline,
            -- let Case 3 handle it by checking for the newline position.
            end
        end

        -- Case 3: Cursor is exactly at the newline position following this line
        if i < #lines and cursor_pos == line_end + 1 then
            -- This position logically belongs to the START of the *next* line (i+1)
            local next_line_start = line_end + 1
            local next_line_len = #lines[i+1]
            local next_line_end = next_line_start + next_line_len
            return i + 1, next_line_start, next_line_end
        end

        -- Move position marker to the start of the next potential line
        current_char_pos = line_end + 1 -- Assumes newline exists
    end

    -- Fallback: Cursor is likely past the very end of the text
    -- Return info for the last line
    local last_line_idx = math.max(1, #lines) -- Ensure index is at least 1
    local last_line_len = #lines[last_line_idx]
    local last_line_start = math.max(0, #text - last_line_len) -- Recalculate start based on end
    local last_line_end = last_line_start + last_line_len
    return last_line_idx, last_line_start, last_line_end
end


return EditorKeyHandler