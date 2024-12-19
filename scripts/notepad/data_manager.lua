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
        data_mgr:SaveNotes("My note content")
        
        -- Load notes
        data_mgr:LoadNotes(function(success, content)
            if success then
                print("Loaded:", content)
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
end)

--[[
    Saves note content to persistent storage.
    
    @param content (string) The note content to save
    @return (boolean) True if save was attempted, false if content was invalid
]]
function DataManager:SaveNotes(content)
    if not content then return false end
    
    -- Save to persistent storage using DST's built-in system
    -- The false parameter indicates we don't need to encode the string
    TheSim:SetPersistentString(self.storage_key, content, false)
    return true
end

--[[
    Loads notes from persistent storage asynchronously.
    
    @param callback (function) Called with (success, content) when load completes
        - success (boolean): Whether the load operation succeeded
        - content (string): The loaded content, or empty string on failure
    
    Note: The callback is required due to the asynchronous nature of
    GetPersistentString. The callback will always be called, even on failure.
]]
function DataManager:LoadNotes(callback)
    if not callback then return end
    
    TheSim:GetPersistentString(self.storage_key, function(success, content)
        if success and content then
            -- Successfully loaded existing notes
            callback(true, content)
        else
            -- Either failed to load or no saved notes exist
            print("[Quick Notes] Failed to load notes or no saved notes found")
            callback(false, "")
        end
    end)
end

return DataManager