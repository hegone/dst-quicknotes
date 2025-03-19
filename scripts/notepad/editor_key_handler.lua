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
    
    -- Initialize undo/redo stacks
    self.undo_stack = {}
    self.redo_stack = {}
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
    
    -- Handle backspace explicitly
    if key == KEY_BACKSPACE and down then
        return self:HandleBackspace(widget)
    end
    
    -- Handle Enter key for line breaks
    if down and (key == KEY_ENTER or key == KEY_KP_ENTER) then
        return self:HandleEnterKey(widget)
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
    local current_text = widget:GetString()
    local cursor_pos = widget:GetEditCursorPos()
    
    if cursor_pos > 0 then
        -- Delete char to the left of cursor
        local new_text = current_text:sub(1, cursor_pos - 1) .. current_text:sub(cursor_pos + 1)
        widget:SetString(new_text)
        widget:SetEditCursorPos(cursor_pos - 1)
        
        -- Notify editor to scroll if needed
        if self.editor.ScrollToCursor then
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
    local cursor_pos = widget:GetEditCursorPos()
    
    -- Insert a newline at cursor position
    local new_text = text:sub(1, cursor_pos) .. "\n" .. text:sub(cursor_pos + 1)
    widget:SetString(new_text)
    widget:SetEditing(true)
    widget:SetEditCursorPos(cursor_pos + 1)
    
    -- Notify editor to scroll if needed
    if self.editor.ScrollToCursor then
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
    if #self.undo_stack > 0 then
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
    if #self.redo_stack > 0 then
        -- Push current text to undo stack
        table.insert(self.undo_stack, self.editor:GetText())
        -- Pop and apply text from redo stack
        local text = table.remove(self.redo_stack)
        self.editor:SetText(text)
    end
end

return EditorKeyHandler