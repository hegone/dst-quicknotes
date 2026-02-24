--[[
    Scratch Document (DST-4)

    Pure text model for the Scratch Editor MVP.

    Responsibilities (M1):
    - Maintain `lines: string[]` where each line contains NO trailing `\n`.
    - Apply text edits: insert / delete / replace.
    - Provide position helpers:
        - Position: { line = 1..N, col = 0..#line } (byte index; ASCII-only MVP)
        - Range: half-open [start, end)

    Non-goals:
    - Rendering, scrolling, width measurement, caret blinking, UI events.
]]

local Document = {}
Document.__index = Document

local function clamp(value, min_value, max_value)
    if value < min_value then return min_value end
    if value > max_value then return max_value end
    return value
end

local function compare_pos(a, b)
    if a.line < b.line then return -1 end
    if a.line > b.line then return 1 end
    if a.col < b.col then return -1 end
    if a.col > b.col then return 1 end
    return 0
end

local function normalize_newlines(text)
    if not text or text == "" then
        return ""
    end
    -- Normalize CRLF/CR to LF for stable line splitting.
    text = string.gsub(text, "\r\n", "\n")
    text = string.gsub(text, "\r", "\n")
    return text
end

local function split_by_line(text)
    if not text or text == "" then
        return { "" }
    end

    local lines = {}
    local start_i = 1

    for i = 1, #text do
        if string.sub(text, i, i) == "\n" then
            table.insert(lines, string.sub(text, start_i, i - 1))
            start_i = i + 1
        end
    end

    table.insert(lines, string.sub(text, start_i))
    if #lines == 0 then
        return { "" }
    end
    return lines
end

local function ensure_non_empty_lines(lines)
    if not lines or #lines == 0 then
        return { "" }
    end
    return lines
end

--[[
    Creates a new document from text.

    @param text (string|nil) Initial content
    @return (Document)
]]
function Document.new(text)
    local normalized = normalize_newlines(text)
    local self = setmetatable({}, Document)
    self.lines = ensure_non_empty_lines(split_by_line(normalized))
    return self
end

function Document:SetText(text)
    local normalized = normalize_newlines(text)
    self.lines = ensure_non_empty_lines(split_by_line(normalized))
end

function Document:GetText()
    return table.concat(self.lines, "\n")
end

function Document:GetLines()
    return self.lines
end

function Document:LineCount()
    return #self.lines
end

function Document:ClampPos(pos)
    local safe = pos or {}
    local line = clamp(tonumber(safe.line) or 1, 1, math.max(1, #self.lines))
    local line_text = self.lines[line] or ""
    local col = clamp(tonumber(safe.col) or 0, 0, #line_text)
    return { line = line, col = col }
end

function Document:NormalizeRange(a, b)
    local start_pos = self:ClampPos(a)
    local end_pos = self:ClampPos(b)
    if compare_pos(start_pos, end_pos) <= 0 then
        return start_pos, end_pos
    end
    return end_pos, start_pos
end

-- Total byte length of the joined text (including '\n' between lines).
function Document:Length()
    local total = 0
    for i = 1, #self.lines do
        total = total + #(self.lines[i] or "")
        if i < #self.lines then
            total = total + 1
        end
    end
    return total
end

function Document:PosToIndex(pos)
    local p = self:ClampPos(pos)
    local idx = 0
    for i = 1, p.line - 1 do
        idx = idx + #(self.lines[i] or "") + 1
    end
    idx = idx + p.col
    return idx
end

function Document:IndexToPos(index)
    local idx = clamp(tonumber(index) or 0, 0, self:Length())

    for i = 1, #self.lines do
        local line_len = #(self.lines[i] or "")
        if idx <= line_len then
            return { line = i, col = idx }
        end

        idx = idx - line_len
        if i < #self.lines then
            -- Skip the newline separator between lines.
            idx = idx - 1
        end
    end

    local last = #self.lines
    local last_text = self.lines[last] or ""
    return { line = last, col = #last_text }
end

function Document:PrevPos(pos)
    local p = self:ClampPos(pos)
    if p.col > 0 then
        return { line = p.line, col = p.col - 1 }
    end
    if p.line > 1 then
        local prev_line_text = self.lines[p.line - 1] or ""
        return { line = p.line - 1, col = #prev_line_text }
    end
    return nil
end

function Document:NextPos(pos)
    local p = self:ClampPos(pos)
    local line_text = self.lines[p.line] or ""
    if p.col < #line_text then
        return { line = p.line, col = p.col + 1 }
    end
    if p.line < #self.lines then
        return { line = p.line + 1, col = 0 }
    end
    return nil
end

--[[
    Inserts text at `pos` and returns the updated caret position (end of inserted text).
]]
function Document:Insert(pos, text)
    local p = self:ClampPos(pos)
    local insert_text = normalize_newlines(text)
    if insert_text == "" then
        return p
    end

    local parts = split_by_line(insert_text)
    local current = self.lines[p.line] or ""
    local before = string.sub(current, 1, p.col)
    local after = string.sub(current, p.col + 1)

    if #parts == 1 then
        self.lines[p.line] = before .. parts[1] .. after
        return { line = p.line, col = p.col + #parts[1] }
    end

    local new_lines = {}

    for i = 1, p.line - 1 do
        new_lines[#new_lines + 1] = self.lines[i]
    end

    new_lines[#new_lines + 1] = before .. parts[1]
    for i = 2, #parts - 1 do
        new_lines[#new_lines + 1] = parts[i]
    end
    new_lines[#new_lines + 1] = parts[#parts] .. after

    for i = p.line + 1, #self.lines do
        new_lines[#new_lines + 1] = self.lines[i]
    end

    self.lines = ensure_non_empty_lines(new_lines)
    return { line = p.line + (#parts - 1), col = #parts[#parts] }
end

--[[
    Deletes the half-open range [start_pos, end_pos) and returns the updated caret position.
]]
function Document:DeleteRange(start_pos, end_pos)
    local start_p, end_p = self:NormalizeRange(start_pos, end_pos)
    if compare_pos(start_p, end_p) == 0 then
        return start_p
    end

    if start_p.line == end_p.line then
        local line_text = self.lines[start_p.line] or ""
        local before = string.sub(line_text, 1, start_p.col)
        local after = string.sub(line_text, end_p.col + 1)
        self.lines[start_p.line] = before .. after
        self.lines = ensure_non_empty_lines(self.lines)
        return self:ClampPos(start_p)
    end

    local start_text = self.lines[start_p.line] or ""
    local end_text = self.lines[end_p.line] or ""
    local before = string.sub(start_text, 1, start_p.col)
    local after = string.sub(end_text, end_p.col + 1)
    local merged = before .. after

    local new_lines = {}
    for i = 1, start_p.line - 1 do
        new_lines[#new_lines + 1] = self.lines[i]
    end
    new_lines[#new_lines + 1] = merged
    for i = end_p.line + 1, #self.lines do
        new_lines[#new_lines + 1] = self.lines[i]
    end

    self.lines = ensure_non_empty_lines(new_lines)
    return self:ClampPos(start_p)
end

--[[
    Replaces the half-open range [start_pos, end_pos) with `text`.
    This is the canonical path for “selection delete/replace”.
]]
function Document:ReplaceRange(start_pos, end_pos, text)
    local start_p, end_p = self:NormalizeRange(start_pos, end_pos)
    local insert_at = self:DeleteRange(start_p, end_p)
    return self:Insert(insert_at, text)
end

function Document:Backspace(pos)
    local p = self:ClampPos(pos)
    local prev = self:PrevPos(p)
    if not prev then
        return p
    end
    return self:DeleteRange(prev, p)
end

function Document:Delete(pos)
    local p = self:ClampPos(pos)
    local next_p = self:NextPos(p)
    if not next_p then
        return p
    end
    return self:DeleteRange(p, next_p)
end

-- Minimal, local-only self-check runner (no DST dependencies).
function Document._selfcheck()
    local function assert_eq(actual, expected, label)
        if actual ~= expected then
            error(string.format("%s: expected %q, got %q", label or "assert_eq", tostring(expected), tostring(actual)))
        end
    end

    local function assert_pos_eq(actual, expected, label)
        assert_eq(actual.line, expected.line, (label or "pos") .. ".line")
        assert_eq(actual.col, expected.col, (label or "pos") .. ".col")
    end

    local function run(name, fn)
        local ok, err = pcall(fn)
        if not ok then
            error(string.format("selfcheck failed: %s: %s", name, tostring(err)))
        end
    end

    run("empty delete no-op", function()
        local doc = Document.new("")
        local pos = doc:Delete({ line = 1, col = 0 })
        assert_eq(doc:GetText(), "", "text")
        assert_pos_eq(pos, { line = 1, col = 0 }, "caret")
    end)

    run("backspace merge", function()
        local doc = Document.new("a\nb")
        local pos = doc:Backspace({ line = 2, col = 0 })
        assert_eq(doc:GetText(), "ab", "text")
        assert_pos_eq(pos, { line = 1, col = 1 }, "caret")
    end)

    run("delete merge", function()
        local doc = Document.new("a\nb")
        local pos = doc:Delete({ line = 1, col = 1 })
        assert_eq(doc:GetText(), "ab", "text")
        assert_pos_eq(pos, { line = 1, col = 1 }, "caret")
    end)

    run("multiline selection delete join", function()
        local doc = Document.new("abc\ndef\nghi")
        local pos = doc:DeleteRange({ line = 1, col = 1 }, { line = 3, col = 2 })
        assert_eq(doc:GetText(), "ai", "text")
        assert_pos_eq(pos, { line = 1, col = 1 }, "caret")
    end)

    run("insert newline split", function()
        local doc = Document.new("ab")
        local pos = doc:Insert({ line = 1, col = 1 }, "X\nY")
        assert_eq(doc:GetText(), "aX\nYb", "text")
        assert_pos_eq(pos, { line = 2, col = 1 }, "caret")
    end)

    run("replace stable w/ trailing newline", function()
        local doc = Document.new("abc")
        local pos = doc:ReplaceRange({ line = 1, col = 1 }, { line = 1, col = 2 }, "Z\n")
        assert_eq(doc:GetText(), "aZ\nc", "text")
        assert_pos_eq(pos, { line = 2, col = 0 }, "caret")
    end)

    run("pos<->index conversion", function()
        local doc = Document.new("a\nbc")
        local idx = doc:PosToIndex({ line = 2, col = 1 })
        assert_eq(idx, 3, "index")
        local pos = doc:IndexToPos(idx)
        assert_pos_eq(pos, { line = 2, col = 1 }, "pos")
    end)

    run("CRLF normalization on insert", function()
        local doc = Document.new("")
        local pos = doc:Insert({ line = 1, col = 0 }, "a\r\nb\rc")
        assert_eq(doc:GetText(), "a\nb\nc", "text")
        assert_pos_eq(pos, { line = 3, col = 1 }, "caret")
    end)

    return true
end

return Document

