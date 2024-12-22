Below is a **comprehensive project plan** you can hand off to your developer. It details how to implement **automatic line-breaking** so the notepad only grows vertically. The plan references specific files and functions from your current DST notepad mod codebase. Feel free to adapt these steps to your code style and workflow.

---

## 1. Introduce a "Line Width" Setting

1. **File:** `scripts/notepad/config.lua`  
2. **Action:**  
   - Add a constant, e.g. `MAX_LINE_WIDTH = 420`, in your `SETTINGS` or create a new table `LINE_BREAK = { WIDTH = 420 }` (whatever suits your structure). This is the maximum width (in pixels) for each line before forcing a newline.  
   - Example:
     ```lua
     local SETTINGS = {
         ...
         MAX_LINE_WIDTH = 420,  -- The maximum line width in pixels
         ...
     }
     ```

3. **Purpose:**  
   This will serve as the cutoff for inserting a manual newline. We’ll measure text widths against this number.

---

## 2. Add a Text-Measuring Function

1. **File:** `scripts/notepad/text_utils.lua` (or `notepad_editor.lua`)  
2. **Action:**  
   - Implement a helper function, e.g. `CalculateTextWidth(text, font, font_size)`, which measures how many pixels a given string occupies.  

3. **Implementation Sketch:**  
   ```lua
   local function CalculateTextWidth(str, font, font_size)
       local measuring_text = Text(font, font_size)
       measuring_text:SetString(str)
       local w, h = measuring_text:GetRegionSize()
       measuring_text:Kill()
       return w
   end
   ```
   
   - Note that in DST modding, you often create a temporary `Text` widget to measure widths. Alternatively, if there's a known global function (e.g. `TheSim:CalculateSizeForFont`), you could use that.  

4. **Purpose:**  
   This function allows us to precisely check if the user’s typed text has exceeded the `MAX_LINE_WIDTH` threshold.

---

## 3. Implement Auto Line-Break Logic

1. **File:** `scripts/notepad/notepad_editor.lua` or `scripts/notepad/text_utils.lua`  
2. **Action:**  
   - Wherever you handle text input (usually in `OnRawKey` or in a custom `OnTextInput` callback), add logic that checks the current line’s width.  
   - If the text surpasses `MAX_LINE_WIDTH`, insert a newline (`"\n"`) at the nearest word boundary.  

3. **Implementation Sketch:**

   ```lua
   -- Pseudocode inside OnRawKey or OnTextInput
   local new_text = self.editor:GetString() .. typed_char
   
   -- Find the current line (split by "\n")
   local lines = SplitByLine(new_text)
   local last_line = lines[#lines]
   
   -- Measure the width of last_line
   local width = CalculateTextWidth(last_line, your_font, your_font_size)
   
   if width > Config.SETTINGS.MAX_LINE_WIDTH then
       -- Find the nearest space or break point in last_line
       local break_index = FindNearestSpace(last_line)
       
       if break_index then
           -- Replace that space with \n or insert \n
           last_line = InsertNewlineAt(last_line, break_index)
           -- Reconstruct text
           lines[#lines] = last_line
           new_text = table.concat(lines, "\n")
       else
           -- If no space found (a single massive word?), break forcibly
           last_line = last_line .. "\n"
           lines[#lines] = last_line
           new_text = table.concat(lines, "\n")
       end
   end
   
   -- Finally set the text
   self.editor:SetString(new_text)
   ```

4. **Helper Functions Needed:**
   - `SplitByLine(text)`: Returns an array of lines by splitting on `"\n"`.  
   - `FindNearestSpace(line)`: Looks from the end of the line backward for a space to insert a line break.  
   - `InsertNewlineAt(line, idx)`: Replaces the space at `idx` with `"\n"` or simply inserts `"\n"` at `idx`.

5. **Purpose:**  
   This ensures your code actually inserts newline characters in the underlying string whenever a line surpasses the maximum width. The result: text only expands vertically.

---

## 4. Keep Word-Wrap Enabled

1. **File:** `notepad_editor.lua` or `text_utils.lua` in your `InitializeEditor()` calls  
2. **Action:**  
   ```lua
   editor:EnableScrollEditWindow(true)
   editor:EnableWordWrap(true)
   ```
3. **Purpose:**  
   - **Visual** word wrap ensures that if for some reason the newline logic lags behind or the user pastes a huge chunk, the editor still won’t expand horizontally.  
   - Combined with actual newline insertion, you get consistent line breaks in both appearance **and** data.

---

## 5. Synchronize the Cursor Correctly

1. **Challenge:**  
   When you insert a newline in the underlying string, you must ensure the cursor position moves to the next line.  
2. **Action:**  
   - After you call `self.editor:SetString(new_text)`, also call `self.editor:SetEditCursorPos(#new_text)` or a more precise position if you inserted the newline in the middle.  

3. **Purpose:**  
   Keeps the user’s cursor in sync with the newly inserted line break.  

---

## 6. Thorough Testing

1. **Test with Different Cases:**  
   - Type a single long word that exceeds the line limit.  
   - Type multiple words that cross the limit.  
   - Insert newlines manually (Enter key) to see if logic still behaves.  
   - Copy-paste large blocks of text to confirm auto-breaking.  

2. **Check for Edge Cases:**  
   - If user types near the boundary of the notepad, does the line break happen gracefully?  
   - If user deletes text and retypes, does it still break properly?  

3. **Multiplayer & Shards:**  
   - Auto line-break logic is purely client-side text editing, so it should not conflict with saving or shard transitions. Still, confirm that saving, reloading, and re-entering the note preserves line breaks.

---

## 7. Additional (Optional) Enhancements

1. **Page Up / Page Down Navigation:**  
   - If you plan to incorporate large text, consider letting the user jump lines quickly.  
2. **Undo/Redo Adjustments:**  
   - Each automatic break could be a separate undo step. That means capturing text states before/after the break.  

---

## Summary of Developer Tasks

1. **Add `MAX_LINE_WIDTH`** in `config.lua`.  
2. **Create a text-measuring helper** (e.g., `CalculateTextWidth()`).  
3. **Implement auto line-break** logic in `OnRawKey` or `OnTextInput`:
   - Split text by lines.
   - If the last line exceeds `MAX_LINE_WIDTH`, insert `"\n"`.
   - Update the editor with `SetString(new_text)` and fix cursor position.  
4. **Keep `EnableWordWrap(true)`** for consistent rendering.  
5. **Test** thoroughly with varied input scenarios.  

With these changes, your **DST notepad** will **auto-insert newlines** whenever text hits the right edge, ensuring it **only expands downward**. Users will see consistent line wrapping both visually and in the saved content.