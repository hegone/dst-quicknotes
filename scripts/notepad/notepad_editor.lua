-- scripts/notepad/notepad_editor.lua
--[[
    Notepad Editor Module for DST Quick Notes
    
    This module provides the core text editing functionality for the notepad.
    It wraps Don't Starve Together's TextEdit widget with additional features:
    - Focus management
    - Text manipulation methods
    - Scrolling support
    - Enhanced cursor navigation
    
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
local FocusManager = require "notepad/focus_manager"

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
    
    -- Store config reference
    self.editor.config = Config
    
    -- Add selection state to editor for cursor navigation
    self.editor.selection_active = false
    self.editor.selection_start = 0
    self.editor.selection_end = 0
    
    -- Initialize specialized handlers
    self.key_handler = EditorKeyHandler(self) -- Pass self (NotepadEditor instance)
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

    -- Set cursor color to white for better visibility
    if editor.SetEditCursorColour then
        editor:SetEditCursorColour(1, 1, 1, 1)  -- White color (RGBA)
    elseif editor.inst and editor.inst.TextWidget and editor.inst.TextWidget.SetEditCursorColour then
        editor.inst.TextWidget:SetEditCursorColour(1, 1, 1, 1)
    end

    editor:SetString("")
    editor.allow_newline = true
    
    -- Extend OnTextInput to handle selection and line breaking
    -- Need to ensure 'self' inside this function refers to the TextEdit widget,
    -- but we need access to the NotepadEditor instance's handlers.
    local notepad_editor_instance = self -- Capture the NotepadEditor instance
    function editor:OnTextInput(text)
        -- Handle the text input using our specialized handler from the NotepadEditor instance
        if notepad_editor_instance.text_input_handler:HandleTextInput(self, text, Config) then -- 'self' here is the TextEdit widget
            notepad_editor_instance:ScrollToCursor() -- Call ScrollToCursor on the NotepadEditor instance
            return true
        end
        return false  -- Don't call base TextEdit.OnTextInput to prevent double input
    end
    
    -- Set up paste handler using the TextInputHandler
    self.text_input_handler:SetupPasteHandler(editor)
    
    -- Set up key handler for all keyboard input
    self.key_handler:SetupKeyHandler(editor) -- Pass the TextEdit widget to the handler setup
    
    -- Add direct access to TextEditWidget if needed (though direct access is often discouraged)
    if editor.inst and editor.inst.TextEditWidget then
        editor.TextEditWidget = editor.inst.TextEditWidget
    end
    
    -- Initialize focus handling using the FocusManager
    FocusManager:SetupEditorFocusHandlers(editor, Config.COLORS.EDITOR_TEXT)
    
    -- Note: Call to self:SetupHighlighting() was removed as the function was non-functional and removed.
end

--[[ Text Manipulation Methods ]]--

--[[
    Gets the current text content of the editor.
    
    @return (string) The current editor content
]]
function NotepadEditor:GetText()
    -- Ensure editor exists before accessing GetString
    if not self.editor then return "" end
    return self.editor:GetString()
end

--[[
    Sets the text content of the editor.
    
    @param text (string) The new text content (optional, defaults to empty string)
]]
function NotepadEditor:SetText(text)
    -- Ensure editor exists before setting text
    if not self.editor then return end

    local safe_text = text or ""
    self.editor:SetString(safe_text)
    
    -- Ensure cursor is at end of text
    if self.editor.SetEditCursorPos then
        self.editor:SetEditCursorPos(#safe_text)
    elseif self.editor.inst and self.editor.inst.TextEditWidget then
         self.editor.inst.TextEditWidget:SetEditCursorPos(#safe_text)
    end
    -- Reset scroll after setting text
    self:ScrollToCursor() -- Scroll to end (or wherever cursor is now)
end

--[[
    Sets keyboard focus to the editor.
]]
function NotepadEditor:SetFocus()
    if self.editor then
        self.editor:SetFocus()
    end
end

--[[
    Scrolls the editor to ensure the cursor is visible.
    Called after text changes or cursor movement.
    Uses an improved algorithm similar to ConsoleScreen.
]]
function NotepadEditor:ScrollToCursor()
    local editor = self.editor
    -- Check if editor and necessary methods/properties exist
    if not editor or not editor.SetScroll or not editor.GetEditCursorPos or not editor.GetString then return end
    
    -- Get cursor position and editor dimensions
    local cursor_pos = editor:GetEditCursorPos()
    local text = editor:GetString() or ""
    -- Use text_utils instance for consistency. Ensure text_utils exists.
    if not self.text_utils then return end 
    local lines = self.text_utils:SplitByLine(text) 
    
    -- Calculate cursor line
    local cursor_line = 1
    local current_char_pos = 0
    for i = 1, #lines do
        local line_len = #lines[i]
        -- Check if cursor is within this line content or exactly at the newline after it
        if cursor_pos >= current_char_pos and cursor_pos <= current_char_pos + line_len then
             cursor_line = i
             break
        -- If cursor is exactly at newline, it belongs to the start of the next line
        elseif i < #lines and cursor_pos == current_char_pos + line_len + 1 then
             cursor_line = i + 1
             break
        end
        current_char_pos = current_char_pos + line_len + 1 -- +1 for newline
    end
    -- If loop finishes and cursor_line is still 1, check if it should be last line
    if cursor_line == 1 and #lines > 1 and cursor_pos > current_char_pos then
         cursor_line = #lines -- Cursor is past the end, associate with last line
    end

    
    -- Calculate scroll position - improved algorithm
    local line_height = editor.size or Config.FONT_SIZES.EDITOR -- Use editor's font size for line height approx.
    local editor_height = Config.DIMENSIONS.EDITOR.HEIGHT
    local visible_lines = math.max(1, math.floor(editor_height / line_height)) -- Ensure at least 1 visible line
    local total_lines = #lines
    
    -- Ensure we don't divide by zero or have negative scroll range
    local scrollable_lines = math.max(0, total_lines - visible_lines)
    if scrollable_lines <= 0 then
        editor:SetScroll(0) -- No scrolling needed if all lines fit
        return
    end

    -- Determine the desired top visible line to keep cursor in view
    -- Attempt to get current scroll position if possible, otherwise assume 0
    local current_scroll_fraction = 0 
    if editor.GetScroll then -- Check if GetScroll exists
        current_scroll_fraction = editor:GetScroll()
    elseif editor.scroll_pos then -- Fallback to stored value if GetScroll doesn't exist
        current_scroll_fraction = editor.scroll_pos
    end
    
    local current_top_line = math.floor(current_scroll_fraction * scrollable_lines) + 1

    local new_top_line = current_top_line

    -- If cursor moved above the visible area
    if cursor_line < current_top_line then
        new_top_line = cursor_line
    -- If cursor moved below the visible area
    elseif cursor_line >= current_top_line + visible_lines then
        new_top_line = cursor_line - visible_lines + 1
    end

    -- Clamp the new top line
    new_top_line = math.max(1, math.min(new_top_line, total_lines - visible_lines + 1))

    -- Calculate final scroll position (fraction 0 to 1)
    local scroll_pos = (new_top_line - 1) / scrollable_lines
    scroll_pos = math.max(0, math.min(1, scroll_pos)) -- Clamp final value

    -- Apply scroll position (SetScroll expects fraction 0-1)
    editor:SetScroll(scroll_pos)
    editor.scroll_pos = scroll_pos -- Store it again, maybe useful if GetScroll doesn't exist
end

--[[
    Cleans up the editor widget and its components.
    Should be called when the notepad is being destroyed.
]]
function NotepadEditor:Kill()
    -- Clean up editor widget itself
    if self.editor then
        self.editor:Kill()
        self.editor = nil
    end
    
    -- Clean up utility instances
    if self.text_utils then
        self.text_utils:Kill()
        self.text_utils = nil
    end

    -- Nil out references to handlers (they don't have explicit Kill methods usually)
    self.key_handler = nil
    self.text_input_handler = nil
    self.parent = nil -- Break cycle if parent holds reference back
end

return NotepadEditor