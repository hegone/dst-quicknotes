local Widget = require "widgets/widget"
local Text = require "widgets/text"
local Image = require "widgets/image"

local CustomTextEditor = Class(Widget, function(self, width)
    Widget._ctor(self, "CustomTextEditor")
    
    self.width = width or 300  -- width of the editor region (for reference)
    self.height = 300  -- default height
    self.font = DEFAULTFONT
    self.font_size = 25
    
    -- Internal state
    self.buffer = ""       -- The text string
    self.cursor_pos = 0    -- 0 means before the first character; if buffer="abc" and cursor_pos=1, cursor is between 'a' and 'b'.
    self.max_length = 10000  -- Default max length
    
    -- Display elements
    self.bg = self:AddChild(Image("images/global.xml", "square.tex"))
    self.bg:SetSize(self.width, 300)  -- Increased height to match notepad
    self.bg:SetTint(0.2, 0.2, 0.2, 1)
    self.bg:SetClickable(true)  -- Make background clickable to receive focus
    
    self.text = self:AddChild(Text(self.font, self.font_size))
    self.text:SetPosition(-self.width/2 + 10, 0)  -- Left align text
    self.text:SetColour(1, 1, 1, 1)  -- Default white text
    self.text:SetRegionSize(self.width - 20, self.height) -- Set text region size with padding
    self.text:EnableWordWrap(true) -- Enable word wrapping
    if self.text.EnableWhitespaceWrap then  -- Check if the method exists
        self.text:EnableWhitespaceWrap(true)  -- Enable whitespace wrapping for better handling of long words
    end
    
    -- Cursor displayed as a pipe '|'
    self.cursor = self:AddChild(Text(self.font, self.font_size))
    self.cursor:SetString("|")
    self.cursor:SetColour(1, 1, 1, 1)
    self:RefreshDisplay()
end)

-- Update the displayed text and move the cursor visually.
function CustomTextEditor:RefreshDisplay()
    self.text:SetString(self.buffer)
    
    -- Measure text up to cursor_pos
    local left_text = string.sub(self.buffer, 1, self.cursor_pos)
    
    -- Ensure text stays within bounds
    local max_width = self.width - 20  -- Account for padding
    local w, h = self.text:GetRegionSize()
    
    -- To measure cursor position, temporarily set the text to left_text, measure width, then revert
    local original = self.text:GetString()
    self.text:SetString(left_text)
    local cursor_w, _ = self.text:GetRegionSize()
    self.text:SetString(original)
    
    -- Position the cursor, ensuring it stays within bounds
    local start_x = -self.width/2 + 10  -- starting X for text
    local cursor_x = math.min(start_x + cursor_w + 2, start_x + max_width - 10)
    self.cursor:SetPosition(cursor_x, 0)
end

function CustomTextEditor:OnGainFocus()
    Widget.OnGainFocus(self)
    -- Keep text white on focus
    self:SetColour(1, 1, 1, 1)
end

function CustomTextEditor:OnLoseFocus()
    Widget.OnLoseFocus(self)
    -- Keep text white when not focused
    self:SetColour(1, 1, 1, 1)
end
-- Handle character input
function CustomTextEditor:OnTextInput(ch)
    if ch == "\n" or ch == "\r" then
        -- For now, ignore Enter or handle differently
        return true
    end

    -- Check max length before inserting
    if #self.buffer >= self.max_length then
        return true
    end

    -- Insert the character since we have word wrap enabled
    local new_text = string.sub(self.buffer, 1, self.cursor_pos) .. ch .. string.sub(self.buffer, self.cursor_pos + 1)
    self.buffer = new_text
    self.cursor_pos = self.cursor_pos + 1
    self:RefreshDisplay()

    return true
end

-- Handle special keys
function CustomTextEditor:OnRawKey(key, down)
    if not down then return false end

    if key == KEY_BACKSPACE then
        if self.cursor_pos > 0 then
            -- Remove the character before the cursor
            self.buffer = string.sub(self.buffer, 1, self.cursor_pos - 1) .. string.sub(self.buffer, self.cursor_pos + 1)
            self.cursor_pos = self.cursor_pos - 1
            self:RefreshDisplay()
        end
        return true
    elseif key == KEY_LEFT then
        if self.cursor_pos > 0 then
            self.cursor_pos = self.cursor_pos - 1
            self:RefreshDisplay()
        end
        return true
    elseif key == KEY_RIGHT then
        if self.cursor_pos < #self.buffer then
            self.cursor_pos = self.cursor_pos + 1
            self:RefreshDisplay()
        end
        return true
    end

    return false
end

-- Add compatibility methods for NotepadWidget
function CustomTextEditor:GetString()
    return self.buffer
end

function CustomTextEditor:SetString(str)
    self.buffer = str or ""
    self.cursor_pos = #self.buffer  -- Place cursor at end
    self:RefreshDisplay()
end

function CustomTextEditor:SetTextLengthLimit(limit)
    self.max_length = limit
end

function CustomTextEditor:SetColour(r, g, b, a)
    self.text:SetColour(r, g, b, a)
    -- Keep cursor white for visibility
    self.cursor:SetColour(1, 1, 1, 1)
end

function CustomTextEditor:SetRegionSize(w, h)
    self.width = w
    self.height = h
    self.bg:SetSize(w, h)
    -- Update text widget's region size with padding
    self.text:SetRegionSize(w - 20, h)
    -- Maintain left alignment with new width
    self.text:SetPosition(-w/2 + 10, 0)
    -- Enable both word wrap and whitespace wrap for better text containment
    self.text:EnableWordWrap(true)
    if self.text.EnableWhitespaceWrap then  -- Check if the method exists
        self.text:EnableWhitespaceWrap(true)
    end
    self:RefreshDisplay()
end

return CustomTextEditor
