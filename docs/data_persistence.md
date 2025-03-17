# **Data Persistence and Save System**

## Saving Mod Data
DST saves world and entity state automatically. For mod-specific data:
- Implement `OnSave` and `OnLoad` in components.
  ```lua
  function MyComponent:OnSave()
      return { my_value = self.my_value }
  end

  function MyComponent:OnLoad(data)
      if data and data.my_value then
          self.my_value = data.my_value
      end
  end
  ```

## World-Level Data Storage
- Attach data to `TheWorld` entity for global persistence.
  ```lua
  AddPrefabPostInit("world", function(inst)
      inst:AddComponent("mod_tracker")
  end)
  ```

## Persistent Strings (External Data Storage)
- Store non-world-dependent data using `TheSim:SetPersistentString()`.
  ```lua
  TheSim:SetPersistentString("mymod_highscore", "1000", false, function(success) 
      print("Data saved:", success) 
  end)
  ```
- Retrieve with `TheSim:GetPersistentString()`.

## Ensuring Save Compatibility
- Handle missing or outdated data in `OnLoad`.
- Avoid saving unnecessary large datasets to prevent bloat.

Following these guidelines ensures **robust and compatible** mod data persistence in DST.
