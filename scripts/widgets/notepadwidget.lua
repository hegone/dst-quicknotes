--[[
    Notepad Widget Module for DST Quick Notes
    
    This is the main widget module that creates and manages the notepad UI.
    It handles the overall layout, appearance, and behavior of the notepad,
    including:
    - Creating and positioning UI elements (frame, title, editor, etc.)
    - Managing widget lifecycle (show/hide, focus, destruction)
    - Coordinating with other modules (data, input, editor)
    - Auto-saving and manual saving of notes
    - Drag and drop functionality
    
    The widget uses DST's screen system and follows the game's UI styling
    to maintain a consistent look and feel.

    Usage:
        local NotepadWidget = require("widgets/notepadwidget")
        local notepad = NotepadWidget()
        notepad:OnBecomeActive()  -- Show the notepad
]]

local Screen = require "widgets/screen"
local Widget = require "widgets/widget"
local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local Text = require "widgets/text"
local Button = require "widgets/button"
local TEMPLATES = require "widgets/templates"
local DataManager = require "notepad/data_manager"
local InputHandler = require "notepad/input_handler"
local Config = require "notepad/config"
local DraggableWidget = require "notepad/draggable_widget"
local NotepadEditor = require "notepad/notepad_editor"

--[[
    NotepadWidget Class
    
    Main widget class that extends Screen to create a floating notepad interface.
    Manages the visual layout, user interaction, and data persistence of notes.
]]
local NotepadWidget = Class(Screen, function(self)
    Screen._ctor(self, "NotepadWidget")
    print("[Quick Notes] Creating NotepadWidget")
    
    -- Initialize core components
    self.data_manager = DataManager()
    self.isOpen = false
    
    -- Initialize timers
    self.save_timer = nil          -- Controls save indicator visibility
    self.auto_save_timer = nil     -- Handles periodic auto-saving
    self.focus_task = nil          -- Manages focus delay on open
    
    -- Initialize input handling
    self.input_handler = InputHandler(self)
    
    -- Set up non-modal screen background
    self:InitializeBackground()
    
    -- Create and configure root widget
    self:InitializeRootWidget()
    
    -- Set up UI components
    self:InitializeUIComponents()
    
    -- Set default focus and load saved notes
    self.default_focus = self.editor
    self:LoadNotes()
    
    print("[Quick Notes] NotepadWidget created successfully")
    self:Hide()
end)

--[[
    Initializes the transparent background that allows clicking through.
]]
function NotepadWidget:InitializeBackground()
    self.black = self:AddChild(Image("images/global.xml", "square.tex"))
    self.black:SetVRegPoint(ANCHOR_MIDDLE)
    self.black:SetHRegPoint(ANCHOR_MIDDLE)
    self.black:SetVAnchor(ANCHOR_MIDDLE)
    self.black:SetHAnchor(ANCHOR_MIDDLE)
    self.black:SetScaleMode(SCALEMODE_FILLSCREEN)
    self.black:SetTint(0, 0, 0, 0)  -- Completely transparent
end

