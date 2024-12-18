Below is a revised, step-by-step guide that includes the previously discussed enhancements (multiline scrolling, cursor positioning, Home/End keys, PageUp/PageDown navigation, focus management) and now also incorporates **automatic line-break insertion** when the typed text exceeds the widget’s horizontal boundary.  

We’ll assume you have the `NotepadWidget` and related code in place. The new steps focus on modifying the editor’s behavior during text input.

---

### Overview of New & Improved Features

1. **Multiline & Scrolling:**  
   Already supported by `TextEdit` with `EnableScrollEditWindow(true)` and `EnableWordWrap(true)`.  
   You can add scroll buttons or rely on mouse wheel for navigation.

2. **Automatic Line-Break Insertion:**  
   Instead of just visually wrapping long lines, we insert actual `\n` characters once the text reaches the boundary. This ensures that the underlying note content has explicit newlines rather than just visual wrapping.

3. **Cursor Positioning & Line Wrapping:**  
   With actual newlines inserted, cursor navigation at line ends becomes more intuitive.

4. **Home/End Keys:**  
   Jump to start/end of the current line.

5. **PageUp/PageDown Keys:**  
   Navigate larger texts by "pages."

6. **Focus Management:**  
   Ensure the widget handles losing focus gracefully.

---

### Detailed Steps

#### 1. Automatic Line-Break Insertion

**Goal:**  
When the user types and reaches the right boundary of the editor’s region, automatically insert a newline character so that the text “wraps” to the next line in the underlying data as well.

**Key Idea:**  
- After each character is typed, measure the width of the current line.
- If the line exceeds the allowed width, insert a newline before the last typed character and move the cursor.

**Steps:**

1. **Disable Internal WordWrap for This Logic**:  
   Since we’re adding actual line breaks, we can rely on `EnableWordWrap(true)` for visual comfort. However, `EnableWordWrap(true)` can cause the text to wrap visually without modifying the underlying text. For clarity, consider keeping it on for visual alignment but remember we’re now also modifying the underlying text to include `\n`.

   If you want to strictly control actual line breaks, you may set `EnableWordWrap(false)` to avoid confusion, and let your logic handle wrapping.  
   
   *For now, leave `EnableWordWrap(true)` for better UX, but remember we’re also adding newlines.* 

2. **Override `OnTextInput` in the Editor:**
   In `notepadwidget.lua`, when you define `self.editor`, add a custom `OnTextInput` handler:
   ```lua
   local LINE_WIDTH = 450  -- The width of your text region
   local font_size = 25    -- The font size used, adjust as needed
   
   -- Helper function to measure the width of a given line of text:
   local measure_text_width = function(text)
       local temp = Text(DEFAULTFONT, font_size)
       temp:SetString(text)
       local w, h = temp:GetRegionSize()
       temp:Kill() -- cleanup
       return w
   end

   function self.editor:OnTextInput(text)
       if text == nil or text == "" then
           return TextEdit.OnTextInput(self, text)
       end

       -- First, let the original handler add the character
       TextEdit.OnTextInput(self, text)
       
       -- Now, check the last line width
       local full_text = self:GetString()
       local lines = {}
       for line in full_text:gmatch("([^\n]*)\n?") do
           table.insert(lines, line)
       end
       
       local last_line = lines[#lines] or ""
       local w = measure_text_width(last_line)
       
       if w > LINE_WIDTH then
           -- The line exceeds allowed width
           -- Find a suitable break point (e.g., before the last typed character or at the last space)
           local break_pos = #last_line
           -- Optionally, find the last space character to avoid breaking a word:
           local space_pos = last_line:find(" [%S]*$") -- last space before end of line
           if space_pos and space_pos > 1 then
               break_pos = space_pos
           end
           
           -- Construct the new text with a newline inserted
           local new_line = last_line:sub(1, break_pos - 1) .. "\n" .. last_line:sub(break_pos)
           lines[#lines] = new_line
           
           local new_text = table.concat(lines, "\n")
           self:SetString(new_text)
           
           -- Move cursor to the end of the inserted part
           self:SetEditCursorPos(#new_text)
       end
   end
   ```
   
   This logic ensures that when typing surpasses the line width, a newline is inserted into the actual text. You may refine break logic (e.g., find a space to break on, or simply break right before the character that caused overflow).

