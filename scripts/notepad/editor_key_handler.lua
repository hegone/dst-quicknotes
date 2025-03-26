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
        local result = self:ProcessKey(widget, key, down)
        if result ~= nil then
            return result
        end
        -- Fall back to original handler if we didn't handle the key
        return original_on_raw_key(widget, key, down)
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

--[[
    Handles cursor movement keys (arrows, home, end, page up/down).
    
    @param widget (TextEdit) The text widget
    @param key (number) The key code
    @return (boolean) True if handled, false otherwise
]]
function EditorKeyHandler:HandleCursorMovement(widget, key)
    -- Ensure the widget has the needed methods
    if not widget.GetString then
        return false
    end
    
    local text = widget:GetString()
    
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
    -- Clear selection if shift isn't pressed and selection is active
    elseif not selecting and self.selection_active then
        self.selection_active = false
    end
    
    local new_pos = cursor_pos
    
    -- Handle different navigation keys
    if key == KEY_LEFT then
        -- Move cursor left one character
        if cursor_pos > 0 then
            new_pos = cursor_pos - 1
        end
    elseif key == KEY_RIGHT then
        -- Move cursor right one character
        if cursor_pos < #text then
            new_pos = cursor_pos + 1
        end
    elseif key == KEY_UP then
        -- Move cursor up one line
        if current_line > 1 then
            local prev_line = lines[current_line - 1]
            local line_pos = cursor_pos - line_start
            new_pos = line_start - #prev_line - 1 + math.min(line_pos, #prev_line)
        end
    elseif key == KEY_DOWN then
        -- Move cursor down one line
        if current_line < #lines then
            local next_line = lines[current_line + 1]
            local line_pos = cursor_pos - line_start
            new_pos = line_end + 1 + math.min(line_pos, #next_line)
        end
    elseif key == KEY_HOME then
        -- Fix for Home key: Only move horizontally, never vertically
        
        -- Get full text and cursor position for reliable line detection
        local text_content = widget:GetString() or ""
        local cursor_position = cursor_pos
        
        -- Find which line the cursor is on right now - force recalculation
        local all_lines = self:SplitTextIntoLines(text_content)
        local position = 0
        local current_line_index = 1
        local current_line_start = 0
        
        for i, line in ipairs(all_lines) do
            local line_start = position
            local line_end = position + #line
            
            -- If cursor is in this range, this is our line
            if cursor_position >= line_start and cursor_position <= line_end then
                current_line_index = i
                current_line_start = line_start
                break
            end
            
            -- Special handling for newline character
            if i < #all_lines and cursor_position == line_end + 1 then
                current_line_index = i + 1  -- Next line
                current_line_start = line_end + 1
                break
            end
            
            position = line_end + 1  -- +1 for newline
        end
        
        -- Always go to start of current line
        new_pos = current_line_start
    elseif key == KEY_END then
        -- Fix for End key: Only move horizontally, never vertically
        
        -- Get full text and cursor position for reliable line detection
        local text_content = widget:GetString() or ""
        local cursor_position = cursor_pos
        
        -- Find which line the cursor is on right now - force recalculation
        local all_lines = self:SplitTextIntoLines(text_content)
        local position = 0
        local current_line_index = 1
        local current_line_start = 0
        local current_line_end = 0
        
        for i, line in ipairs(all_lines) do
            local line_start = position
            local line_end = position + #line
            
            -- If cursor is in this range, this is our line
            if cursor_position >= line_start and cursor_position <= line_end then
                current_line_index = i
                current_line_start = line_start
                current_line_end = line_end
                break
            end
            
            -- Special handling for newline character
            if i < #all_lines and cursor_position == line_end + 1 then
                current_line_index = i + 1  -- Next line
                current_line_start = line_end + 1
                current_line_end = line_end + 1 + #all_lines[i+1]
                break
            end
            
            position = line_end + 1  -- +1 for newline
        end
        
        -- Always go to end of current line
        new_pos = current_line_end
    elseif key == KEY_PAGEUP then
        -- First check if already at the first line
        if current_line == 1 then
            -- If already at the first line, just go to the beginning of the line
            new_pos = 0
        else
            -- Move cursor up 10 lines, preserving column position
            local target_line = math.max(1, current_line - 10)
            local current_column = cursor_pos - line_start
            
            -- Find the position in the target line
            local target_line_pos = 0
            for i = 1, target_line - 1 do
                if i <= #lines then
                    target_line_pos = target_line_pos + #lines[i] + 1
                end
            end
            
            -- Calculate new position with column clamping
            local target_line_text = lines[target_line] or ""
            local target_column = math.min(current_column, #target_line_text)
            new_pos = target_line_pos + target_column
        end
    elseif key == KEY_PAGEDOWN then
        -- First check if already at the last line
        if current_line == #lines then
            -- If already at the last line, just go to the end of the line
            new_pos = #text
        else
            -- Move cursor down 10 lines, preserving column position
            local target_line = math.min(#lines, current_line + 10)
            local current_column = cursor_pos - line_start
            
            -- Find the position in the target line
            local target_line_pos = 0
            for i = 1, target_line - 1 do
                if i <= #lines then
                    target_line_pos = target_line_pos + #lines[i] + 1
                end
            end
            
            -- Calculate new position with column clamping
            local target_line_text = lines[target_line] or ""
            local target_column = math.min(current_column, #target_line_text)
            new_pos = target_line_pos + target_column
        end
    else
        -- Not a cursor movement key
        return false
    end
    
    -- Do nothing if position hasn't changed
    if new_pos == cursor_pos then
        return true
    end
    
    -- Update cursor position safely
    if widget.SetEditCursorPos then
        widget:SetEditCursorPos(new_pos)
    elseif widget.inst and widget.inst.TextEditWidget then
        widget.inst.TextEditWidget:SetEditCursorPos(new_pos)
    end
    
    -- Update selection end if selecting
    if selecting then
        self.selection_end = new_pos
    end
    
    -- Notify editor to scroll if needed
    if self.editor and self.editor.ScrollToCursor then
        self.editor:ScrollToCursor()
    end
    
    return true
end

--[[
    Handles backspace key press.
    
    @param widget (TextEdit) The text widget
    @return (boolean) True if handled, false otherwise
]]
function EditorKeyHandler:HandleBackspace(widget)
    local current_text = widget:GetString()
    
    -- Safely get cursor position
    local cursor_pos = 0
    if widget.GetEditCursorPos then
        cursor_pos = widget:GetEditCursorPos()
    elseif widget.inst and widget.inst.TextEditWidget then
        cursor_pos = widget.inst.TextEditWidget:GetEditCursorPos()
    end
    
    -- Handle selection-based deletion if active
    if self.selection_active and self.selection_start ~= self.selection_end then
        local start_pos = math.min(self.selection_start, self.selection_end)
        local end_pos = math.max(self.selection_start, self.selection_end)
        
        local new_text = current_text:sub(1, start_pos) .. current_text:sub(end_pos + 1)
        widget:SetString(new_text)
        
        -- Safely set cursor position
        if widget.SetEditCursorPos then
            widget:SetEditCursorPos(start_pos)
        elseif widget.inst and widget.inst.TextEditWidget then
            widget.inst.TextEditWidget:SetEditCursorPos(start_pos)
        end
        
        -- Clear selection
        self.selection_active = false
        
        -- Notify editor to scroll if needed
        if self.editor and self.editor.ScrollToCursor then
            self.editor:ScrollToCursor()
        end
        return true
    end
    
    if cursor_pos > 0 then
        -- Delete char to the left of cursor
        local new_text = current_text:sub(1, cursor_pos - 1) .. current_text:sub(cursor_pos + 1)
        widget:SetString(new_text)
        
        -- Safely set cursor position
        if widget.SetEditCursorPos then
            widget:SetEditCursorPos(cursor_pos - 1)
        elseif widget.inst and widget.inst.TextEditWidget then
            widget.inst.TextEditWidget:SetEditCursorPos(cursor_pos - 1)
        end
        
        -- Notify editor to scroll if needed
        if self.editor and self.editor.ScrollToCursor then
            self.editor:ScrollToCursor()
        end
        return true
    end
    
    return false
end

--[[
    Handles enter key press for line breaks.
    
    @param widget (TextEdit) The text widget
    @return (boolean) Always returns true
]]
function EditorKeyHandler:HandleEnterKey(widget)
    local text = widget:GetString()
    
    -- Safely get cursor position
    local cursor_pos = 0
    if widget.GetEditCursorPos then
        cursor_pos = widget:GetEditCursorPos()
    elseif widget.inst and widget.inst.TextEditWidget then
        cursor_pos = widget.inst.TextEditWidget:GetEditCursorPos()
    end
    
    -- Handle selection-based deletion if active
    if self.selection_active and self.selection_start ~= self.selection_end then
        local start_pos = math.min(self.selection_start, self.selection_end)
        local end_pos = math.max(self.selection_start, self.selection_end)
        
        local new_text = text:sub(1, start_pos) .. "\n" .. text:sub(end_pos + 1)
        widget:SetString(new_text)
        
        -- Safely set cursor position
        if widget.SetEditCursorPos then
            widget:SetEditCursorPos(start_pos + 1)
        elseif widget.inst and widget.inst.TextEditWidget then
            widget.inst.TextEditWidget:SetEditCursorPos(start_pos + 1)
        end
        
        -- Clear selection
        self.selection_active = false
    else
        -- Insert a newline at cursor position
        local new_text = text:sub(1, cursor_pos) .. "\n" .. text:sub(cursor_pos + 1)
        widget:SetString(new_text)
        
        -- Safely set cursor position
        if widget.SetEditCursorPos then
            widget:SetEditCursorPos(cursor_pos + 1)
        elseif widget.inst and widget.inst.TextEditWidget then
            widget.inst.TextEditWidget:SetEditCursorPos(cursor_pos + 1)
        end
    end
    
    -- Maintain editing state
    widget:SetEditing(true)
    
    -- Notify editor to scroll if needed
    if self.editor and self.editor.ScrollToCursor then
        self.editor:ScrollToCursor()
    end
    
    return true
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
    local current_line = ""
    
    for i = 1, #text do
        local char = text:sub(i, i)
        if char == "\n" then
            table.insert(lines, current_line)
            current_line = ""
        else
            current_line = current_line .. char
        end
    end
    
    -- Add the last line
    table.insert(lines, current_line)
    
    return lines
end

--[[
    Gets information about the line containing the cursor.
    
    @param text (string) The full text
    @param cursor_pos (number) Current cursor position
    @param lines (table) Lines array from SplitTextIntoLines
    @return (number, number, number) Line number, line start position, line end position
]]
function EditorKeyHandler:GetCurrentLineInfo(text, cursor_pos, lines)
    -- If text is empty, return defaults
    if #lines == 0 or #text == 0 then
        return 1, 0, 0
    end
    
    local pos = 0
    
    -- Explicitly handle cursor at position 0
    if cursor_pos == 0 then
        return 1, 0, #lines[1]
    end
    
    for i = 1, #lines do
        local line_start = pos
        local line_end = pos + #lines[i]
        
        -- Check if cursor is in this line (inclusive of line_start, line_end)
        if cursor_pos >= line_start and cursor_pos <= line_end then
            return i, line_start, line_end
        end
        
        -- Check if cursor is at the newline after this line
        if i < #lines and cursor_pos == line_end + 1 then
            return i, line_start, line_end
        end
        
        -- Move to next line (add 1 for newline)
        pos = line_end + 1
    end
    
    -- Cursor is past the end of text - return last line
    return #lines, pos - #lines[#lines], pos - 1
end

--[[
    Gets cursor position for a specific line and column.
    
    @param text (string) The full text
    @param line_num (number) Target line number
    @param column (number) Target column in the line
    @param lines (table) Lines array from SplitTextIntoLines
    @return (number) Cursor position
]]
function EditorKeyHandler:GetPositionForLine(text, line_num, column, lines)
    -- Clamp line number
    line_num = math.max(1, math.min(#lines, line_num))
    
    local pos = 0
    
    -- Move position to start of target line
    for i = 1, line_num - 1 do
        if i <= #lines then -- Safety check
            pos = pos + #lines[i] + 1  -- +1 for newline
        end
    end
    
    -- Add column offset (clamped to line length)
    if line_num <= #lines then -- Safety check
        local target_line = lines[line_num]
        local target_column = math.min(column, #target_line)
        pos = pos + target_column
    end
    
    -- Clamp final position to text length
    return math.min(pos, #text)
end

return EditorKeyHandler