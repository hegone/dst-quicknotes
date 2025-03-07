--[[
    Input Handler Module for DST Quick Notes
    
    This module manages all input interactions for the notepad widget, including:
    - Keyboard shortcuts (Ctrl+S to save, Escape to close)
    - Mouse dragging behavior for the title bar
    - Click detection for closing the notepad when clicking outside
    - Direct handling of clicks within the editor for cursor positioning
    
    It centralizes input handling logic to keep the main widget code cleaner
    and more focused on UI presentation.

    Usage:
        local InputHandler = require("notepad/input_handler")
        local handler = InputHandler(widget)
        handler:AddClickHandler()  -- Start handling outside clicks
]]

--[[
    InputHandler Class
    
    Manages keyboard and mouse input for the notepad widget.
    Coordinates with the widget to handle saving, closing, dragging,
    and other input-based interactions.

    @param widget (Widget) The notepad widget this handler controls
]]
local InputHandler = Class(function(self, widget)
    self.widget = widget                  -- Reference to the notepad widget
    self.keyboard_handlers = {}           -- Map of control codes to handler functions
    self.click_handler = nil              -- Handler for clicks outside widget
    
    -- Drag state tracking
    self.dragging = false                 -- Current drag state
    self.drag_start_x = 0                 -- Mouse X position when drag started
    self.drag_start_y = 0                 -- Mouse Y position when drag started
    self.widget_start_x = 0               -- Widget X position when drag started
    self.widget_start_y = 0               -- Widget Y position when drag started
    
    self:SetupKeyboardHandlers()          -- Initialize keyboard shortcuts
end)

--[[
    Sets up keyboard shortcut handlers.
    Currently supports:
    - Ctrl+S: Save notes
    - Escape: Close notepad
]]
function InputHandler:SetupKeyboardHandlers()
    self.keyboard_handlers = {
        -- Escape to close
        [CONTROL_CANCEL] = function()
            self.widget:Close()
            return true
        end
    }
end

--[[
    Handles keyboard control events.
    
    @param control (number) The control code being pressed
    @param down (boolean) Whether the key is being pressed down
    @return (boolean) True if the input was handled, false otherwise
]]
function InputHandler:OnControl(control, down)
    if down and control == CONTROL_CANCEL then
        -- Force return true to prevent event propagation
        self.widget:Close()
        return true
    end
    
    if down and self.keyboard_handlers[control] then
        return self.keyboard_handlers[control]()
    end
    return false
end

--[[
    Handles raw key events for keyboard shortcuts.
    
    @param key (number) The key code
    @param down (boolean) Whether the key is being pressed down
    @return (boolean) True if the key was handled
]]
function InputHandler:OnRawKey(key, down)
    -- Handle Escape key to close the notepad
    if down and key == KEY_ESCAPE then
        self.widget:Close()
        return true
    end
    
    -- Handle Ctrl+S to save
    if down and key == KEY_S and TheInput:IsKeyDown(KEY_CTRL) then
        self.widget:SaveNotes()
        return true
    end
    return false
end

--[[
    Initiates dragging operation.
    
    @param x (number) Starting mouse X position
    @param y (number) Starting mouse Y position
    @param widget_pos (table) Widget's current position {x=number, y=number}
]]
function InputHandler:StartDragging(x, y, widget_pos)
    self.dragging = true
    -- Store initial positions for drag calculations
    self.drag_start_x = x
    self.drag_start_y = y
    self.widget_start_x = widget_pos.x
    self.widget_start_y = widget_pos.y
end

--[[
    Stops the current dragging operation.
]]
function InputHandler:StopDragging()
    self.dragging = false
end

--[[
    Updates widget position during dragging.
    
    @param root (Widget) The root widget being dragged
]]
function InputHandler:UpdateDragging(root)
    if self.dragging and TheInput:IsMouseDown(MOUSEBUTTON_LEFT) then
        local mousepos = TheInput:GetScreenPosition()
        -- Calculate position delta from drag start
        local dx = mousepos.x - self.drag_start_x
        local dy = mousepos.y - self.drag_start_y
        -- Update widget position
        root:SetPosition(self.widget_start_x + dx, self.widget_start_y + dy)
    else
        self.dragging = false
    end
end

--[[
    Checks if a click is inside the editor area.
    
    @param x (number) Mouse X position
    @param y (number) Mouse Y position
    @return (boolean) True if the click is inside editor area
]]
function InputHandler:IsClickInEditorArea(x, y)
    -- Make sure we have a valid editor
    if not self.widget or not self.widget.editor or not self.widget.editor.editor then
        print("[Quick Notes] DEBUG: Missing editor components in IsClickInEditorArea")
        return false
    end
    
    -- Get the actual TextEdit widget
    local text_edit = self.widget.editor.editor
    
    -- Get editor position and size
    local editor_pos = text_edit:GetWorldPosition()
    local editor_width, editor_height = text_edit:GetRegionSize()
    
    -- Calculate if point is within editor bounds
    local in_editor = (math.abs(x - editor_pos.x) <= editor_width/2) and 
                     (math.abs(y - editor_pos.y) <= editor_height/2)
    
    print("[Quick Notes] DEBUG: Click at", x, y, "editor at", editor_pos.x, editor_pos.y, "size", editor_width, editor_height, "in editor:", in_editor)
    
    return in_editor
