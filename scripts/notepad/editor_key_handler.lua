--[[
    Editor Key Handler Module for DST Quick Notes
    
    This module handles keyboard input and mouse interactions for the notepad editor.
    It manages special key combinations, cursor movement, text editing operations,
    and cursor placement via mouse clicks.
    
    Usage:
        local EditorKeyHandler = require "notepad/editor_key_handler"
        local handler = EditorKeyHandler(editor)
        handler:SetupKeyHandler(editor.editor)
]]

local TextEdit = require "widgets/textedit"
local Config = require "notepad/config"

--[[
    EditorKeyHandler Class
    
    Manages keyboard input and mouse interactions for the notepad editor, providing custom
    key handling for special keys and operations.
    
    @param editor (NotepadEditor) The editor instance this handler works with
]]
local EditorKeyHandler = Class(function(self, editor)
    self.editor = editor
    
    -- Initialize undo/redo stacks
    self.undo_stack = {}
    self.redo_stack = {}
end)

--[[
    Sets up the OnRawKey handler for a TextEdit widget.
    
    @param text_edit (TextEdit) The text edit widget to set up
]]
function EditorKeyHandler:SetupKeyHandler(text_edit)
    -- Verify we have a valid TextEdit widget
    if not text_edit or not text_edit.GetString then
        print("[Quick Notes] Error: Invalid TextEdit widget in SetupKeyHandler")
        return
    end

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
end

--[[
    Handles mouse clicks within the text editor area to position the cursor.
    
    @param widget (TextEdit) The text widget 
    @param x (number) Screen X coordinate of the click
    @param y (number) Screen Y coordinate of the click
    @return (boolean) True if the click was handled, false otherwise
]]
function EditorKeyHandler:HandleMouseClick(widget, x, y)
    -- Safety checks
    if not widget or not widget.GetString or not widget.SetEditCursorPos then
        print("[Quick Notes] Error: Widget missing required methods")
        return false
    end
    
    -- Check if editor instance is available
    if not self.editor or not self.editor.text_utils then
        print("[Quick Notes] Error: Missing editor or text_utils")
        return false
    end
    
    local text = widget:GetString() or ""
    if text == "" then
        -- If text is empty, just set cursor at start and focus
        widget:SetEditCursorPos(0)
        return true
    end
    
    -- Get widget dimensions
    local width, height = widget:GetRegionSize()
    local half_width = width / 2
    local half_height = height / 2
    
    -- Get editor text and split into lines
    local lines = self.editor.text_utils:SplitByLine(text)
    if #lines == 0 then
        return false
    end
    
    -- Convert screen coordinates to local widget coordinates
    -- Get widget's world position
    local widget_pos = widget:GetWorldPosition()
    local local_x = x - widget_pos.x
    local local_y = y - widget_pos.y
    
    print("[Quick Notes] Mouse click at:", x, y, "Local:", local_x, local_y)
    
    -- Check if click is within widget bounds
    if math.abs(local_x) > half_width or math.abs(local_y) > half_height then
        print("[Quick Notes] Click outside editor bounds")
        return false
    end
    
    -- Adjust y coordinate to be relative to top of widget (0,0 is center)
    local adjusted_y = half_height - local_y  -- Invert Y since 0,0 is at center
    
    -- Determine line height based on font size
    local line_height = widget.size or 25
    
    -- Get current scroll position (0-1)
    local scroll_pos = 0
    if widget.GetScroll then
        scroll_pos = widget:GetScroll()
    end
    
    -- Calculate total content height
    local total_content_height = #lines * line_height
    local visible_height = height
    
    -- Determine visible range based on scroll position
    local scroll_offset = scroll_pos * (total_content_height - visible_height)
    if scroll_offset < 0 then scroll_offset = 0 end
    
    -- Convert click position to line index
    local clicked_y_pos = adjusted_y + scroll_offset
    local clicked_line_idx = math.floor(clicked_y_pos / line_height) + 1
    
    -- Clamp to valid line range
    if clicked_line_idx < 1 then clicked_line_idx = 1 end
    if clicked_line_idx > #lines then clicked_line_idx = #lines end
    
    -- Get the line text
    local line_text = lines[clicked_line_idx]
    
    -- Convert horizontal click position to character index
    local x_offset = local_x + half_width   -- Adjust to make 0 at the left edge
    
    -- Simple approach: estimate character based on average character width
    local avg_char_width = self.editor.text_utils:CalculateTextWidth("m", widget.font, widget.size) or 10
    local cursor_pos_in_line = math.floor(x_offset / avg_char_width)
    
    -- Clamp to line length
    if cursor_pos_in_line < 0 then cursor_pos_in_line = 0 end
    if cursor_pos_in_line > #line_text then cursor_pos_in_line = #line_text end
    
    -- Now calculate the absolute cursor position in the full text
    local absolute_cursor_pos = 0
    for i = 1, clicked_line_idx - 1 do
        absolute_cursor_pos = absolute_cursor_pos + #lines[i] + 1  -- +1 for newline
    end
    absolute_cursor_pos = absolute_cursor_pos + cursor_pos_in_line
    
    -- Set the cursor position with proper error handling
    pcall(function()
        widget:SetEditCursorPos(absolute_cursor_pos)
    end)
    
    -- Notify editor to scroll if needed
    if self.editor.ScrollToCursor then
        self.editor:ScrollToCursor()
    end
    
    -- Print debug info
    print("[Quick Notes] Cursor positioned at line", clicked_line_idx, "position", cursor_pos_in_line, "absolute", absolute_cursor_pos)
    
    return true
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
    -- Safety check
    if not widget then
        return nil
    end
    
    -- Handle ESC key to prevent text input
    if key == KEY_ESCAPE and down then
        -- Let the parent widget handle the ESC key for closing
        if widget.parent and widget.parent.parent and widget.parent.parent.Close then
            widget.parent.parent:Close()
        end
        return true
    end
    
    -- Handle backspace explicitly
    if key == KEY_BACKSPACE and down then
        return self:HandleBackspace(widget)
    end
    
    -- Handle Enter key for line breaks
    if down and (key == KEY_ENTER or key == KEY_KP_ENTER) then
        return self:HandleEnterKey(widget)
    end
    
    -- Handle Home/End keys
    if down and key == KEY_HOME then
        return self:HandleHomeKey(widget)
    end
    
    if down and key == KEY_END then
        return self:HandleEndKey(widget)
    end
    
    -- Handle Page Up/Down keys
    if down and key == KEY_PAGEUP then
        return self:HandlePageUpKey(widget)
    end
    
    if down and key == KEY_PAGEDOWN then
        return self:HandlePageDownKey(widget)
    end
    
    -- Handle undo/redo shortcuts
    if down and key == KEY_Z and TheInput:IsKeyDown(KEY_CTRL) then
        if TheInput:IsKeyDown(KEY_SHIFT) then
            self:Redo()
        else
            self:Undo()
        end
        return true
    end
    
    -- Let original handler process other keys
    return nil
