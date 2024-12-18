local Screen = require "widgets/screen"
local Widget = require "widgets/widget"
local TextEdit = require "widgets/textedit"
local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local Text = require "widgets/text"
local Button = require "widgets/button"
local TEMPLATES = require "widgets/templates"

local NotepadWidget = Class(Screen, function(self)
    Screen._ctor(self, "NotepadWidget")
    print("Creating NotepadWidget")

    self.isOpen = false
    -- Dragging state
    self.dragging = false
    self.drag_start_x = 0
    self.drag_start_y = 0
    self.widget_start_x = 0
    self.widget_start_y = 0
    -- Initialize timers (using existing UI inst from Screen)
    self.save_timer = nil
    self.auto_save_timer = nil
    self.focus_task = nil
    
    -- Create root widget
    self.root = self:AddChild(Widget("ROOT"))
    self.root:SetVAnchor(ANCHOR_MIDDLE)
    self.root:SetHAnchor(ANCHOR_MIDDLE)
    self.root:SetScaleMode(SCALEMODE_PROPORTIONAL)
    self.root:SetPosition(0, 0)
    
    -- Background shadow
    self.bg_shadow = self.root:AddChild(Image("images/hud.xml", "craft_slot.tex"))
    self.bg_shadow:SetSize(520, 420)
    self.bg_shadow:SetPosition(5, -5)
    self.bg_shadow:SetTint(0, 0, 0, 0.5)
    
    -- Main wooden background
    self.bg = self.root:AddChild(Image("images/hud.xml", "craft_slot.tex"))
    self.bg:SetSize(500, 400)
    self.bg:SetTint(0.7, 0.7, 0.7, 1)
    
    -- Frame overlay for worn effect
    self.frame = self.root:AddChild(Image("images/hud.xml", "craft_slot.tex"))
    self.frame:SetSize(500, 400)
    self.frame:SetTint(0.4, 0.4, 0.4, 0.3)
    
    -- Title
    self.title = self.root:AddChild(Text(TITLEFONT, 30, "Quick Notes"))
    self.title:SetPosition(0, 160)
    self.title:SetColour(0.9, 0.8, 0.6, 1)  -- Warmer color for wooden theme
    
    -- Text Editor
    self.editor = self.root:AddChild(TextEdit(DEFAULTFONT, 25))
    self.editor:SetPosition(0, 0)
    self.editor:SetRegionSize(450, 300)
    self.editor:SetHAlign(ANCHOR_LEFT)
    self.editor:SetVAlign(ANCHOR_TOP)
    self.editor:EnableScrollEditWindow(true)
    self.editor:EnableWordWrap(true)
    self.editor:SetTextLengthLimit(10000)
    self.editor:SetColour(1, 1, 1, 1)
    self.editor:SetString("")
    self.editor.allow_newline = true
    
    -- Handle Enter key for line breaks
    function self.editor:OnRawKey(key, down)
        if down and (key == KEY_ENTER or key == KEY_KP_ENTER) then
            local text = self:GetString()
            self:SetString(text .. "\n")
            self:SetEditing(true)
            return true
        end
        return TextEdit.OnRawKey(self, key, down)
    end

    -- Setup focus handlers
    function self.editor:OnGainFocus()
        TextEdit.OnGainFocus(self)
        self:SetEditing(true)
        self:SetColour(1, 1, 1, 1)
    end
    
    function self.editor:OnLoseFocus()
        TextEdit.OnLoseFocus(self)
        self:SetColour(1, 1, 1, 1)
    end
    -- Save indicator
    self.save_indicator = self.root:AddChild(Text(DEFAULTFONT, 20, ""))
    self.save_indicator:SetPosition(0, -170)
    self.save_indicator:SetColour(0.5, 1, 0.5, 1)
    
    -- Close button
    self.close_btn = self.root:AddChild(ImageButton("images/global_redux.xml", "close.tex"))
    self.close_btn:SetPosition(230, 170)
    self.close_btn:SetScale(0.7)
    self.close_btn:SetOnClick(function() self:Close() end)
    
    -- Set default focus handler
    self.default_focus = self.editor
    
    -- Setup keyboard handlers
    self:SetupKeyboardHandlers()
    -- Load saved notes
    self:LoadNotes()
    print("NotepadWidget created successfully")
    self:Hide()

    -- Make title bar draggable
    self.title:SetClickable(true)
end)

function NotepadWidget:OnUpdate()
    if self.dragging and TheInput:IsMouseDown(MOUSEBUTTON_LEFT) then
        local mousepos = TheInput:GetScreenPosition()
        local dx = mousepos.x - self.drag_start_x
        local dy = mousepos.y - self.drag_start_y
        self.root:SetPosition(self.widget_start_x + dx, self.widget_start_y + dy)
    else
        self.dragging = false
    end
end

