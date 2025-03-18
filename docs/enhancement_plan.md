# QuickNotes Enhancement Plan

## Overview

This document outlines the planned enhancements for the "QuickNotes" Don't Starve Together mod. The enhancements are organized into multiple phases, focusing first on critical navigation and scrolling improvements, then adding richer text editing features, followed by advanced functionality.

## Phase 1: Core Navigation and Scrolling Improvements

### 1.1 Arrow Key Navigation
**Priority:** High  
**Complexity:** Medium  
**Files to Modify:** `scripts/notepad/editor_key_handler.lua`

Currently, the mod supports basic navigation via Home/End/PageUp/PageDown keys, but lacks proper arrow key support. This enhancement will implement full arrow key navigation including:

- Left/Right arrow keys to move cursor horizontally
- Up/Down arrow keys to navigate between lines
- Shift+Arrow keys for text selection (Phase 2)
- Ctrl+Arrow keys for word-by-word navigation

**Implementation Details:**
```lua
function EditorKeyHandler:ProcessKey(widget, key, down)
    -- Existing code...
    
    -- Handle arrow keys
    if down and key == KEY_LEFT then
        return self:HandleLeftKey(widget)
    end
    
    if down and key == KEY_RIGHT then
        return self:HandleRightKey(widget)
    end
    
    if down and key == KEY_UP then
        return self:HandleUpKey(widget)
    end
    
    if down and key == KEY_DOWN then
        return self:HandleDownKey(widget)
    end
    
    -- Rest of existing code...
end

function EditorKeyHandler:HandleLeftKey(widget)
    local cursor_pos = widget:GetEditCursorPos()
    if cursor_pos > 0 then
        widget:SetEditCursorPos(cursor_pos - 1)
        self.editor:ScrollToCursor()
        return true
    end
    return false
end

function EditorKeyHandler:HandleRightKey(widget)
    local cursor_pos = widget:GetEditCursorPos()
    local text = widget:GetString()
    if cursor_pos < #text then
        widget:SetEditCursorPos(cursor_pos + 1)
        self.editor:ScrollToCursor()
        return true
    end
    return false
end

function EditorKeyHandler:HandleUpKey(widget)
    local text = widget:GetString()
    local cursor_pos = widget:GetEditCursorPos()
    
    -- Find current line start
    local line_start = cursor_pos
    while line_start > 0 and text:sub(line_start, line_start) ~= "\n" do
        line_start = line_start - 1
    end
    
    -- If we found a newline, move to the character after it
    if text:sub(line_start, line_start) == "\n" then
        line_start = line_start + 1
    end
    
    -- Current column position
    local column = cursor_pos - line_start
    
    -- Find previous line start
    local prev_line_start = line_start - 2
    while prev_line_start > 0 and text:sub(prev_line_start, prev_line_start) ~= "\n" do
        prev_line_start = prev_line_start - 1
    end
    
    if prev_line_start < 0 then
        prev_line_start = 0
    elseif text:sub(prev_line_start, prev_line_start) == "\n" then
        prev_line_start = prev_line_start + 1
    end
    
    -- Find previous line end
    local prev_line_end = line_start - 2
    
    -- Calculate new cursor position
    local new_pos = prev_line_start + math.min(column, prev_line_end - prev_line_start + 1)
    widget:SetEditCursorPos(new_pos)
    self.editor:ScrollToCursor()
    return true
end

function EditorKeyHandler:HandleDownKey(widget)
    local text = widget:GetString()
    local cursor_pos = widget:GetEditCursorPos()
    
    -- Implementation details would mirror HandleUpKey, but for downward movement
    -- ...
    
    return true
end
```

### 1.2 Improved Cursor Scrolling
**Priority:** High  
**Complexity:** Medium  
**Files to Modify:** `scripts/notepad/notepad_editor.lua`

The current implementation has basic scrolling but needs improvement to ensure the cursor is always visible and to provide a better UX when navigating through large documents.

