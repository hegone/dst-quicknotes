# Clickable Cursor Placement Feature

## Overview

The clickable cursor placement feature allows users to click anywhere within the text editor area to position the cursor at that specific location. This provides a more intuitive text editing experience similar to standard text editors.

## Implementation Details

### Component Integration

The feature is implemented across several components:

1. **EditorKeyHandler** - Enhanced with mouse click handling capabilities
2. **NotepadEditor** - Updated to ensure proper focus management
3. **NotepadUI** - Improved click handling for consistent behavior

### Technical Approach

The implementation follows DST modding conventions and works within the limitations of the game's UI system:

#### Cursor Positioning Algorithm

1. **Click Detection** - Captures mouse click coordinates when clicking within the editor area
2. **Coordinate Conversion** - Translates screen coordinates to local editor coordinates
3. **Line Determination** - Calculates which line was clicked based on the Y-coordinate and scroll position
4. **Character Position** - Estimates the character position within the line based on the X-coordinate
5. **Cursor Placement** - Sets the editor cursor to the calculated position

#### Focus Management

To address focus issues, we've implemented multiple layers of focus protection:

1. **Focus Recovery** - Ensures editor regains focus after any click interaction
2. **Editing Mode Enforcement** - Explicitly sets the editor to editing mode after focus changes
3. **Delayed Focus** - Uses small timing delays to overcome DST's focus handling quirks
4. **Focus Catcher** - An invisible widget that helps maintain focus state

## User Experience

From the user's perspective, the notepad now behaves like a standard text editor:

- Click anywhere in the text to position the cursor
- The editor maintains focus properly through all interactions
- Editing resumes seamlessly after clicking within the notepad area

## Known Limitations

While the implementation is robust, there are some inherent limitations due to DST's UI system:

1. **Character Precision** - The character position calculation uses an average character width, which may not be pixel-perfect for variable-width fonts
2. **Scroll Behavior** - Scroll position affects cursor placement accuracy, especially with very long documents
3. **Edge Cases** - Multi-line selections and very complex text layouts may have reduced precision

## Future Enhancements

Potential improvements for future updates:

1. **More precise character positioning** using character-by-character width calculations
2. **Drag selection** to select ranges of text
3. **Double-click word selection** for faster editing
4. **Right-click context menu** with additional editing options

## Testing

The feature has been tested in various scenarios:

- Different text lengths and content types
- Various click positions within the editor
- Focus transitions between game UI elements
- Interaction with other editing features (keyboard navigation, etc.)

These improvements should provide a more intuitive and reliable editing experience for users of the QuickNotes mod.