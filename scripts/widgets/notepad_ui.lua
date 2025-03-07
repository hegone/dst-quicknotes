--[[
    Notepad UI Module for DST Quick Notes
    
    This module handles the visual components of the notepad widget.
    It creates and configures all UI elements including backgrounds,
    frames, title bar, and controls. The module is responsible for
    the appearance and layout of the notepad interface.
    
    Usage:
        local NotepadUI = require "widgets/notepad_ui"
        local ui = NotepadUI(parent_widget)
        ui:InitializeUIComponents()
]]

local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local Text = require "widgets/text"
local Widget = require "widgets/widget"
local Config = require "notepad/config"

--[[
    NotepadUI Class
    
    Handles the creation and configuration of all visual UI elements
    for the notepad widget. This class is responsible for the appearance
    and layout of the notepad interface.
    
    @param parent (Widget) Parent widget that will own these UI elements
]]
local NotepadUI = Class(function(self, parent)
    self.parent = parent  -- Store reference to parent widget
end)

--[[
    Initializes the transparent background that allows clicking through.
]]
function NotepadUI:InitializeBackground()
    self.parent.black = self.parent:AddChild(Image("images/global.xml", "square.tex"))
    self.parent.black:SetVRegPoint(ANCHOR_MIDDLE)
    self.parent.black:SetHRegPoint(ANCHOR_MIDDLE)
    self.parent.black:SetVAnchor(ANCHOR_MIDDLE)
    self.parent.black:SetHAnchor(ANCHOR_MIDDLE)
    self.parent.black:SetScaleMode(SCALEMODE_FILLSCREEN)
    self.parent.black:SetTint(0, 0, 0, 0)  -- Completely transparent
end

--[[
    Initializes the root widget and its visual components.
]]
function NotepadUI:InitializeRootWidget()
    -- Create root widget
    self.parent.root = self.parent:AddChild(Widget("ROOT"))
    self.parent.root:SetVAnchor(ANCHOR_MIDDLE)
    self.parent.root:SetHAnchor(ANCHOR_MIDDLE)
    self.parent.root:SetScaleMode(SCALEMODE_PROPORTIONAL)
    self.parent.root:SetPosition(0, 0)
    
    -- Add shadow for depth
    self.parent.bg_shadow = self.parent.root:AddChild(Image("images/global.xml", "square.tex"))
    self.parent.bg_shadow:SetSize(Config.DIMENSIONS.SHADOW.WIDTH, Config.DIMENSIONS.SHADOW.HEIGHT)
    self.parent.bg_shadow:SetPosition(5, -5)
    self.parent.bg_shadow:SetTint(
        Config.COLORS.SHADOW_TINT.r,
        Config.COLORS.SHADOW_TINT.g,
        Config.COLORS.SHADOW_TINT.b,
        Config.COLORS.SHADOW_TINT.a
    )
end

--[[
    Initializes all UI components including background, frame, title,
    editor, and save indicator.
]]
function NotepadUI:InitializeUIComponents()
    -- Set up clickable background
    self:InitializeClickableBackground()
    
    -- Add decorative frame
    self:InitializeFrame()
    
    -- Add title bar and text
    self:InitializeTitleBar()
    
    -- Add save indicator
    self:InitializeSaveIndicator()
    
    -- Add close button
    self:InitializeCloseButton()
end

--[[
    Creates the clickable background that handles focus.
]]
function NotepadUI:InitializeClickableBackground()
    self.parent.bg = self.parent.root:AddChild(Image("images/global.xml", "square.tex"))
    self.parent.bg:SetSize(Config.DIMENSIONS.BACKGROUND.WIDTH, Config.DIMENSIONS.BACKGROUND.HEIGHT)
    self.parent.bg:SetTint(0, 0, 0, 0)  -- Completely transparent
    self.parent.bg:SetClickable(true)
    self.parent.bg.OnMouseButton = function(_, button, down, x, y)
        if button == MOUSEBUTTON_LEFT and down then
            if self.parent.editor then
                self.parent.editor:SetFocus()
            end
            return true
        end
        return false
    end
end

--[[
    Creates the decorative frame around the notepad.
]]
function NotepadUI:InitializeFrame()
    self.parent.frame = self.parent.root:AddChild(Image("images/global.xml", "square.tex"))
    self.parent.frame:SetSize(Config.DIMENSIONS.FRAME.WIDTH, Config.DIMENSIONS.FRAME.HEIGHT)
    self.parent.frame:SetTint(
        Config.COLORS.FRAME_TINT.r,
        Config.COLORS.FRAME_TINT.g,
        Config.COLORS.FRAME_TINT.b,
        Config.COLORS.FRAME_TINT.a
    )
