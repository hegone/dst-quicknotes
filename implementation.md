Below is a **concise, developer-ready plan** for fixing the two reported issues:

---

## 1. **“Reset” Button Not Appearing Next to “Close” Button**

### **Observed Issue**

- The code in `notepadwidget.lua` does define a reset button (`self.reset_btn`) and positions it to the left of the close button (`self.close_btn`), but the reset button is not visible in the game.

### **Likely Causes & Fixes**

1. **Texture/Atlas Reference Issue**  
   - The reset button uses `ImageButton("images/global.xml", "spinner_arrow.tex")`. If `spinner_arrow.tex` doesn’t exist in `images/global.xml` or is missing from mod assets, the button may be invisible.
   - **Solution**: Confirm that:
     - `"spinner_arrow.tex"` actually exists in `images/global.xml`.  
     - The mod’s `Assets` table in `modmain.lua` or somewhere else has this texture/atlas registered.  
     - If the texture is missing, use a known texture from `"images/global_redux.xml"` or a custom atlas.

2. **Positioning or Overlay**  
   - The button is positioned at `(-30, 0)` relative to the close button container. If the container is too small or overshadowed by other UI elements, the button might be offscreen or covered.
   - **Solution**: Double-check the coordinates or swap it so the reset button is clearly spaced:
     ```lua
     self.reset_btn:SetPosition(-45, 0)  -- move further left
     ```
   - Verify that no other widget has a higher Z-order covering the button.

3. **Initialization Order**  
   - Make sure `InitializeCloseButton()` is indeed called during widget setup (it should be if you see the close button).
   - **Solution**: If the code is present but never called, invoke `InitializeCloseButton()` in `InitializeUIComponents()`.

### **Implementation Steps**

1. **Check/Replace the Texture**  
   - If `spinner_arrow.tex` is missing, either add that texture to `images/global.xml` or use a different icon (e.g., `"close.tex"`) with a distinctive tint.

2. **Verify Position**  
   - Adjust the `SetPosition()` offset to something like `(-45, 0)` so it’s distinctly visible left of the close button.

3. **Test In-Game**  
   - Rebuild/refresh the mod, open the notepad, confirm you see **two** buttons: one for reset, one for close.

---

## 2. **Ctrl+S Not Triggering a Save**

### **Observed Issue**

- The code in `input_handler.lua` uses `CONTROL_ACCEPT` to detect Ctrl-key combos, but in DST’s input system, `CONTROL_ACCEPT` often corresponds to *Enter/confirm*, not specifically Ctrl+S. As a result, pressing **Ctrl+S** doesn’t call `SaveNotes()`.

### **Likely Causes & Fixes**

1. **Wrong Control Code**  
   - The existing code snippet:
     ```lua
     self.keyboard_handlers = {
         -- Ctrl+S to save
         [CONTROL_ACCEPT] = function()
             if TheInput:IsKeyDown(KEY_CTRL) then
                 self.widget:SaveNotes()
                 return true
             end
         end,
         ...
     }
     ```
     ties “Ctrl+S” to a control code that might never be triggered by pressing **S**.  
   - **Solution**: Instead, detect the actual keys in `OnRawKey(key, down)`.

2. **Needs an Explicit Check for Key “S”**  
   - DST doesn’t automatically map Ctrl+S to `CONTROL_ACCEPT`. We must check if `TheInput:IsKeyDown(KEY_CTRL)` **and** `key == KEY_S`.
   - **Solution**: Add something like:
     ```lua
     function InputHandler:OnRawKey(key, down)
         if down and key == KEY_S and TheInput:IsKeyDown(KEY_CTRL) then
             self.widget:SaveNotes()
             return true
         end
         return false
     end
     ```
     This ensures an explicit check for Ctrl+S.

### **Implementation Steps**

1. **Remove the Ctrl+S Logic from `CONTROL_ACCEPT`**  
   - Delete or comment out the “Ctrl+S to save” block in `self.keyboard_handlers`.

2. **Implement in `OnRawKey`**  
   - In `input_handler.lua`, or even in `notepadwidget.lua` (whichever handles raw key events best), do:
     ```lua
     function InputHandler:OnRawKey(key, down)
         -- Check Ctrl+S
         if down and key == KEY_S and TheInput:IsKeyDown(KEY_CTRL) then
             self.widget:SaveNotes()
             return true
         end
         return InputHandler._base.OnRawKey(self, key, down)
     end
     ```
3. **Confirm**  
   - Reload, open notepad, press Ctrl+S. The notepad should show “Saved!” (or your chosen message).

---

## Final “Hand-Off” Checklist

1. **Fix the Reset Button**  
   - Validate the texture file (`spinner_arrow.tex`) or replace it.  
   - Adjust the button’s coordinates so it’s visibly next to the close button.  
   - Verify initialization order; ensure `InitializeCloseButton()` is called.

2. **Enable Ctrl+S Saving**  
   - Remove the old `CONTROL_ACCEPT` approach.  
   - In `OnRawKey()`, explicitly check for **`if (key == KEY_S and TheInput:IsKeyDown(KEY_CTRL))`**.  
   - Call `self.widget:SaveNotes()` upon detection.

3. **Test In-Game**  
   - Confirm the notepad shows **both** the reset and close buttons.  
   - Press **Ctrl+S** with notepad focused; verify it triggers a “Saved!” message and persists the note.

By following these steps, you’ll have the reset button visibly placed next to the close button and **Ctrl+S** will properly trigger the save function.