--[[
    Initializes the root widget and its visual components.
]]
function NotepadWidget:InitializeRootWidget()
    -- Create root widget
    self.root = self:AddChild(Widget("ROOT"))
    self.root:SetVAnchor(ANCHOR_MIDDLE)
    self.root:SetHAnchor(ANCHOR_MIDDLE)
    self.root:SetScaleMode(SCALEMODE_PROPORTIONAL)
    self.root:SetPosition(0, 0)
    
    -- Add shadow for depth
    self.bg_shadow = self.root:AddChild(Image("images/global.xml", "square.tex"))
    self.bg_shadow:SetSize(Config.DIMENSIONS.SHADOW.WIDTH, Config.DIMENSIONS.SHADOW.HEIGHT)
    self.bg_shadow:SetPosition(5, -5)
    self.bg_shadow:SetTint(
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
function NotepadWidget:InitializeUIComponents()
    -- Set up clickable background
    self:InitializeClickableBackground()
    
    -- Add decorative frame
    self:InitializeFrame()
    
    -- Add title bar and text
    self:InitializeTitleBar()
    
    -- Initialize text editor
    self.editor = NotepadEditor(self.root, DEFAULTFONT, Config.FONT_SIZES.EDITOR)
    
    -- Add save indicator
    self:InitializeSaveIndicator()
    
    -- Add close button
    self:InitializeCloseButton()
end

--[[
    Creates the clickable background that handles focus.
]]
function NotepadWidget:InitializeClickableBackground()
    self.bg = self.root:AddChild(Image("images/global.xml", "square.tex"))
    self.bg:SetSize(Config.DIMENSIONS.BACKGROUND.WIDTH, Config.DIMENSIONS.BACKGROUND.HEIGHT)
    self.bg:SetTint(0, 0, 0, 0)  -- Completely transparent
    self.bg:SetClickable(true)
    self.bg.OnMouseButton = function(_, button, down, x, y)
        if button == MOUSEBUTTON_LEFT and down then
            if self.editor then
                self.editor:SetFocus()
            end
            return true
        end
        return false
    end
end

--[[
    Creates the decorative frame around the notepad.
]]
function NotepadWidget:InitializeFrame()
    self.frame = self.root:AddChild(Image("images/global.xml", "square.tex"))
    self.frame:SetSize(Config.DIMENSIONS.FRAME.WIDTH, Config.DIMENSIONS.FRAME.HEIGHT)
    self.frame:SetTint(
        Config.COLORS.FRAME_TINT.r,
        Config.COLORS.FRAME_TINT.g,
        Config.COLORS.FRAME_TINT.b,
        Config.COLORS.FRAME_TINT.a
    )
end

--[[
    Creates the title bar with background and text.
]]
function NotepadWidget:InitializeTitleBar()
    -- Title background
    self.title_bg = self.root:AddChild(Image("images/global.xml", "square.tex"))
    self.title_bg:SetSize(Config.DIMENSIONS.TITLE_BAR.WIDTH, Config.DIMENSIONS.TITLE_BAR.HEIGHT)
    self.title_bg:SetPosition(0, 160)
    self.title_bg:SetTint(
        Config.COLORS.TITLE_BG_TINT.r,
        Config.COLORS.TITLE_BG_TINT.g,
        Config.COLORS.TITLE_BG_TINT.b,
        Config.COLORS.TITLE_BG_TINT.a
    )
    
    -- Title text
    self.title = self.root:AddChild(Text(HEADERFONT, Config.FONT_SIZES.TITLE, "Quick Notes"))
    self.title:SetPosition(0, 160)
    self.title:SetColour(
        Config.COLORS.TITLE_TEXT.r,
        Config.COLORS.TITLE_TEXT.g,
        Config.COLORS.TITLE_TEXT.b,
        Config.COLORS.TITLE_TEXT.a
    )
    self.title:SetClickable(true)  -- Enable dragging
end

--[[
    Creates the save indicator text.
]]
function NotepadWidget:InitializeSaveIndicator()
    self.save_indicator = self.root:AddChild(Text(DEFAULTFONT, Config.FONT_SIZES.SAVE_INDICATOR, ""))
    self.save_indicator:SetPosition(0, -170)
    self.save_indicator:SetColour(
        Config.COLORS.SAVE_INDICATOR.r,
        Config.COLORS.SAVE_INDICATOR.g,
        Config.COLORS.SAVE_INDICATOR.b,
        Config.COLORS.SAVE_INDICATOR.a
    )
end

--[[
    Creates the close button.
]]
function NotepadWidget:InitializeCloseButton()
    -- Create button container
    local button_container = self.root:AddChild(Widget("ButtonContainer"))
    button_container:SetPosition(230, 170)
    
    -- Add reset button
    self.reset_btn = button_container:AddChild(ImageButton("images/global.xml", "square.tex"))
    self.reset_btn:SetPosition(-30, 0)  -- Position to the left of close button
    self.reset_btn:SetScale(0.5)
    self.reset_btn:SetOnClick(function() self:Reset() end)
    self.reset_btn:SetHoverText("Reset Notepad (Ctrl+R)")
    self.reset_btn:SetImageNormalColour(0.7, 0.2, 0.2, 1)  -- Red tint
    
    -- Add close button
    self.close_btn = button_container:AddChild(ImageButton("images/global.xml", "square.tex"))
    self.close_btn:SetScale(0.5)
    self.close_btn:SetOnClick(function() self:Close() end)
    self.close_btn:SetHoverText("Close Notepad")
    self.close_btn:SetImageNormalColour(0.2, 0.2, 0.2, 1)  -- Dark gray tint
end

--[[
    Updates widget state, primarily handling dragging.
]]
function NotepadWidget:OnUpdate()
    self.input_handler:UpdateDragging(self.root)
end

--[[
    Handles mouse button events.
    
    @param button (number) The mouse button being pressed
    @param down (boolean) Whether the button is being pressed down
    @param x (number) Mouse X position
    @param y (number) Mouse Y position
    @return (boolean) True if the input was handled
]]
function NotepadWidget:OnMouseButton(button, down, x, y)
    if self.input_handler:OnMouseButton(button, down, x, y) then
        return true
    end
    return NotepadWidget._base.OnMouseButton(self, button, down, x, y)
end

--[[
    Called when the widget becomes active.
    Handles showing the widget and setting up timers.
]]
function NotepadWidget:OnBecomeActive()
    print("[Quick Notes] NotepadWidget becoming active")
    NotepadWidget._base.OnBecomeActive(self)
    
    self:Show()
    self.isOpen = true
    self.root:ScaleTo(0, 1, Config.SETTINGS.OPEN_ANIMATION_DURATION)
    
    self.input_handler:AddClickHandler()
    
    -- Handle focus timing
    if self.focus_task then
        self.focus_task:Cancel()
        self.focus_task = nil
    end
    
    self.focus_task = self.inst:DoTaskInTime(Config.SETTINGS.FOCUS_DELAY, function()
        if self.editor then
            self.editor:SetFocus()
            self:StartAutoSave()
        end
        self.focus_task = nil
    end)
end

--[[
    Called when the widget becomes inactive.
    Handles cleanup and saving.
]]
function NotepadWidget:OnBecomeInactive()
    print("[Quick Notes] NotepadWidget becoming inactive")
    NotepadWidget._base.OnBecomeInactive(self)
    
    self.input_handler:RemoveClickHandler()
    
    self:Hide()
    self.isOpen = false
    self:StopAutoSave()
    self:SaveNotes()  -- Save on close
    
    if self.focus_task then
        self.focus_task:Cancel()
        self.focus_task = nil
    end
end

--[[
    Starts the auto-save timer.
]]
function NotepadWidget:StartAutoSave()
    self:StopAutoSave()  -- Clean up any existing timer
    self.auto_save_timer = self.inst:DoPeriodicTask(Config.SETTINGS.AUTO_SAVE_INTERVAL, function()
        if self.editor and self.editor:GetText() then
            self:SaveNotes()
        end
    end)
end

--[[
    Stops the auto-save timer.
]]
function NotepadWidget:StopAutoSave()
    if self.auto_save_timer then
        self.auto_save_timer:Cancel()
        self.auto_save_timer = nil
    end
end

--[[
    Closes the notepad widget.
]]
function NotepadWidget:Close()
    print("[Quick Notes] NotepadWidget closing")
    self:SaveNotes()
    self.isOpen = false
    if _G.TheFrontEnd:GetActiveScreen() == self then
        _G.TheFrontEnd:PopScreen(self)
    end
end

--[[
    Saves the current notes content.
]]
function NotepadWidget:SaveNotes()
    if not self.editor then return end
    local content = self.editor:GetText()
    if not content then return end
    
    if self.data_manager:SaveNotes(content) then
        self:ShowSaveIndicator("Saved!")
    end
end

--[[
    Shows the save indicator with a message.
    
    @param message (string) Message to display (optional)
]]
function NotepadWidget:ShowSaveIndicator(message)
    if not self.save_indicator then return end
    
    self.save_indicator:SetString(message or "")
    
    if self.save_timer then
        self.save_timer:Cancel()
        self.save_timer = nil
    end
    
    self.save_timer = self.inst:DoTaskInTime(Config.SETTINGS.SAVE_INDICATOR_DURATION, function()
        if self.save_indicator then
            self.save_indicator:SetString("")
        end
        self.save_timer = nil
    end)
end

--[[
    Loads saved notes from persistent storage.
]]
function NotepadWidget:LoadNotes()
    self.data_manager:LoadNotes(function(success, content)
        if success and self.editor then
            self.editor:SetText(content)
        else
            if self.editor then
                self.editor:SetText("")
            end
        end
    end)
end

--[[
    Resets the notepad by clearing all content.
    Optionally saves the cleared state.
    
    @param save_state (boolean) Whether to save the cleared state (optional, defaults to true)
]]
function NotepadWidget:Reset(save_state)
    if not self.editor then return end
    
    -- Clear editor content
    self.editor:SetText("")
    
    -- Show feedback
    self:ShowSaveIndicator("Reset!")
    
    -- Save cleared state if requested
    if save_state ~= false then
        self:SaveNotes()
    end
end

--[[
    Handles keyboard control events.
    
    @param control (number) The control code
    @param down (boolean) Whether the key is being pressed down
    @return (boolean) True if the input was handled
]]
function NotepadWidget:OnControl(control, down)
    if NotepadWidget._base.OnControl(self, control, down) then return true end
    return self.input_handler:OnControl(control, down)
end

--[[
    Handles raw key events for global shortcuts.
    
    @param key (number) The key code
    @param down (boolean) Whether the key is being pressed down
    @return (boolean) True if the key was handled
]]
function NotepadWidget:OnRawKey(key, down)
    -- Handle reset shortcut (Ctrl+R)
    if down and key == KEY_R and TheInput:IsKeyDown(KEY_CTRL) then
        self:Reset()
        return true
    end
    
    return false
end

--[[
    Checks if a point is within the widget's bounds.
    
    @param x (number) X coordinate to check
    @param y (number) Y coordinate to check
    @return (boolean) True if the point is within the widget
]]
function NotepadWidget:IsMouseInWidget(x, y)
    if not self.bg then return false end
    
    -- Check title bar area
    local title_pos = self.title:GetWorldPosition()
    local title_w, title_h = self.title:GetRegionSize()
    local in_title = math.abs(y - title_pos.y) <= title_h/2
    
    -- Check close button area
    local close_pos = self.close_btn:GetWorldPosition()
    local close_w, close_h = self.close_btn:GetSize()
    local in_close = math.abs(x - close_pos.x) <= close_w/2 and math.abs(y - close_pos.y) <= close_h/2
    
    -- Check main notepad area
    local pos = self.root:GetPosition()
    local size = {self.bg:GetSize()}
    local left = pos.x - size[1]/2
    local right = pos.x + size[1]/2
    local bottom = pos.y - size[2]/2
    local top = pos.y + size[2]/2
    local in_notepad = x >= left and x <= right and y >= bottom and y <= top
    
    return in_title or in_close or in_notepad
end

--[[
    Checks if the notepad is currently open.
    
    @return (boolean) True if the notepad is open
]]
function NotepadWidget:IsOpen()
    return self.isOpen
end

--[[
    Cleans up the widget and its components.
    Called when the widget is being destroyed.
]]
function NotepadWidget:OnDestroy()
    -- Remove input handler
    if self.input_handler then
        self.input_handler:RemoveClickHandler()
    end
    
    -- Cancel all timers
    self:StopAutoSave()
    
    if self.save_timer then
        self.save_timer:Cancel()
        self.save_timer = nil
    end
    
    if self.focus_task then
        self.focus_task:Cancel()
        self.focus_task = nil
    end
    
    -- Destroy UI components
    if self.save_indicator then self.save_indicator:Kill() end
    if self.editor then
        self.editor:Kill()
        self.editor = nil
    end
    if self.close_btn then self.close_btn:Kill() end
    if self.title then self.title:Kill() end
    if self.frame then self.frame:Kill() end
    if self.bg then self.bg:Kill() end
    
    NotepadWidget._base.OnDestroy(self)
end

return NotepadWidget