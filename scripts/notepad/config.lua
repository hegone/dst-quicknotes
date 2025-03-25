--[[
    Configuration Module for DST Quick Notes
    
    This module centralizes all configuration constants used throughout the notepad mod.
    It includes settings for visual elements (dimensions, colors, fonts) and behavior
    (autosave timing, text limits). Centralizing these values makes the mod easier to
    maintain and modify.

    Usage:
        local config = require("notepad/config")
        local editor_width = config.DIMENSIONS.EDITOR.WIDTH
]]

-- Configuration will be set by modmain.lua
local TEXT_COLOR = "WHITE"
local BG_COLOR = "DARK" 
local BG_OPACITY = 0.7

-- Color mapping tables for user-selected colors
local TEXT_COLOR_MAP = {
    WHITE = { r = 1, g = 1, b = 1, a = 1 },
    YELLOW = { r = 1, g = 0.9, b = 0.5, a = 1 },
    LIGHT_BLUE = { r = 0.6, g = 0.8, b = 1, a = 1 },
    LIGHT_GREEN = { r = 0.6, g = 1, b = 0.6, a = 1 },
    PINK = { r = 1, g = 0.7, b = 0.9, a = 1 }
}

local BG_COLOR_MAP = {
    DARK = { r = 0.1, g = 0.1, b = 0.1 },
    BROWN = { r = 0.25, g = 0.15, b = 0.1 },
    GREY = { r = 0.2, g = 0.2, b = 0.23 },
    BLUE = { r = 0.1, g = 0.1, b = 0.25 },
    GREEN = { r = 0.1, g = 0.2, b = 0.15 },
    PINK = { r = 0.3, g = 0.1, b = 0.2 }
}

-- Get colors from the user settings
local function GetUserTextColor()
    return TEXT_COLOR_MAP[TEXT_COLOR] or TEXT_COLOR_MAP.WHITE
end

local function GetUserBgColor()
    local color = BG_COLOR_MAP[BG_COLOR] or BG_COLOR_MAP.DARK
    return { r = color.r, g = color.g, b = color.b, a = BG_OPACITY }
end

-- Font sizes for different UI elements
-- All sizes are in game units
local FONT_SIZES = {
    TITLE = 30,           -- Title bar text size
    EDITOR = 25,          -- Main editor text size
    SAVE_INDICATOR = 20   -- Size of the "Saved" indicator text
}

-- Widget dimensions for all UI components
-- All dimensions are in game units
local DIMENSIONS = {
    SHADOW = {
        WIDTH = 520,      -- Outer shadow width
        HEIGHT = 420      -- Outer shadow height
    },
    BACKGROUND = {
        WIDTH = 500,      -- Main background panel width
        HEIGHT = 400      -- Main background panel height
    },
    FRAME = {
        WIDTH = 510,      -- Decorative frame width
        HEIGHT = 410      -- Decorative frame height
    },
    TITLE_BAR = {
        WIDTH = 510,      -- Title bar width (matches frame)
        HEIGHT = 45       -- Title bar height
    },
    EDITOR = {
        WIDTH = 450,      -- Text input area width
        HEIGHT = 300      -- Text input area height
    }
}

-- Colors and transparency settings for UI elements
-- Colors use RGBA format (red, green, blue, alpha)
-- Values range from 0 to 1
local COLORS = {
    SHADOW_TINT = { r = 0, g = 0, b = 0, a = 0.2 },        -- Outer shadow color
    FRAME_TINT = GetUserBgColor(),                         -- Frame border color
    TITLE_BG_TINT = GetUserBgColor(),                      -- Title bar background
    TITLE_TEXT = GetUserTextColor(),                       -- Title text color
    EDITOR_TEXT = GetUserTextColor(),                      -- Main editor text color
    SAVE_INDICATOR = { r = 0.5, g = 1, b = 0.5, a = 1 }    -- "Saved" indicator color
}

-- Behavioral settings and limits
local SETTINGS = {
    TEXT_LENGTH_LIMIT = 10000,            -- Maximum characters allowed in editor
    AUTO_SAVE_INTERVAL = 30,              -- Time between auto-saves (seconds)
    SAVE_INDICATOR_DURATION = 1,          -- How long "Saved" indicator shows (seconds)
    FOCUS_DELAY = 0.1,                    -- Delay before focusing editor (seconds)
    OPEN_ANIMATION_DURATION = 0.2,        -- Widget open animation time (seconds)
    MAX_LINE_WIDTH = 420                  -- Maximum line width in pixels before forcing newline
}

-- Function to update configuration with user settings
local function UpdateConfig(text_color, bg_color, bg_opacity)
    TEXT_COLOR = text_color or TEXT_COLOR
    BG_COLOR = bg_color or BG_COLOR
    BG_OPACITY = bg_opacity or BG_OPACITY
    
    -- Update colors based on new settings
    COLORS.FRAME_TINT = GetUserBgColor()
    COLORS.TITLE_BG_TINT = GetUserBgColor()
    COLORS.TITLE_TEXT = GetUserTextColor()
    COLORS.EDITOR_TEXT = GetUserTextColor()
end

-- Export all configuration constants
return {
    FONT_SIZES = FONT_SIZES,
    DIMENSIONS = DIMENSIONS,
    COLORS = COLORS,
    SETTINGS = SETTINGS,
    UpdateConfig = UpdateConfig
}