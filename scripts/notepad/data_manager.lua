--[[
    Data Manager Module for DST Quick Notes
    
    This module handles all persistent data operations for the notepad mod.
    It provides a clean interface for saving and loading notes using Don't
    Starve Together's persistent storage system (TheSim).

    The module abstracts away the persistence implementation details,
    allowing the rest of the mod to work with notes without knowing how
    they are stored.

    Usage:
        local DataManager = require("notepad/data_manager")
        local data_mgr = DataManager()
        
        -- Save notes
        data_mgr:SaveNotes("My note content", {x=0, y=0})
        
        -- Load notes
        data_mgr:LoadNotes(function(success, content, position)
            if success then
                print("Loaded:", content, position.x, position.y)
            end
        end)
]]

--[[
    DataManager Class
    
    Handles saving and loading of note content using DST's persistent storage.
    Uses a single storage key for all notes in the current implementation.
]]
local DataManager = Class(function(self)
    -- Initialize with default storage key for all notes
    -- This key is used to identify our data in DST's persistent storage
    self.storage_key = "quicknotes"
    self.backup_key = "quicknotes_backup"
end)

--[[
    Saves note content and position to persistent storage.
    
    @param content (string) The note content to save
    @param position (table) Position data {x=number, y=number}
    @return (boolean) True if save was attempted, false if content was invalid
]]
function DataManager:SaveNotes(content, position)
    if not content then return false end
    
    -- Create state object with content and position
    local state = {
        content = content,
        position = position or {x = 0, y = 0},
        timestamp = os.time()
    }
    
    -- Create JSON string
    local json_data
    local status, result = pcall(function() return json.encode(state) end)
    if status and result then
        json_data = result
    else
        -- Fallback if JSON encoding fails
        print("[Quick Notes] JSON encoding failed, saving content only")
        TheSim:SetPersistentString(self.storage_key, content, false)
        return true
    end
    
    -- Save to persistent storage using DST's built-in system
    TheSim:SetPersistentString(self.storage_key, json_data, false)
    
    -- Create a backup
    self:CreateBackup(content, position)
    
    return true
end

--[[
    Loads notes from persistent storage asynchronously.
    
    @param callback (function) Called with (success, content, position) when load completes
        - success (boolean): Whether the load operation succeeded
        - content (string): The loaded content, or empty string on failure
        - position (table): The saved position, or nil on failure
    
    Note: The callback is required due to the asynchronous nature of
    GetPersistentString. The callback will always be called, even on failure.
]]
function DataManager:LoadNotes(callback)
    if not callback then return end
    
    TheSim:GetPersistentString(self.storage_key, function(success, data)
        if success and data and data ~= "" then
            -- Try to parse JSON data
            local status, state = pcall(function() return json.decode(data) end)
            
            if status and state and state.content then
                -- Successfully loaded JSON state
                callback(true, state.content, state.position)
            else
                -- Either parsing failed or it's old format (just the content string)
                -- Convert to new format by using the content directly
                callback(true, data, nil)
            end
        else
            -- Either failed to load or no saved notes exist
            print("[Quick Notes] Failed to load notes or no saved notes found")
            self:LoadBackup(callback)
        end
    end)
end

--[[
    Creates a backup of the current notes.
    Useful before potentially destructive operations.
    
    @param content (string) Content to backup
    @param position (table) Position to backup
    @return (boolean) True if backup was created, false otherwise
]]
function DataManager:CreateBackup(content, position)
    if not content then return false end
    
    -- Create backup with timestamp
    local state = {
        content = content,
        position = position,
        timestamp = os.time()
    }
    
    -- Try to encode as JSON
    local json_data
    local status, result = pcall(function() return json.encode(state) end)
    if status and result then
        json_data = result
    else
        -- Fallback if JSON encoding fails
        print("[Quick Notes] JSON encoding failed for backup, saving content only")
        TheSim:SetPersistentString(self.backup_key, content, false)
        return true
    end
    
    -- Save to backup key
    TheSim:SetPersistentString(self.backup_key, json_data, false)
    return true
end

--[[
    Loads backup notes if available.
    
    @param callback (function) Same callback as LoadNotes
]]
function DataManager:LoadBackup(callback)
    if not callback then return end
    
    TheSim:GetPersistentString(self.backup_key, function(success, data)
        if success and data and data ~= "" then
            -- Try to parse JSON data
            local status, state = pcall(function() return json.decode(data) end)
            
            if status and state and state.content then
                -- Successfully loaded backup
                print("[Quick Notes] Loaded from backup")
                callback(true, state.content, state.position)
            else
                -- Either parsing failed or it's old format
                callback(true, data, nil)
            end
        else
            -- No backup exists
            callback(false, "", nil)
        end
    end)
end

return DataManager