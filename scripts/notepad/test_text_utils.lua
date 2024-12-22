--[[
    Test Module for Text Utilities
    Tests the automatic line breaking and text manipulation functionality
]]

local TextUtils = require("notepad/text_utils")
local config = require("notepad/config")

-- Mock Text widget for testing
local MockText = Class(function(self, font, size)
    self.font = font
    self.size = size
    self.str = ""
end)

function MockText:SetString(str)
    self.str = str
end

function MockText:GetRegionSize()
    -- Simulate text width based on string length
    -- This is a simplified simulation for testing
    return #self.str * 10, 20
end

function MockText:Kill()
    -- Cleanup simulation
end

-- Mock TextEdit widget for testing
local MockEditor = Class(function(self)
    self.text = ""
    self.cursor_pos = 0
    self.editing = false
end)

function MockEditor:GetString()
    return self.text
end

function MockEditor:SetString(text)
    self.text = text
end

function MockEditor:SetEditing(state)
    self.editing = state
end

function MockEditor:SetEditCursorPos(pos)
    self.cursor_pos = pos
end

-- Test cases
local function RunTests()
    print("Starting Text Utils Tests...")
    
    local utils = TextUtils()
    local test_config = {
        SETTINGS = {
            MAX_LINE_WIDTH = 50,  -- Small width for testing
            TEXT_LENGTH_LIMIT = 1000
        },
        FONT_SIZES = {
            EDITOR = 25
        }
    }
    
    -- Test 1: Basic word wrapping
    print("\nTest 1: Basic word wrapping")
    local editor = MockEditor()
    utils:HandleTextInput(editor, "This is a very long line that should be wrapped automatically", test_config)
    print("Result:", editor.text)
    print("Expected multiple lines with breaks at spaces")
    
    -- Test 2: Long word handling
    print("\nTest 2: Long word handling")
    editor = MockEditor()
    utils:HandleTextInput(editor, "Supercalifragilisticexpialidocious", test_config)
    print("Result:", editor.text)
    print("Expected word to be broken into parts")
    
    -- Test 3: Empty input handling
    print("\nTest 3: Empty input handling")
    editor = MockEditor()
    local result = utils:HandleTextInput(editor, "", test_config)
    print("Result:", result)
    print("Expected false")
    
    -- Test 4: Line splitting
    print("\nTest 4: Line splitting")
    local lines = utils:SplitByLine("Line 1\nLine 2\nLine 3")
    print("Number of lines:", #lines)
    print("Expected 3 lines")
    
    -- Test 5: Space finding
    print("\nTest 5: Space finding")
    local space_index = utils:FindNearestSpace("word1 word2")
    print("Space index:", space_index)
    print("Expected index between words")
    
    print("\nTests completed!")
end

-- Run the tests
RunTests() 