end

--[[
    Handles backspace key press.
    
    @param widget (TextEdit) The text widget
    @return (boolean) True if handled, false otherwise
]]
function EditorKeyHandler:HandleBackspace(widget)
    if not widget or not widget.GetString or not widget.SetString or not widget.GetEditCursorPos then
        return false
    end
    
    local current_text = widget:GetString()
    local cursor_pos = widget:GetEditCursorPos()
    
    if cursor_pos > 0 then
        -- Delete char to the left of cursor
        local new_text = current_text:sub(1, cursor_pos - 1) .. current_text:sub(cursor_pos + 1)
        widget:SetString(new_text)
        widget:SetEditCursorPos(cursor_pos - 1)
        
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
    if not widget or not widget.GetString or not widget.SetString or not widget.GetEditCursorPos then
        return false
    end
    
    local text = widget:GetString()
    local cursor_pos = widget:GetEditCursorPos()
    
    -- Insert a newline at cursor position
    local new_text = text:sub(1, cursor_pos) .. "\n" .. text:sub(cursor_pos + 1)
    widget:SetString(new_text)
    widget:SetEditing(true)
    widget:SetEditCursorPos(cursor_pos + 1)
    
    -- Notify editor to scroll if needed
    if self.editor and self.editor.ScrollToCursor then
        self.editor:ScrollToCursor()
    end
    
    return true
end

--[[
    Handles Home key to move cursor to start of line.
    
    @param widget (TextEdit) The text widget
    @return (boolean) Always returns true
]]
function EditorKeyHandler:HandleHomeKey(widget)
    if not widget or not widget.GetString or not widget.SetEditCursorPos then
        return false
    end
    
    local text = widget:GetString()
    local cursor_pos = widget:GetEditCursorPos()
    
    -- Find start of current line
    local line_start = cursor_pos
    while line_start > 0 and text:sub(line_start, line_start) ~= "\n" do
        line_start = line_start - 1
    end
    
    -- If we found a newline, move to the character after it
    if text:sub(line_start, line_start) == "\n" then
        line_start = line_start + 1
    end
    
    widget:SetEditCursorPos(line_start)
    
    -- Notify editor to scroll if needed
    if self.editor and self.editor.ScrollToCursor then
        self.editor:ScrollToCursor()
    end
    
    return true
