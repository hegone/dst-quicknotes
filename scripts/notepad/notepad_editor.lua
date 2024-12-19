--[[
    Notepad Editor Module for DST Quick Notes
    
    This module provides the core text editing functionality for the notepad.
    It wraps Don't Starve Together's TextEdit widget with additional features:
    - Custom key handling (Enter for new lines)
    - Text manipulation methods
    - Focus management
    - Future undo/redo support (structure in place)
    
    The editor handles all text input and formatting, while delegating
    storage operations to the parent widget.

    Usage:
        local NotepadEditor = require("notepad/notepad_editor")
        local editor = NotepadEditor(parent_widget, "buttonfont", 25)
        editor:SetText("Initial content")
]]

local TextEdit = require "widgets/textedit"
local Config = require "notepad/config"

--[[
    NotepadEditor Class
    
    Manages the text editing component of the notepad, providing a rich
    text editing experience while maintaining compatibility with DST's
    widget system.

    @param parent (Widget) Parent widget to attach the editor to
    @param font (string) Font to use for the editor (optional, defaults to DEFAULTFONT)
    @param font_size (number) Font size to use (optional, defaults from config)
]]
local NotepadEditor = Class(function(self, parent, font, font_size)
    -- Store parent widget for adding children
    self.parent = parent
    
    -- Initialize text editor widget with configured or default settings
    self.editor = parent:AddChild(TextEdit(font or DEFAULTFONT, font_size or Config.FONT_SIZES.EDITOR))
    self:InitializeEditor()
    
    -- Initialize undo/redo stacks for future implementation
    self.undo_stack = {}
    self.redo_stack = {}
end)

--[[
    Initializes the editor widget with all necessary properties and handlers.
    Sets up the visual appearance, behavior, and event handlers.
]]
function NotepadEditor:InitializeEditor()
    local editor = self.editor
    
    -- Configure editor appearance and behavior
    editor:SetPosition(0, 0)
    editor:SetRegionSize(Config.DIMENSIONS.EDITOR.WIDTH, Config.DIMENSIONS.EDITOR.HEIGHT)
    editor:SetHAlign(ANCHOR_LEFT)
    editor:SetVAlign(ANCHOR_TOP)
    editor:EnableScrollEditWindow(true)
    editor:EnableWordWrap(true)
    editor:SetTextLengthLimit(Config.SETTINGS.TEXT_LENGTH_LIMIT)
    editor:SetColour(
        Config.COLORS.EDITOR_TEXT.r,
        Config.COLORS.EDITOR_TEXT.g,
        Config.COLORS.EDITOR_TEXT.b,
        Config.COLORS.EDITOR_TEXT.a
    )
    editor:SetString("")
    editor.allow_newline = true
    
    -- Set up raw key handler for enter key and future key commands
    function editor:OnRawKey(key, down)
        -- Get the editor instance from parent's reference
        local editor_instance = self.parent.parent.editor
        if editor_instance and editor_instance:HandleKeyCommand(key, down) then
            return true
        end
        return TextEdit.OnRawKey(self, key, down)
    end
    
    -- Initialize focus handling
    self:SetupFocusHandlers()
end

--[[
    Handles special key commands for the editor.
    
    @param key (number) The key code being pressed
    @param down (boolean) Whether the key is being pressed down
    @return (boolean) True if the key was handled, false otherwise
]]
function NotepadEditor:HandleKeyCommand(key, down)
    -- Handle Enter key for line breaks
    if down and (key == KEY_ENTER or key == KEY_KP_ENTER) then
        local text = self:GetText()
        self:SetText(text .. "\n")
        self.editor:SetEditing(true)
        return true
    end
    
    -- Future key command handling (e.g., Ctrl+Z for undo)
    -- if down and key == KEY_Z and TheInput:IsKeyDown(KEY_CTRL) then
    --     self:Undo()
    --     return true
    -- end
    
    return false
end

--[[
    Sets up focus gain and loss handlers for the editor.
    Manages visual feedback when the editor gains or loses focus.
]]
function NotepadEditor:SetupFocusHandlers()
    local editor = self.editor
    
    function editor:OnGainFocus()
        TextEdit.OnGainFocus(self)
        self:SetEditing(true)
        self:SetColour(1, 1, 1, 1)
    end
    
    function editor:OnLoseFocus()
        TextEdit.OnLoseFocus(self)
        self:SetColour(1, 1, 1, 1)
    end
end

--[[ Text Manipulation Methods ]]--

--[[
    Gets the current text content of the editor.
    
    @return (string) The current editor content
]]
function NotepadEditor:GetText()
    return self.editor:GetString()
end

--[[
    Sets the text content of the editor.
    
    @param text (string) The new text content (optional, defaults to empty string)
]]
function NotepadEditor:SetText(text)
    -- Future: Add to undo stack before changing text
    -- self:PushToUndoStack(self:GetText())
    self.editor:SetString(text or "")
end

--[[
    Sets keyboard focus to the editor.
]]
function NotepadEditor:SetFocus()
    self.editor:SetFocus()
end

--[[
    Cleans up the editor widget.
    Should be called when the notepad is being destroyed.
]]
function NotepadEditor:Kill()
    if self.editor then
        self.editor:Kill()
        self.editor = nil
    end
end

--[[ Future Undo/Redo Implementation ]]--

--[[
    Pushes text to the undo stack and clears redo stack.
    
    @param text (string) Text state to save for undoing
]]
function NotepadEditor:PushToUndoStack(text)
    table.insert(self.undo_stack, text)
    -- Clear redo stack when new changes are made
    self.redo_stack = {}
end

--[[
    Undoes the last text change if available.
    Moves current state to redo stack.
]]
function NotepadEditor:Undo()
    if #self.undo_stack > 0 then
        -- Push current text to redo stack
        table.insert(self.redo_stack, self:GetText())
        -- Pop and apply text from undo stack
        local text = table.remove(self.undo_stack)
        self.editor:SetString(text)
    end
end

--[[
    Redoes the last undone change if available.
    Moves current state to undo stack.
]]
function NotepadEditor:Redo()
    if #self.redo_stack > 0 then
        -- Push current text to undo stack
        table.insert(self.undo_stack, self:GetText())
        -- Pop and apply text from redo stack
        local text = table.remove(self.redo_stack)
        self.editor:SetString(text)
    end
end

return NotepadEditor