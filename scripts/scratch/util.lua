--[[
    Scratch Editor Utilities

    Minimal helpers for the Scratch Editor MVP that do NOT depend on TextEdit/TextEditWidget.
    This module is intentionally small and only contains logic needed for M0 debug/HUD.
]]

local Text = require "widgets/text"

local ScratchUtil = {}

function ScratchUtil.Clamp(value, min_value, max_value)
    if value < min_value then
        return min_value
    end
    if value > max_value then
        return max_value
    end
    return value
end

function ScratchUtil.SplitByLine(text)
    if not text or text == "" then
        return {""}
    end

    local lines = {}
    local current_line = ""

    for char in text:gmatch(".") do
        if char == "\n" then
            table.insert(lines, current_line)
            current_line = ""
        else
            current_line = current_line .. char
        end
    end

    table.insert(lines, current_line)
    return lines
end

function ScratchUtil.MeasureTextWidth(measurer_widget, str, font, font_size)
    if not measurer_widget then
        return 0
    end

    font = font or DEFAULTFONT
    font_size = font_size or 25

    local measuring_text = measurer_widget:AddChild(Text(font, font_size))
    local width = 0

    local status, err = pcall(function()
        measuring_text:SetString(str or "")
        width = measuring_text:GetRegionSize()
    end)

    if measuring_text then
        measuring_text:Kill()
    end

    if not status then
        print("[Quick Notes] Scratch MeasureTextWidth error:", err)
        return 0
    end

    return width or 0
end

function ScratchUtil.MeasureLineHeight(measurer_widget, font, font_size)
    if not measurer_widget then
        return font_size or 25
    end

    font = font or DEFAULTFONT
    font_size = font_size or 25

    local measuring_text = measurer_widget:AddChild(Text(font, font_size))
    local height = 0

    local status, err = pcall(function()
        measuring_text:SetString("Ag")
        local _, h = measuring_text:GetRegionSize()
        height = h or 0
    end)

    if measuring_text then
        measuring_text:Kill()
    end

    if not status then
        print("[Quick Notes] Scratch MeasureLineHeight error:", err)
        return font_size
    end

    if height <= 0 then
        return font_size
    end

    return height
end

return ScratchUtil
