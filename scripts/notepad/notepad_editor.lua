--[[
    Notepad Editor Module for DST Quick Notes
    
    This module provides the core text editing functionality for the notepad.
    It wraps Don't Starve Together's TextEdit widget with additional features:
    - Focus management
    - Text manipulation methods
    - Scrolling support
    
    The editor handles text input and formatting while delegating
    key handling to EditorKeyHandler and text input processing to TextInputHandler.

    Usage:
        local NotepadEditor = require("notepad/notepad_editor")
        local editor = NotepadEditor(parent_widget, "buttonfont", 25)
        editor:SetText("Initial content")
]]

local TextEdit = require "widgets/textedit"
local Config = require "notepad/config"
local TextUtils = require "notepad/text_utils"
local EditorKeyHandler = require "notepad/editor_key_handler"
local TextInputHandler = require "notepad/text_input_handler"

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
    
    -- Initialize text utilities
    self.text_utils = TextUtils()
    
    -- Create the editor widget
    self.editor = self.parent:AddChild(TextEdit(font or DEFAULTFONT, font_size or Config.FONT_SIZES.EDITOR))
    
    -- Store font settings for text measurement
    self.editor.font = font or DEFAULTFONT
    self.editor.size = font_size or Config.FONT_SIZES.EDITOR
    
    -- Initialize specialized handlers
    self.key_handler = EditorKeyHandler(self)
    self.text_input_handler = TextInputHandler(self.text_utils)
    
    self:InitializeEditor()
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
    
    -- Set up text input handler for automatic line breaking
    function editor:OnTextInput(text)
        -- Store reference to the editor instance for easier access
        local editor_instance = self.parent.parent.editor
        
        -- Handle the text input using our specialized handler
        if editor_instance.text_input_handler:HandleTextInput(self, text, Config) then
            editor_instance:ScrollToCursor()
            return true
        end
        return false  -- Don't call base TextEdit.OnTextInput to prevent double input
    end
    
    -- Set up key handler for all keyboard input
    self.key_handler:SetupKeyHandler(editor)
    
    -- Initialize focus handling
    self:SetupFocusHandlers(editor)
end

--[[
    Sets up focus gain and loss handlers for the editor.
    Manages visual feedback when the editor gains or loses focus.
    
    @param editor (TextEdit) The editor widget to set up handlers for
]]
function NotepadEditor:SetupFocusHandlers(editor)
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
    -- Add to key handler's undo stack before changing text
    if self.key_handler then
        self.key_handler:PushToUndoStack(self:GetText())
    end
    self.editor:SetString(text or "")
end

--[[
    Sets keyboard focus to the editor.
]]
function NotepadEditor:SetFocus()
    self.editor:SetFocus()
end

--[[
    Scrolls the editor to ensure the cursor is visible.
    Called after text changes or cursor movement.
]]
function NotepadEditor:ScrollToCursor()
    local editor = self.editor
    if not editor or not editor.SetScroll then return end
    
    -- Get cursor position and editor dimensions
    local cursor_pos = editor.GetEditCursorPos and editor:GetEditCursorPos() or 0
    local text = editor:GetString() or ""
    local lines = self.text_utils:SplitByLine(text)
    
    -- Calculate cursor line
    local cursor_line = 1
    local pos = 0
    for i, line in ipairs(lines) do
        pos = pos + #line + 1  -- +1 for newline
        if pos > cursor_pos then
            cursor_line = i
            break
        end
    end
    
    -- Calculate scroll position
    local line_height = editor.size or 25  -- Use editor's font size for line height
    local visible_lines = Config.DIMENSIONS.EDITOR.HEIGHT / line_height
    local total_lines = #lines
    
    -- Ensure we don't divide by zero
    if total_lines < 1 then total_lines = 1 end
    
    -- Adjust scroll position to show more context below cursor
    local scroll_pos = math.max(0, math.min(1, (cursor_line - math.floor(visible_lines/3)) / total_lines))
    
    -- Apply scroll position with smooth animation
    editor:SetScroll(scroll_pos)
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

return NotepadEditor