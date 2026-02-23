--[[
    Scratch Debug Overlay Widget

    Displays live debug information for the Scratch Editor when DEBUG_EDITOR is enabled.
    This widget is intentionally minimal: a single Text widget whose string is updated
    from ScratchEditor:Refresh().
]]

local Widget = require "widgets/widget"
local Text = require "widgets/text"

local ScratchDebugOverlay = Class(Widget, function(self, font, size)
    Widget._ctor(self, "ScratchDebugOverlay")

    self.text = self:AddChild(Text(font or DEFAULTFONT, size or 16, ""))

    -- Align top-left when supported by the underlying widget.
    if self.text.SetHAlign then
        self.text:SetHAlign(ANCHOR_LEFT)
    end
    if self.text.SetVAlign then
        self.text:SetVAlign(ANCHOR_TOP)
    end

    -- Light green/white for visibility on dark backgrounds.
    self.text:SetColour(0.9, 1.0, 0.9, 1.0)
end)

function ScratchDebugOverlay:SetHidden(hidden)
    if hidden then
        self:Hide()
    else
        self:Show()
    end
end

function ScratchDebugOverlay:SetDebugString(str)
    if self.text then
        self.text:SetString(str or "")
    end
end

return ScratchDebugOverlay
