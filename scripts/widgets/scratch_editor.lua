--[[
    Scratch Editor (MVP - M0)

    A minimal, flag-gated editor stub for the Scratch Editor MVP.
    Non-goals for M0:
    - Real text rendering
    - Keyboard editing
    - Selection UI
    - Scrolling / scrollbar

    Goals for M0:
    - Safe integration behind USE_SCRATCH_EDITOR=false by default
    - A focusable "KeyboardSink" widget (ImageButton) as `self.editor`
    - Debug HUD (DebugOverlay) when DEBUG_EDITOR=true:
        caret, selection range, viewport info, and click hit test (row/vline/col)
]]

local Widget = require "widgets/widget"
local Image = require "widgets/image"

local Config = require "notepad/config"
local ScratchUtil = require "scratch/util"
local ScratchDebugOverlay = require "widgets/scratch_debug_overlay"

local ScratchEditor = Class(Widget, function(self, width, height, font, font_size)
    Widget._ctor(self, "ScratchEditor")

    self.width = width or 450
    self.height = height or 300
    self.font = font or DEFAULTFONT
    self.font_size = font_size or 25

    self.text = ""
    self.lines = {""}

    -- Minimal debug state model (M0)
    self.caret = { line = 1, col = 0 }
    self.selection = {
        anchor = { line = 1, col = 0 },
        active = { line = 1, col = 0 },
    }
    self.viewport = {
        top_vline = 1,
        visible_lines = 1,
        total_lines = 1,
    }
    self.last_hit = nil

    -- Off-tree measurer widget (killed explicitly in :Kill()).
    self.measurer = Widget("ScratchMeasurer")
    self.line_height = ScratchUtil.MeasureLineHeight(self.measurer, self.font, self.font_size)

    -- Keyboard sink + hit test surface
    -- Note: ImageButton does not expose SetSize reliably across DST builds.
    -- Use a clickable transparent Image instead.
    self.editor = self:AddChild(Image("images/global.xml", "square.tex"))
    self.editor:SetSize(self.width, self.height)
    self.editor:SetPosition(0, 0)
    self.editor:SetTint(0, 0, 0, 0)
    self.editor:SetClickable(true)

    -- Route mouse clicks to our hit test.
    self.editor.OnMouseButton = function(_, button, down, x, y)
        return self:OnMouseButton(button, down, x, y)
    end

    -- Debug overlay (hidden by default)
    self.debug_overlay = self:AddChild(ScratchDebugOverlay(DEFAULTFONT, 16))
    self.debug_overlay:SetPosition(-self.width / 2 + 6, self.height / 2 - 6)
    self.debug_overlay:Hide()

    self:Refresh()
end)

function ScratchEditor:GetText()
    return self.text
end

function ScratchEditor:SetText(text)
    self.text = text or ""
    self.lines = ScratchUtil.SplitByLine(self.text)
    if #self.lines == 0 then
        self.lines = {""}
    end

    -- Clamp caret into the new document.
    self.caret.line = ScratchUtil.Clamp(self.caret.line or 1, 1, #self.lines)
    local line_text = self.lines[self.caret.line] or ""
    self.caret.col = ScratchUtil.Clamp(self.caret.col or 0, 0, #line_text)

    -- For M0, selection is always collapsed to caret.
    self.selection.anchor = { line = self.caret.line, col = self.caret.col }
    self.selection.active = { line = self.caret.line, col = self.caret.col }

    self:Refresh()
end

function ScratchEditor:SetFocus()
    if self.editor and self.editor.SetFocus then
        self.editor:SetFocus()
        return
    end
    if ScratchEditor._base and ScratchEditor._base.SetFocus then
        ScratchEditor._base.SetFocus(self)
    end
end

function ScratchEditor:Kill()
    if self.measurer then
        self.measurer:Kill()
        self.measurer = nil
    end
    ScratchEditor._base.Kill(self)
end

function ScratchEditor:Refresh()
    local safe_line_height = math.max(1, self.line_height or self.font_size or 25)

    self.viewport.visible_lines = math.max(1, math.floor(self.height / safe_line_height))
    self.viewport.total_lines = math.max(1, #self.lines)
    self.viewport.top_vline = ScratchUtil.Clamp(self.viewport.top_vline or 1, 1, self.viewport.total_lines)

    if not (Config.DEBUG_EDITOR and self.debug_overlay) then
        if self.debug_overlay then
            self.debug_overlay:Hide()
        end
        return
    end

    self.debug_overlay:Show()

    local sel = self.selection or {}
    local anchor = sel.anchor or {}
    local active = sel.active or {}

    local hit_str = "-"
    if self.last_hit then
        hit_str = string.format(
            "%d/%d/%d",
            self.last_hit.row or -1,
            self.last_hit.vline or -1,
            self.last_hit.col or -1
        )
    end

    local debug_str = string.format(
        "caret: L%d C%d | sel: %d:%d->%d:%d | viewport: top %d vis %d total %d | hit: %s",
        self.caret.line or 1,
        self.caret.col or 0,
        anchor.line or 1,
        anchor.col or 0,
        active.line or 1,
        active.col or 0,
        self.viewport.top_vline or 1,
        self.viewport.visible_lines or 1,
        self.viewport.total_lines or 1,
        hit_str
    )

    self.debug_overlay:SetDebugString(debug_str)
end

function ScratchEditor:FindColByX(line_text, local_x)
    local line = line_text or ""
    if line == "" then
        return 0
    end

    local x = math.max(0, local_x or 0)
    local low = 0
    local high = #line

    while low < high do
        local mid = math.floor((low + high + 1) / 2)
        local substr = string.sub(line, 1, mid)
        local width = ScratchUtil.MeasureTextWidth(self.measurer, substr, self.font, self.font_size)

        if width <= x then
            low = mid
        else
            high = mid - 1
        end
    end

    return low
end

function ScratchEditor:OnMouseButton(button, down, x, y)
    if button ~= MOUSEBUTTON_LEFT or not down then
        return false
    end

    if not (self.editor and self.editor.GetWorldPosition) then
        return false
    end

    local pos = self.editor:GetWorldPosition()
    local cx = pos.x or 0
    local cy = pos.y or 0

    local half_w = self.width / 2
    local half_h = self.height / 2

    -- Bounds check in screen coordinates.
    if x < (cx - half_w) or x > (cx + half_w) or y < (cy - half_h) or y > (cy + half_h) then
        return false
    end

    local left = cx - half_w
    local top = cy + half_h
    local local_x = x - left
    local local_y_from_top = top - y

    local safe_line_height = math.max(1, self.line_height or self.font_size or 25)
    local row = math.floor(local_y_from_top / safe_line_height)
    row = ScratchUtil.Clamp(row, 0, math.max(0, (self.viewport.visible_lines or 1) - 1))

    local vline = (self.viewport.top_vline or 1) + row
    local line_index = ScratchUtil.Clamp(vline, 1, math.max(1, #self.lines))

    local line_text = self.lines[line_index] or ""
    local col = self:FindColByX(line_text, local_x)

    self.caret = { line = line_index, col = col }
    self.selection.anchor = { line = line_index, col = col }
    self.selection.active = { line = line_index, col = col }
    self.last_hit = { row = row, vline = vline, col = col }

    self:SetFocus()
    self:Refresh()
    return true
end

return ScratchEditor
