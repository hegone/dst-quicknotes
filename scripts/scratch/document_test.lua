--[[
    Scratch Document Self-Test (DST-4)

    Runs a small, DST-independent test suite for `scratch/document.lua`.
    Intended to be executed locally via:
        luajit scripts/scratch/document_test.lua
]]

package.path = "./scripts/?.lua;" .. package.path

local function assert_eq(actual, expected, label)
    if actual ~= expected then
        error(string.format("%s: expected %q, got %q", label or "assert_eq", tostring(expected), tostring(actual)))
    end
end

local function assert_pos_eq(actual, expected, label)
    assert_eq(actual.line, expected.line, (label or "pos") .. ".line")
    assert_eq(actual.col, expected.col, (label or "pos") .. ".col")
end

local function test(name, fn)
    local ok, err = pcall(fn)
    if ok then
        io.write("[PASS] ", name, "\n")
        return true
    end
    io.write("[FAIL] ", name, "\n", tostring(err), "\n")
    return false
end

local Document = require "scratch/document"

local passed = true

passed = test("empty document delete is no-op", function()
    local doc = Document.new("")
    local pos = doc:Delete({ line = 1, col = 0 })
    assert_eq(doc:GetText(), "", "text")
    assert_pos_eq(pos, { line = 1, col = 0 }, "caret")
end) and passed

passed = test("backspace at col 0 merges with previous line", function()
    local doc = Document.new("a\nb")
    local pos = doc:Backspace({ line = 2, col = 0 })
    assert_eq(doc:GetText(), "ab", "text")
    assert_pos_eq(pos, { line = 1, col = 1 }, "caret")
end) and passed

passed = test("delete at line end merges with next line", function()
    local doc = Document.new("a\nb")
    local pos = doc:Delete({ line = 1, col = 1 })
    assert_eq(doc:GetText(), "ab", "text")
    assert_pos_eq(pos, { line = 1, col = 1 }, "caret")
end) and passed

passed = test("multiline selection delete removes middle lines and joins ends", function()
    local doc = Document.new("abc\ndef\nghi")
    local pos = doc:DeleteRange({ line = 1, col = 1 }, { line = 3, col = 2 })
    assert_eq(doc:GetText(), "ai", "text")
    assert_pos_eq(pos, { line = 1, col = 1 }, "caret")
end) and passed

passed = test("insert with newline splits lines", function()
    local doc = Document.new("ab")
    local pos = doc:Insert({ line = 1, col = 1 }, "X\nY")
    assert_eq(doc:GetText(), "aX\nYb", "text")
    assert_pos_eq(pos, { line = 2, col = 1 }, "caret")
end) and passed

passed = test("replace range is stable for any input (example with trailing newline)", function()
    local doc = Document.new("abc")
    local pos = doc:ReplaceRange({ line = 1, col = 1 }, { line = 1, col = 2 }, "Z\n")
    assert_eq(doc:GetText(), "aZ\nc", "text")
    assert_pos_eq(pos, { line = 2, col = 0 }, "caret")
end) and passed

passed = test("pos <-> index conversion matches joined text indices", function()
    local doc = Document.new("a\nbc")
    local idx = doc:PosToIndex({ line = 2, col = 1 })
    assert_eq(idx, 3, "index")
    local pos = doc:IndexToPos(idx)
    assert_pos_eq(pos, { line = 2, col = 1 }, "pos")
end) and passed

passed = test("insert normalizes CRLF and CR to LF", function()
    local doc = Document.new("")
    local pos = doc:Insert({ line = 1, col = 0 }, "a\r\nb\rc")
    assert_eq(doc:GetText(), "a\nb\nc", "text")
    assert_pos_eq(pos, { line = 3, col = 1 }, "caret")
end) and passed

if not passed then
    os.exit(1)
end