**Implementation Details:**
```lua
function NotepadEditor:ScrollToCursor()
    local editor = self.editor
    if not editor or not editor.SetScroll then return end
    
    -- Get cursor position and text content
    local cursor_pos = editor:GetEditCursorPos() or 0
    local text = editor:GetString() or ""
    local lines = self.text_utils:SplitByLine(text)
    
    -- Calculate cursor line and position
    local cursor_line = 1
    local pos = 0
    local chars_processed = 0
    
    for i, line in ipairs(lines) do
        if cursor_pos >= chars_processed and cursor_pos <= chars_processed + #line then
            cursor_line = i
            break
        end
        chars_processed = chars_processed + #line + 1  -- +1 for newline
    end
    
    -- Calculate scroll position to keep cursor visible
    local line_height = editor.size or 25
    local visible_lines = Config.DIMENSIONS.EDITOR.HEIGHT / line_height
    local total_lines = math.max(#lines, 1)
    
    -- Keep cursor in middle of visible area when possible
    local scroll_pos = math.max(0, math.min(1, (cursor_line - visible_lines/2) / total_lines))
    
    -- Apply scroll position with smooth animation
    editor:SetScroll(scroll_pos)
end
```

### 1.3 Visual Scrollbar
**Priority:** Medium  
**Complexity:** High  
**Files to Modify:** `scripts/widgets/notepad_ui.lua`, `scripts/notepad/notepad_editor.lua`

Add a visual scrollbar to provide feedback on document length and current position, as well as to allow manual scrolling.

**Implementation Details:**
```lua
function NotepadUI:InitializeScrollbar()
    -- Create scrollbar background
    self.parent.scrollbar_bg = self.parent.root:AddChild(Image("images/global.xml", "square.tex"))
    self.parent.scrollbar_bg:SetSize(10, Config.DIMENSIONS.EDITOR.HEIGHT)
    self.parent.scrollbar_bg:SetPosition(Config.DIMENSIONS.EDITOR.WIDTH/2 + 15, 0)
    self.parent.scrollbar_bg:SetTint(0.2, 0.2, 0.2, 0.5)
    
    -- Create scrollbar handle
    self.parent.scrollbar = self.parent.root:AddChild(ImageButton("images/global.xml", "square.tex"))
    self.parent.scrollbar:SetSize(8, 50)  -- Initial size, will adjust based on content
    self.parent.scrollbar:SetPosition(Config.DIMENSIONS.EDITOR.WIDTH/2 + 15, 0)
    self.parent.scrollbar:SetTint(0.6, 0.6, 0.6, 0.8)
    
    -- Handle scrollbar dragging
    self.parent.scrollbar:SetOnClick(function() end)  -- Prevent default click behavior
    
    function self.parent.scrollbar:OnMouseButton(button, down, x, y)
        if button == MOUSEBUTTON_LEFT then
            if down then
                self.dragging = true
                self.drag_start_y = y
                self.drag_start_pos = self:GetPosition()
                return true
            else
                self.dragging = false
                return true
            end
        end
        return false
    end
    
    function self.parent.scrollbar:OnUpdate()
        if self.dragging and TheInput:IsMouseDown(MOUSEBUTTON_LEFT) then
            local mouse_pos = TheInput:GetScreenPosition()
            local delta_y = mouse_pos.y - self.drag_start_y
            
            -- Calculate scrollbar boundaries
            local sb_bg = self.parent.scrollbar_bg
            local bg_pos = sb_bg:GetPosition()
            local bg_height = select(2, sb_bg:GetSize())
            local handle_height = select(2, self:GetSize())
            
            local min_y = bg_pos.y - (bg_height/2) + (handle_height/2)
            local max_y = bg_pos.y + (bg_height/2) - (handle_height/2)
            
            -- Set new position
            local new_y = math.clamp(self.drag_start_pos.y + delta_y, min_y, max_y)
            self:SetPosition(self.drag_start_pos.x, new_y)
            
            -- Calculate and set scroll percentage
            local scroll_pct = 1 - ((new_y - min_y) / (max_y - min_y))
            if self.parent.editor and self.parent.editor.editor then
                self.parent.editor.editor:SetScroll(scroll_pct)
            end
        end
    end
    
    -- Add scroll update function to NotepadEditor
    function self.parent.UpdateScrollbarFromEditor()
        local editor = self.parent.editor.editor
        if not editor or not self.parent.scrollbar then return end
        
        local scroll_pct = editor:GetScroll() or 0
        local sb_bg = self.parent.scrollbar_bg
        local bg_pos = sb_bg:GetPosition()
        local bg_height = select(2, sb_bg:GetSize())
        local handle_height = select(2, self.parent.scrollbar:GetSize())
        
        local min_y = bg_pos.y - (bg_height/2) + (handle_height/2)
        local max_y = bg_pos.y + (bg_height/2) - (handle_height/2)
        
        local y_pos = min_y + ((1 - scroll_pct) * (max_y - min_y))
        self.parent.scrollbar:SetPosition(self.parent.scrollbar:GetPosition().x, y_pos)
        
        -- Update handle size based on content
        local text = editor:GetString() or ""
        local lines = self.parent.editor.text_utils:SplitByLine(text)
        local line_height = editor.size or 25
        local visible_lines = Config.DIMENSIONS.EDITOR.HEIGHT / line_height
        local total_lines = math.max(#lines, 1)
        
        local handle_size = math.max(20, (visible_lines / total_lines) * bg_height)
        self.parent.scrollbar:SetSize(8, handle_size)
    end
    
    -- Modify existing ScrollToCursor function to update scrollbar position
    local original_scroll_fn = self.parent.editor.ScrollToCursor
    self.parent.editor.ScrollToCursor = function(editor)
        original_scroll_fn(editor)
        self.parent.UpdateScrollbarFromEditor()
    end
end
```