end

--[[
    Creates the title bar with background and text.
]]
function NotepadUI:InitializeTitleBar()
    -- Title background
    self.parent.title_bg = self.parent.root:AddChild(Image("images/global.xml", "square.tex"))
    self.parent.title_bg:SetSize(Config.DIMENSIONS.TITLE_BAR.WIDTH, Config.DIMENSIONS.TITLE_BAR.HEIGHT)
    self.parent.title_bg:SetPosition(0, 160)
    self.parent.title_bg:SetTint(
        Config.COLORS.TITLE_BG_TINT.r,
        Config.COLORS.TITLE_BG_TINT.g,
        Config.COLORS.TITLE_BG_TINT.b,
        Config.COLORS.TITLE_BG_TINT.a
    )
    
    -- Title text
    self.parent.title = self.parent.root:AddChild(Text(HEADERFONT, Config.FONT_SIZES.TITLE, "Quick Notes"))
    self.parent.title:SetPosition(0, 160)
    self.parent.title:SetColour(
        Config.COLORS.TITLE_TEXT.r,
        Config.COLORS.TITLE_TEXT.g,
        Config.COLORS.TITLE_TEXT.b,
        Config.COLORS.TITLE_TEXT.a
    )
    self.parent.title:SetClickable(true)  -- Enable dragging
end

--[[
    Creates the save indicator text.
]]
function NotepadUI:InitializeSaveIndicator()
    self.parent.save_indicator = self.parent.root:AddChild(Text(DEFAULTFONT, Config.FONT_SIZES.SAVE_INDICATOR, ""))
    self.parent.save_indicator:SetPosition(0, -170)
    self.parent.save_indicator:SetColour(
        Config.COLORS.SAVE_INDICATOR.r,
        Config.COLORS.SAVE_INDICATOR.g,
        Config.COLORS.SAVE_INDICATOR.b,
        Config.COLORS.SAVE_INDICATOR.a
    )
end

--[[
    Creates the close button.
]]
function NotepadUI:InitializeCloseButton()
    -- Create button container
    local button_container = self.parent.root:AddChild(Widget("ButtonContainer"))
    button_container:SetPosition(230, 170)
    
    -- Add reset button
    self.parent.reset_btn = button_container:AddChild(ImageButton("images/global_redux.xml", "close.tex"))
    self.parent.reset_btn:SetPosition(-30, 0)  -- Position to the left of close button
    self.parent.reset_btn:SetScale(0.7)
    self.parent.reset_btn:SetOnClick(function() self.parent:Reset() end)
    self.parent.reset_btn:SetHoverText("Reset Notepad (Ctrl+R)")
    self.parent.reset_btn:SetImageNormalColour(0.7, 0.2, 0.2, 1)  -- Red tint
    self.parent.reset_btn:SetRotation(45)  -- Rotate it to make it look different from the close button
    
    -- Add close button
    self.parent.close_btn = button_container:AddChild(ImageButton("images/global_redux.xml", "close.tex"))
    self.parent.close_btn:SetScale(0.7)
    self.parent.close_btn:SetOnClick(function() self.parent:Close() end)
    self.parent.close_btn:SetHoverText("Close Notepad")
    self.parent.close_btn:SetImageNormalColour(0.2, 0.2, 0.2, 1)  -- Dark gray tint
end

--[[
    Checks if a point is within the widget's bounds.
    
    @param x (number) X coordinate to check
    @param y (number) Y coordinate to check
    @return (boolean) True if the point is within the widget
]]
function NotepadUI:IsMouseInWidget(x, y)
    if not self.parent.bg then return false end
    
    -- Check title bar area
    local title_pos = self.parent.title:GetWorldPosition()
    local title_w, title_h = self.parent.title:GetRegionSize()
    local in_title = math.abs(y - title_pos.y) <= title_h/2
    
    -- Check close button area
    local close_pos = self.parent.close_btn:GetWorldPosition()
    local close_w, close_h = self.parent.close_btn:GetSize()
    local in_close = math.abs(x - close_pos.x) <= close_w/2 and math.abs(y - close_pos.y) <= close_h/2
    
    -- Check main notepad area
    local pos = self.parent.root:GetPosition()
    local size = {self.parent.bg:GetSize()}
    local left = pos.x - size[1]/2
    local right = pos.x + size[1]/2
    local bottom = pos.y - size[2]/2
    local top = pos.y + size[2]/2
    local in_notepad = x >= left and x <= right and y >= bottom and y <= top
    
    return in_title or in_close or in_notepad
end

return NotepadUI