**Testing:**  
- Type text continuously without pressing enter.
- Once you approach the boundary, a newline should be inserted automatically.
- The cursor should end up at the correct position on the new line.

---

#### 2. Multiline & Scrolling

**From Previous Steps:**  
If you haven’t already:
- Ensure `EnableScrollEditWindow(true)` and `EnableWordWrap(true)` are set.  
- Confirm you can scroll using the mouse wheel.
- Add scroll arrows or a scrollbar if desired, by using `ImageButton` and calling `self.editor:Scroll(lines_count)` or adjusting the scroll position.

**Testing:**  
- Type multiple lines until you can scroll.
- Use the mouse wheel to verify vertical scrolling.
- (Optional) Add buttons to scroll line-by-line or a small scrollbar.

---

#### 3. Cursor Positioning & Line Wrapping

**With actual line breaks inserted**, cursor navigation matches the underlying text structure:
- Left/Right arrows move within a line.
- Up/Down arrows move between lines.

If you want to fine-tune navigation (e.g., ensure Up/Down works as expected in wrapped lines), no extra step may be needed now that we have explicit newlines in the text.

**Testing:**  
- Move cursor around using arrow keys.
- Confirm that moving up at the first line or down at the last line behaves logically.

---

#### 4. Home/End Keys

**Goal:**  
Move the cursor to the start/end of the current line.

**Steps (from previous instructions):**
- In `OnRawKey`, detect `KEY_HOME` and `KEY_END`.
- Find the current line boundaries by searching backward/forward for `\n`.
- Set the cursor position accordingly using `self:SetEditCursorPos()`.

**Testing:**  
- Place cursor in the middle of a line and press Home -> moves to start.
- Press End -> moves to the end of the line.

---

#### 5. PageUp/PageDown Keys

**Goal:**  
Scroll through the text by about one screenful of lines.

**Steps (from previous instructions):**
- Determine how many lines fit in the visible region (e.g., ~12 lines).
- On `KEY_PAGEUP`, move cursor and scroll position up by ~12 lines.
- On `KEY_PAGEDOWN`, move down similarly.
  
Since we now have actual newlines, counting lines is easier:
- Get the current text, split by `\n`, and move up or down 12 lines from the current cursor line.

**Testing:**  
- With a large note, press PageDown and confirm it scrolls down appropriately.
- Press PageUp to scroll back up.

---

#### 6. Focus Management

**Goal:**  
Ensure the notepad behaves well if the player opens another UI or closes the notepad mid-edit.

**Steps (from previous instructions):**
- Test opening and closing the notepad while editing.
- Press ESC to open the game menu and return.
- Verify that text input and scrolling still work afterward.

**Most of this logic is already in place.** Just ensure that no errors occur if the note is closed or focus is lost unexpectedly.

**Testing:**  
- Start typing, then pause the game or open another menu, then return.
- Confirm no loss of data or focus issues.

---

### Summary of Changes

- **Automatic Line-Breaks:**  
  Added logic in `OnTextInput` to insert `\n` when text exceeds a set width.
  
- **Multiline & Scrolling:**  
  Confirmed working with mouse wheel or add UI buttons.

- **Cursor Navigation (Arrows, Home/End):**  
  With actual newlines, navigation is more natural. Implemented Home/End keys for line boundaries.

- **PageUp/PageDown:**  
  Added the ability to jump multiple lines at once.

- **Focus Management:**  
  Tested and ensured robust behavior under various focus changes.

By following these revised steps, you’ll have a notepad that not only handles long texts, scrolling, and navigation keys gracefully but also inserts actual newline characters at line boundaries to maintain a coherent underlying text structure.