### 1.4 Mouse Wheel Scrolling
**Priority:** Medium  
**Complexity:** Low  
**Files to Modify:** `scripts/notepad/input_handler.lua`

Add support for mouse wheel scrolling to provide an alternative method for navigating the document.

**Implementation Details:**
```lua
function InputHandler:AddMouseWheelHandlers()
    -- Set up mouse wheel handlers in OnBecomeActive
    self.wheel_forward_handler = TheInput:AddMouseWheelHandler(function(up)
        if up and self.widget:IsOpen() then
            if self.widget.editor and self.widget.editor.editor then
                local editor = self.widget.editor.editor
                local current_scroll = editor:GetScroll() or 0
                local new_scroll = math.max(0, current_scroll - 0.05)
                editor:SetScroll(new_scroll)
                
                -- Update scrollbar if it exists
                if self.widget.UpdateScrollbarFromEditor then
                    self.widget:UpdateScrollbarFromEditor()
                end
                
                return true
            end
        end
        return false
    end, true)  -- true = wheel forward/up

    self.wheel_back_handler = TheInput:AddMouseWheelHandler(function(up)
        if up and self.widget:IsOpen() then
            if self.widget.editor and self.widget.editor.editor then
                local editor = self.widget.editor.editor
                local current_scroll = editor:GetScroll() or 0
                local new_scroll = math.min(1, current_scroll + 0.05)
                editor:SetScroll(new_scroll)
                
                -- Update scrollbar if it exists
                if self.widget.UpdateScrollbarFromEditor then
                    self.widget:UpdateScrollbarFromEditor()
                end
                
                return true
            end
        end
        return false
    end, false)  -- false = wheel back/down
end

function InputHandler:RemoveMouseWheelHandlers()
    if self.wheel_forward_handler then
        self.wheel_forward_handler:Remove()
        self.wheel_forward_handler = nil
    end
    
    if self.wheel_back_handler then
        self.wheel_back_handler:Remove()
        self.wheel_back_handler = nil
    end
end
```

## Phase 2: Enhanced Text Editing

### 2.1 Text Selection
**Priority:** Medium  
**Complexity:** High  
**Files to Modify:** `scripts/notepad/editor_key_handler.lua`, `scripts/notepad/notepad_editor.lua`

Implement text selection functionality with both keyboard (Shift+Arrow) and mouse input, providing visual highlighting for selected text.

**Key Features:**
- Implement selection start/end tracking
- Add Shift+Arrow key handlers for keyboard selection
- Add mouse drag selection
- Implement visual highlighting for selected text
- Modify text input handling to replace selected text when typing

### 2.2 Clipboard Operations
**Priority:** Medium  
**Complexity:** Medium  
**Files to Modify:** `scripts/notepad/editor_key_handler.lua`

Add support for common clipboard operations (Copy, Cut, Paste, Select All) to improve text editing workflow.

