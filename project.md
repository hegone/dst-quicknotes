
### **Prompt Title:**  
**"Develop a Persistent In-Game Notepad Mod for Don't Starve Together Using Lua"**

---

### **Prompt Content:**  

You are tasked with providing technical steps and code implementation to create a **toggleable, persistent in-game notepad mod** for *Don't Starve Together* (DST) using Lua. The mod must allow players to write notes, view them, and have the notes saved even when:

1. **The player enters or exits caves.**  
2. **The game session is reloaded (notes persist across saves).**

---

### **Core Requirements:**
1. **Notepad Functionality:**
   - A toggleable widget-based notepad UI (default key: **N**).
   - Players can write and view notes seamlessly.

2. **Persistent Saving:**
   - Save and load the note content:
     - When entering/exiting the caves.
     - When reloading the game or rejoining the server.
   - Notes should be stored locally on the server/client and reloaded on game start.

3. **UI Design:**
   - Minimalistic UI with a toggle to expand/collapse the notepad.

4. **Custom Keybinding:**
   - Allow customization of the keybinding via the mod configuration menu.

---

### **Technical Steps and Key Implementations:**

#### **1. Mod File Structure**
Create the following folder and file structure for the mod:
```
QuickNotes/
├── modinfo.lua        -- Mod metadata
├── modmain.lua        -- Core mod script
└── scripts/
    └── widgets/
        └── notepadwidget.lua -- UI and widget logic
```

---

#### **2. Implement Persistent Data Storage**
Leverage **`ShardPersistData`** for saving and loading across caves and reloads:

- Use **`SavePersistentString`** and **`TheSim:GetPersistentString`** to store data locally.
- Ensure the notes persist across shard transitions (overworld and caves).

---

#### **3. Keybinding to Toggle the Notepad**
Add a keybinding in `modmain.lua` to toggle the notepad:

```lua
GLOBAL.TheInput:AddKeyDownHandler(GLOBAL.KEY_N, function()
    if GLOBAL.ThePlayer and notepadScreen then
        notepadScreen:Toggle()
    end
end)
```

---

#### **4. Notepad Widget Implementation**
Create a widget to display and edit notes:

```lua
local Widget = require "widgets/widget"
local TextEdit = require "widgets/textedit"
local Screen = require "widgets/screen"

local NotepadWidget = Class(Screen, function(self)
    Screen._ctor(self, "NotepadWidget")
    
    self.root = self:AddChild(Widget("root"))
    self.root:SetPosition(0, 0)

    -- Background UI
    self.bg = self.root:AddChild(Image("images/global.xml", "square.tex"))
    self.bg:SetSize(400, 300)
    self.bg:SetTint(0, 0, 0, 0.8)

    -- Text Editor
    self.editor = self.root:AddChild(TextEdit(NEWFONT, 20, ""))
    self.editor:SetPosition(0, 0)
    self.editor:SetString(self:LoadNotes())
    self.editor:SetEditable(true)

    -- Save Notes on Edit
    self.editor:SetPassControlToScreen(false)
    self.editor.OnTextInput = function()
        self:SaveNotes(self.editor:GetString())
    end
end)

function NotepadWidget:SaveNotes(content)
    SavePersistentString("quicknotes", content, false)
end

function NotepadWidget:LoadNotes()
    local data = nil
    TheSim:GetPersistentString("quicknotes", function(success, savedata)
        if success and savedata then
            data = savedata
        end
    end)
    return data or ""
end
```

---

#### **5. Handle Persistent Loading on Game Start**
Hook into the world post-initialization to load saved notes:

```lua
AddPrefabPostInit("world", function(inst)
    if not notepadScreen then
        notepadScreen = GLOBAL.TheFrontEnd:AddScreen(NotepadWidget())
        notepadScreen:Hide()  -- Start hidden
    end
end)
```

---

#### **6. Save Notes Across Caves and Reloads**
The **`SavePersistentString`** method automatically works across shard transitions and reloads because it stores data locally. Notes will persist when players:

- Enter caves and return to the surface.
- Reload the game or disconnect/reconnect to the server.

---

### **7. Mod Configuration for Customization**
Allow players to customize the keybinding and UI behavior through a **mod configuration menu** in `modinfo.lua`:

```lua
name = "QuickNotes: Persistent Notepad"
description = "A handy notepad for jotting down notes. Notes are saved and persist across caves and reloads!"
author = "YourName"
version = "1.0"

configuration_options = {
    {
        name = "keybind_toggle",
        label = "Toggle Key",
        options = {
            {description = "N", data = "N"},
            {description = "H", data = "H"},
            {description = "J", data = "J"},
        },
        default = "N",
    }
}
```

---

### **8. Test Cases**
Test the following scenarios:
1. Open and close the notepad with the **N** key.
2. Write notes and confirm they persist:
   - After exiting and reloading the game.
   - After entering and exiting the caves.
3. Test the mod with multiple players to ensure no interference.

---

### **Expected Behavior:**
- Players can toggle the notepad with the default key or a custom keybinding.
- Notes persist **across cave transitions** and **game reloads**.
- UI remains clean, responsive, and unobtrusive.