function NotepadWidget:OnMouseButton(button, down, x, y)
    if button == MOUSEBUTTON_LEFT then
        if down then
            -- Only start dragging if clicking on the title
            local title_pos = self.title:GetWorldPosition()
            local title_w, title_h = self.title:GetRegionSize()
            if math.abs(y - title_pos.y) <= title_h/2 then
                self.dragging = true
                local mousepos = TheInput:GetScreenPosition()
                self.drag_start_x = mousepos.x
                self.drag_start_y = mousepos.y
                local pos = self.root:GetPosition()
                self.widget_start_x = pos.x
                self.widget_start_y = pos.y
                return true
            end
        else
            self.dragging = false
        end
    end
    return NotepadWidget._base.OnMouseButton(self, button, down, x, y)
end

function NotepadWidget:SetupKeyboardHandlers()
    self.keyboard_handlers = {
        -- Ctrl+S to save
        [CONTROL_ACCEPT] = function()
            if TheInput:IsKeyDown(KEY_CTRL) then
                self:SaveNotes()
                return true
            end
        end,
        -- Escape to close
        [CONTROL_CANCEL] = function()
            self:Close()
            return true
        end
    }
end

function NotepadWidget:OnBecomeActive()
    print("NotepadWidget becoming active")
    NotepadWidget._base.OnBecomeActive(self)
    
    self:Show()
    self.isOpen = true
    self.root:ScaleTo(0, 1, .2)
    
    -- Cancel any existing focus task
    if self.focus_task then
        self.focus_task:Cancel()
        self.focus_task = nil
    end
    
    -- Set focus to the editor after a short delay
    self.focus_task = self.inst:DoTaskInTime(0.1, function()
        if self.editor then
            self.editor:SetFocus()
            -- Start auto-save timer
            self:StartAutoSave()
        end
        self.focus_task = nil
    end)
end

function NotepadWidget:OnBecomeInactive()
    print("NotepadWidget becoming inactive")
    NotepadWidget._base.OnBecomeInactive(self)
    self:Hide()
    self.isOpen = false
    self:StopAutoSave()
    self:SaveNotes() -- Save on close
    
    -- Cancel focus task if it exists
    if self.focus_task then
        self.focus_task:Cancel()
        self.focus_task = nil
    end
end

function NotepadWidget:StartAutoSave()
    self:StopAutoSave() -- Clean up any existing timer
    -- Auto-save every 30 seconds
    self.auto_save_timer = self.inst:DoPeriodicTask(30, function() 
        if self.editor and self.editor:GetString() then
            self:SaveNotes()
        end
    end)
end

function NotepadWidget:StopAutoSave()
    if self.auto_save_timer then
        self.auto_save_timer:Cancel()
        self.auto_save_timer = nil
    end
end

function NotepadWidget:Close()
    print("NotepadWidget closing")
    self:SaveNotes()
    self.isOpen = false
    if _G.TheFrontEnd:GetActiveScreen() == self then
        _G.TheFrontEnd:PopScreen(self)
    end
end

function NotepadWidget:SaveNotes()
    if not self.editor then return end
    local content = self.editor:GetString()
    if not content then return end
    
    TheSim:SetPersistentString("quicknotes", content, false)
    self:ShowSaveIndicator("Saved!")
end

function NotepadWidget:ShowSaveIndicator(message)
    if not self.save_indicator then return end
    
    -- Show save indicator briefly
    self.save_indicator:SetString(message or "")
    
    -- Cancel existing timer if any
    if self.save_timer then
        self.save_timer:Cancel()
        self.save_timer = nil
    end
    
    -- Create new timer
    self.save_timer = self.inst:DoTaskInTime(1, function() 
        if self.save_indicator then
            self.save_indicator:SetString("")
        end
        self.save_timer = nil
    end)
end

function NotepadWidget:LoadNotes()
    TheSim:GetPersistentString("quicknotes", function(success, content)
        if success and content and self.editor then
            self.editor:SetString(content)
        else
            print("Failed to load notes or no saved notes found")
            if self.editor then
                self.editor:SetString("")
            end
        end
    end)
end

function NotepadWidget:OnControl(control, down)
    if NotepadWidget._base.OnControl(self, control, down) then return true end
    
    if down and self.keyboard_handlers[control] then
        return self.keyboard_handlers[control]()
    end
    
    return false
end

function NotepadWidget:OnDestroy()
    self:StopAutoSave()
    
    if self.save_timer then
        self.save_timer:Cancel()
        self.save_timer = nil
    end
    
    if self.focus_task then
        self.focus_task:Cancel()
        self.focus_task = nil
    end
    
    if self.save_indicator then self.save_indicator:Kill() end
    if self.editor then self.editor:Kill() end
    if self.close_btn then self.close_btn:Kill() end
    if self.title then self.title:Kill() end
    if self.frame then self.frame:Kill() end
    if self.bg then self.bg:Kill() end
    
    NotepadWidget._base.OnDestroy(self)
end

return NotepadWidget 