**Implementation Details:**
```lua
function EditorKeyHandler:ProcessKey(widget, key, down)
    -- Existing code...
    
    -- Handle clipboard operations
    if down and TheInput:IsKeyDown(KEY_CTRL) then
        -- Copy
        if key == KEY_C then
            return self:HandleCopy(widget)
        end
        
        -- Paste
        if key == KEY_V then
            return self:HandlePaste(widget)
        end
        
        -- Cut
        if key == KEY_X then
            return self:HandleCut(widget)
        end
        
        -- Select All
        if key == KEY_A then
            return self:HandleSelectAll(widget)
        end
    end
    
    -- Rest of existing code...
end

function EditorKeyHandler:HandleCopy(widget)
    local text = widget:GetString()
    local selection = self.editor:GetSelectedText()
    
    if selection and selection ~= "" then
        -- Store in our internal clipboard (DST doesn't have system clipboard access)
        self.clipboard = selection
        self.editor.state:ShowSaveIndicator("Copied!")
        return true
    end
    return false
end

function EditorKeyHandler:HandlePaste(widget)
    if not self.clipboard or self.clipboard == "" then
        return false
    end
    
    local text = widget:GetString()
    local cursor_pos = widget:GetEditCursorPos()
    local selection = self.editor:GetSelectedText()
    
    -- If text is selected, replace it with clipboard content
    if selection then
        local sel_start, sel_end = self.editor:GetSelectionRange()
        local new_text = text:sub(1, sel_start - 1) .. self.clipboard .. text:sub(sel_end + 1)
        widget:SetString(new_text)
        widget:SetEditCursorPos(sel_start + #self.clipboard)
    else
        -- Otherwise, insert at cursor position
        local new_text = text:sub(1, cursor_pos) .. self.clipboard .. text:sub(cursor_pos + 1)
        widget:SetString(new_text)
        widget:SetEditCursorPos(cursor_pos + #self.clipboard)
    end
    
    self.editor:ScrollToCursor()
    return true
end

function EditorKeyHandler:HandleCut(widget)
    -- Similar to copy but removes selected text
    -- ...
    return true
end

function EditorKeyHandler:HandleSelectAll(widget)
    local text = widget:GetString()
    self.editor:SetSelectionRange(1, #text)
    return true
end
```

### 2.3 Word Wrap Improvements
**Priority:** Low  
**Complexity:** Medium  
**Files to Modify:** `scripts/notepad/text_input_handler.lua`

Enhance the existing word wrap functionality to provide smoother text entry with automatic soft wrapping at word boundaries.

**Key Features:**
- Improve word wrap algorithm to only break at word boundaries
- Add support for non-breaking spaces
- Fix cursor positioning issues after line breaks

## Phase 3: Advanced Features

### 3.1 Multiple Notes/Pages
**Priority:** Medium  
**Complexity:** High  
**Files to Modify:** `scripts/widgets/notepad_ui.lua`, `scripts/notepad/data_manager.lua`, `scripts/widgets/notepadwidget.lua`

Allow users to have multiple pages of notes, providing a tab system for navigation and separate storage for each page.

**Key Features:**
- Create a tab system at the top of the notepad
- Modify data persistence system to handle multiple notes
- Add UI for page creation, deletion, and renaming

### 3.2 Simple Markdown Support
**Priority:** Low  
**Complexity:** High  
**Files to Modify:** Multiple files needed

Add basic markdown-style formatting to enhance note taking abilities.

**Key Features:**
- Support for basic formatting (bold, italic, lists)
- Live preview or syntax highlighting
- Export formatted text

### 3.3 Search Functionality
**Priority:** Medium  
**Complexity:** Medium  
**Files to Modify:** `scripts/widgets/notepad_ui.lua`, `scripts/notepad/notepad_editor.lua`

Add text search capability within notes, allowing users to find information quickly.

**Key Features:**
- Add search bar with next/previous buttons
- Highlight search results
- Jump between occurrences

### 3.4 Import/Export Notes
**Priority:** Low  
**Complexity:** Medium  
**Files to Modify:** `scripts/notepad/data_manager.lua`, `scripts/widgets/notepad_ui.lua`

Allow users to save notes outside the game and import notes from external sources.

**Key Features:**
- Add export functionality to save notes to external files
- Add import functionality to load notes from saved files

## Implementation Roadmap

### Phase 1 Implementation (Version 0.4.0)
1. Arrow key navigation
2. Improved cursor scrolling
3. Mouse wheel scrolling
4. Visual scrollbar

**Estimated time:** 1-2 weeks

### Phase 2 Implementation (Version 0.5.0)
1. Text selection
2. Clipboard operations
3. Word wrap improvements

**Estimated time:** 2-3 weeks

### Phase 3 Implementation (Versions 0.6.0+)
1. Multiple notes/pages
2. Search functionality
3. Simple markdown support
4. Import/Export notes

**Estimated time:** 4-6 weeks

## Conclusion

This enhancement plan provides a structured approach to improving the QuickNotes mod, focusing first on critical usability features before adding more advanced functionality. Each phase builds upon the previous one, ensuring that core features work well before adding complexity.

The implementation details provide a starting point for development, though actual implementation may require adjustment based on testing and compatibility with Don't Starve Together's API constraints.