end

--[[
    Handles cursor positioning for clicks inside the editor.
    
    @param x (number) Mouse X position
    @param y (number) Mouse Y position
    @return (boolean) True if handled
]]
function InputHandler:PositionCursorAtClick(x, y)
    -- Make sure we have a valid editor
    if not self.widget or not self.widget.editor or not self.widget.editor.editor then
        print("[Quick Notes] DEBUG: Missing editor components in PositionCursorAtClick")
        return false
    end
    
    -- Get the actual TextEdit widget
    local text_edit = self.widget.editor.editor
    
    -- Check if editor has necessary methods
    if not text_edit.GetString or not text_edit.SetEditCursorPos then
        print("[Quick Notes] DEBUG: Editor missing required methods")
        return false
    end
    
    print("[Quick Notes] DEBUG: Positioning cursor from click")
    
    -- Get text content
    local text = text_edit:GetString() or ""
    if text == "" then
        text_edit:SetEditCursorPos(0)
        return true
    end
    
    -- Get editor dimensions and position
    local editor_pos = text_edit:GetWorldPosition()
    local editor_width, editor_height = text_edit:GetRegionSize()
    
    -- Calculate local coordinates within editor
    local local_x = x - editor_pos.x
    local local_y = y - editor_pos.y
    
    -- Calculate position as percentage of editor width/height
    local x_percent = (local_x + editor_width/2) / editor_width
    local y_percent = (local_y + editor_height/2) / editor_height
    
    -- Clamp percentages to 0-1 range
    x_percent = math.max(0, math.min(1, x_percent))
    y_percent = math.max(0, math.min(1, y_percent))
    
    print("[Quick Notes] DEBUG: Click position: local=", local_x, local_y, "percent=", x_percent, y_percent)
    
    -- Split text into lines
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
    table.insert(lines, current_line)
    
    -- Calculate which line was clicked
    local line_index = math.max(1, math.min(#lines, math.floor(y_percent * #lines) + 1))
    
    -- Calculate character position within line
    local line = lines[line_index]
    local char_index = math.max(0, math.min(#line, math.floor(x_percent * #line)))
    
    -- Convert line/char into absolute cursor position
    local absolute_pos = 0
    for i = 1, line_index - 1 do
        absolute_pos = absolute_pos + #lines[i] + 1  -- +1 for newline
    end
    absolute_pos = absolute_pos + char_index
    
    -- Set cursor position
    print("[Quick Notes] DEBUG: Positioning cursor at line", line_index, "char", char_index, "absolute", absolute_pos)
    text_edit:SetEditCursorPos(absolute_pos)
    
    -- Make sure editor keeps focus and editing mode
    text_edit:SetFocus()
    text_edit:SetEditing(true)
    
    return true
end

--[[
    Sets up handler for clicks outside the notepad.
    Used to close the notepad when clicking away.
]]
function InputHandler:AddClickHandler()
    if self.click_handler then return end
    
    self.click_handler = TheInput:AddMouseButtonHandler(function(button, down, x, y)
        if button == MOUSEBUTTON_LEFT and down and self.widget:IsOpen() then
            -- First check if click is inside editor area - if so, handle it specially
            if self:IsClickInEditorArea(x, y) then
                print("[Quick Notes] DEBUG: Click detected in editor area")
                self:PositionCursorAtClick(x, y)
                return true  -- Consume the event
            end
            
            -- Check if it's inside the notepad using the UI's method
            if not self.widget.ui:IsMouseInWidget(x, y) then
                -- Only close if it's truly outside the notepad
                print("[Quick Notes] Click outside notepad - closing")
                self.widget:Close()
                return true
            end
        end
        return false
    end)
end

--[[
    Removes the outside click handler.
    Called when closing the notepad.
]]
function InputHandler:RemoveClickHandler()
    if self.click_handler then
        self.click_handler:Remove()
        self.click_handler = nil
    end
end

--[[
    Handles mouse button events.
    
    @param button (number) The mouse button being pressed
    @param down (boolean) Whether the button is being pressed down
    @param x (number) Mouse X position
    @param y (number) Mouse Y position
    @return (boolean) True if the input was handled, false otherwise
]]
function InputHandler:OnMouseButton(button, down, x, y)
    if button == MOUSEBUTTON_LEFT then
        if down then
            -- Only allow dragging from title bar
            if self.widget and self.widget.title then
                local title_pos = self.widget.title:GetWorldPosition()
                local title_h = select(2, self.widget.title:GetRegionSize())
                if math.abs(y - title_pos.y) <= title_h/2 then
                    local mousepos = TheInput:GetScreenPosition()
                    local pos = self.widget.root:GetPosition()
                    self:StartDragging(mousepos.x, mousepos.y, pos)
                    return true
                end
            end
            
            -- Check if click is in editor area
            if self:IsClickInEditorArea(x, y) then
                print("[Quick Notes] DEBUG: Click in editor area via OnMouseButton")
                return self:PositionCursorAtClick(x, y)
            end
        else
            self:StopDragging()
        end
    end
    return false
end

return InputHandler