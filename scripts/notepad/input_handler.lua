--[[
    Input Handler Module for DST Quick Notes
    
    This module manages all input interactions for the notepad widget, including:
    - Keyboard shortcuts (Ctrl+S to save, Escape to close)
    - Mouse dragging behavior for the title bar
    - Click detection for closing the notepad when clicking outside
    
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
    Sets up handler for clicks outside the notepad.
    Used to close the notepad when clicking away.
]]
function InputHandler:AddClickHandler()
    if self.click_handler then return end
    
    self.click_handler = TheInput:AddMouseButtonHandler(function(button, down, x, y)
        if button == MOUSEBUTTON_LEFT and down then
            -- Only process if notepad is open
            if self.widget:IsOpen() then
                -- Check title bar bounds
                local title_pos = self.widget.title:GetWorldPosition()
                local title_w, title_h = self.widget.title:GetRegionSize()
                local in_title = math.abs(y - title_pos.y) <= title_h/2
                
                -- Check close button bounds
                local close_pos = self.widget.close_btn:GetWorldPosition()
                local close_w, close_h = self.widget.close_btn:GetSize()
                local in_close = math.abs(x - close_pos.x) <= close_w/2 and 
                                math.abs(y - close_pos.y) <= close_h/2
                
                -- Close if click is outside notepad and not on title/close button
                if not self.widget:IsMouseInWidget(x, y) and not in_title and not in_close then
                    self.widget:Close()
                    return true
                end
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
            local title_pos = self.widget.title:GetWorldPosition()
            local title_h = select(2, self.widget.title:GetRegionSize())
            if math.abs(y - title_pos.y) <= title_h/2 then
                local mousepos = TheInput:GetScreenPosition()
                local pos = self.widget.root:GetPosition()
                self:StartDragging(mousepos.x, mousepos.y, pos)
                return true
            end
        else
            self:StopDragging()
        end
    end
    return false
end

return InputHandler