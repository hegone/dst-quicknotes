--[[
    Draggable Widget Module for DST Quick Notes
    
    This module provides drag-and-drop functionality for widgets in Don't Starve Together.
    It handles mouse interaction calculations and position updates, making it easy to
    add dragging behavior to any widget.

    The module maintains drag state and offset calculations internally, providing a
    clean interface for starting, updating, and stopping drag operations.

    Usage:
        local DraggableWidget = require("notepad/draggable_widget")
        local dragger = DraggableWidget()
        
        -- In your widget's OnMouseButton:
        if button == MOUSEBUTTON_LEFT then
            dragger:StartDragging(mouseX, mouseY, self:GetPosition())
        end
        
        -- In your widget's OnMouseMove:
        dragger:UpdateDragging(self, mouseX, mouseY)
]]

--[[
    DraggableWidget Class
    
    Handles drag-and-drop functionality for widgets, maintaining drag state
    and calculating position updates based on mouse movement.
]]
local DraggableWidget = Class(function(self)
    -- Initialize drag state
    self.dragging = false           -- Current drag state
    self.drag_offset = {            -- Offset from mouse to widget position
        x = 0,
        y = 0
    }
end)

--[[
    Starts a drag operation.
    
    @param x (number) Current mouse X position
    @param y (number) Current mouse Y position
    @param widget_pos (table) Widget's current position {x=number, y=number}
    @return (boolean) Always returns true to indicate drag started
]]
function DraggableWidget:StartDragging(x, y, widget_pos)
    self.dragging = true
    -- Calculate offset between mouse position and widget position
    self.drag_offset = {
        x = x - widget_pos.x,
        y = y - widget_pos.y
    }
    return true
end

--[[
    Stops the current drag operation.
]]
function DraggableWidget:StopDragging()
    self.dragging = false
end

--[[
    Updates widget position during dragging.
    
    @param widget (Widget) The widget being dragged
    @param x (number) Current mouse X position
    @param y (number) Current mouse Y position
    @return (boolean) True if position was updated, false if not dragging
]]
function DraggableWidget:UpdateDragging(widget, x, y)
    if self.dragging and widget then
        -- Update widget position based on mouse position and stored offset
        widget:SetPosition(
            x - self.drag_offset.x,
            y - self.drag_offset.y
        )
        return true
    end
    return false
end

--[[
    Checks if widget is currently being dragged.
    
    @return (boolean) True if widget is being dragged, false otherwise
]]
function DraggableWidget:IsDragging()
    return self.dragging
end

return DraggableWidget