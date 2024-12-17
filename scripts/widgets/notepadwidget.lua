local Screen = require "widgets/screen"
local Widget = require "widgets/widget"
local TextEdit = require "widgets/textedit"
local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local Text = require "widgets/text"

local NotepadWidget = Class(Screen, function(self)
    Screen._ctor(self, "NotepadWidget")
    print("Creating NotepadWidget")
    
    if not _G.ThePlayer or not _G.ThePlayer.HUD then
        print("Warning: Attempting to create NotepadWidget before player initialization")
        return
    end
    
    self.isOpen = false
    
    -- Root widget
    self.root = self:AddChild(Widget("ROOT"))
    self.root:SetVAnchor(ANCHOR_MIDDLE)
    self.root:SetHAnchor(ANCHOR_MIDDLE)
    self.root:SetPosition(0, 0)
    self.root:SetScale(1)
    
    -- Background panel
    self.bg = self.root:AddChild(Image("images/global.xml", "square.tex"))
    self.bg:SetSize(500, 400)
    self.bg:SetTint(0, 0, 0, 0.8)
    
    -- Add a frame
    self.frame = self.root:AddChild(Image("images/global.xml", "square.tex"))
    self.frame:SetSize(510, 410)
    self.frame:SetTint(0.6, 0.6, 0.6, 0.6)
    self.frame:MoveToBack()
    
    -- Title
    self.title = self.root:AddChild(Text(TITLEFONT, 30, "Quick Notes"))
    self.title:SetPosition(0, 170)
    
    -- Text editor
    self.editor = self.root:AddChild(TextEdit(DEFAULTFONT, 25))
    self.editor:SetPosition(0, 0)
    self.editor:SetRegionSize(450, 300)
    self.editor:SetHAlign(ANCHOR_LEFT)
    self.editor:SetVAlign(ANCHOR_TOP)
    self.editor:EnableScrollEditWindow(true)
    self.editor:SetString("")
    self.editor:SetForceEdit(true)
    
    -- Close button
    self.close_btn = self.root:AddChild(ImageButton("images/global_redux.xml", "close.tex"))
    self.close_btn:SetPosition(230, 170)
    self.close_btn:SetScale(0.7)
    self.close_btn:SetOnClick(function() self:Close() end)
    
    -- Add a save indicator
    self.save_indicator = self.root:AddChild(Text(DEFAULTFONT, 20, ""))
    self.save_indicator:SetPosition(0, -170)
    
    -- Load saved notes
    self:LoadNotes()
    
    -- Save notes when edited with debounce
    self.save_timeout = nil
    self.editor.OnTextInput = function()
        if self.save_timeout then
            self.save_timeout:Cancel()
        end
        self.save_timeout = self.inst:DoTaskInTime(1, function()
            self:SaveNotes()
            self.save_indicator:SetString("Saved!")
            self.inst:DoTaskInTime(2, function()
                self.save_indicator:SetString("")
            end)
        end)
    end
    
    print("NotepadWidget created successfully")
    self:Hide() -- Start hidden
end)

function NotepadWidget:OnBecomeActive()
    print("NotepadWidget becoming active")
    NotepadWidget._base.OnBecomeActive(self)
    self:Show()
    self.isOpen = true
    self.root:ScaleTo(0, 1, .2)
end

function NotepadWidget:OnBecomeInactive()
    print("NotepadWidget becoming inactive")
    NotepadWidget._base.OnBecomeInactive(self)
    self:Hide()
    self.isOpen = false
end

function NotepadWidget:Close()
    print("NotepadWidget closing")
    self:SaveNotes()
    _G.TheFrontEnd:PopScreen(self)
end

function NotepadWidget:SaveNotes()
    local content = self.editor:GetString()
    TheSim:SetPersistentString("quicknotes", content, false)
end

function NotepadWidget:LoadNotes()
    TheSim:GetPersistentString("quicknotes", function(success, content)
        if success and content then
            self.editor:SetString(content)
        end
    end)
end

return NotepadWidget 