end

--[[
    Handles End key to move cursor to end of line.
    
    @param widget (TextEdit) The text widget
    @return (boolean) Always returns true
]]
function EditorKeyHandler:HandleEndKey(widget)
    if not widget or not widget.GetString or not widget.SetEditCursorPos then
        return false
    end
    
    local text = widget:GetString()
    local cursor_pos = widget:GetEditCursorPos()
    
    -- Find end of current line
    local line_end = cursor_pos
    while line_end < #text and text:sub(line_end + 1, line_end + 1) ~= "\n" do
        line_end = line_end + 1
    end
    
    widget:SetEditCursorPos(line_end)
    
    -- Notify editor to scroll if needed
    if self.editor and self.editor.ScrollToCursor then
        self.editor:ScrollToCursor()
    end
    
    return true
end

--[[
    Handles Page Up key to scroll up multiple lines.
    
    @param widget (TextEdit) The text widget
    @return (boolean) Always returns true
]]
function EditorKeyHandler:HandlePageUpKey(widget)
    if not widget or not widget.GetString or not widget.SetEditCursorPos then
        return false
    end
    
    local text = widget:GetString()
    local cursor_pos = widget:GetEditCursorPos()
    
    -- Count back 10 lines, or to the beginning
    local target_pos = cursor_pos
    local lines_to_move = 10
    
    while lines_to_move > 0 and target_pos > 0 do
        target_pos = target_pos - 1
        if target_pos > 0 and text:sub(target_pos, target_pos) == "\n" then
            lines_to_move = lines_to_move - 1
        end
    end
    
    widget:SetEditCursorPos(target_pos)
    
    -- Notify editor to scroll
    if self.editor and self.editor.ScrollToCursor then
        self.editor:ScrollToCursor()
    end
    
    return true
end

--[[
    Handles Page Down key to scroll down multiple lines.
    
    @param widget (TextEdit) The text widget
    @return (boolean) Always returns true
]]
function EditorKeyHandler:HandlePageDownKey(widget)
    if not widget or not widget.GetString or not widget.SetEditCursorPos then
        return false
    end
    
    local text = widget:GetString()
    local cursor_pos = widget:GetEditCursorPos()
    
    -- Count forward 10 lines, or to the end
    local target_pos = cursor_pos
    local lines_to_move = 10
    
    while lines_to_move > 0 and target_pos < #text do
        target_pos = target_pos + 1
        if target_pos < #text and text:sub(target_pos, target_pos) == "\n" then
            lines_to_move = lines_to_move - 1
        end
    end
    
    widget:SetEditCursorPos(target_pos)
    
    -- Notify editor to scroll
    if self.editor and self.editor.ScrollToCursor then
        self.editor:ScrollToCursor()
    end
    
    return true
end

--[[ Undo/Redo Implementation ]]--

--[[
    Pushes text to the undo stack and clears redo stack.
    
    @param text (string) Text state to save for undoing
]]
function EditorKeyHandler:PushToUndoStack(text)
    table.insert(self.undo_stack, text)
    -- Clear redo stack when new changes are made
    self.redo_stack = {}
end

--[[
    Undoes the last text change if available.
    Moves current state to redo stack.
]]
function EditorKeyHandler:Undo()
    if #self.undo_stack > 0 and self.editor and self.editor.GetText and self.editor.SetText then
        -- Push current text to redo stack
        table.insert(self.redo_stack, self.editor:GetText())
        -- Pop and apply text from undo stack
        local text = table.remove(self.undo_stack)
        self.editor:SetText(text)
    end
end

--[[
    Redoes the last undone change if available.
    Moves current state to undo stack.
]]
function EditorKeyHandler:Redo()
    if #self.redo_stack > 0 and self.editor and self.editor.GetText and self.editor.SetText then
        -- Push current text to undo stack
        table.insert(self.undo_stack, self.editor:GetText())
        -- Pop and apply text from redo stack
        local text = table.remove(self.redo_stack)
        self.editor:SetText(text)
    end
end

return EditorKeyHandler