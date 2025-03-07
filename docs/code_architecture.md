# QuickNotes: Code Architecture

This document provides an overview of the QuickNotes mod's architecture, explaining the major components and their interactions.

## Module Structure

The codebase follows a modular approach, with each file handling a specific responsibility:

### Core Components

1. **modmain.lua** (~80 lines)
   - Entry point for the mod
   - Handles asset registration
   - Sets up key bindings
   - Controls notepad creation and toggling

2. **modinfo.lua** (~70 lines)
   - Defines mod metadata
   - Provides user configuration options
   - Specifies compatibility information

### Widget Components

3. **scripts/widgets/notepadwidget.lua** (~240 lines)
   - Main widget coordinator
   - Initializes all other components
   - Handles lifecycle events (show/hide)
   - Manages data persistence

4. **scripts/widgets/notepad_ui.lua** (~220 lines)
   - Creates all visual UI elements
   - Handles layout and positioning
   - Manages appearance settings

5. **scripts/widgets/notepad_state.lua** (~215 lines)
   - Manages notepad state (open/closed)
   - Handles auto-save functionality
   - Controls save indicators
   - Manages focus timing

### Notepad Functionality

6. **scripts/notepad/notepad_editor.lua** (~200 lines)
   - Wraps the text editing functionality
   - Delegates key handling and text input
   - Provides API for text manipulation
   - Handles editor scrolling

7. **scripts/notepad/editor_key_handler.lua** (~220 lines)
   - Processes all keyboard input
   - Handles special keys (Home/End/PageUp/PageDown)
   - Manages undo/redo stack
   - Handles cursor navigation

8. **scripts/notepad/text_input_handler.lua** (~180 lines)
   - Processes all text input
   - Handles automatic line breaking
   - Manages special characters and enter key behavior

9. **scripts/notepad/text_utils.lua** (~180 lines)
   - Provides text measurement utilities
   - Handles line splitting
   - Offers helper functions for text manipulation

10. **scripts/notepad/data_manager.lua** (~70 lines)
    - Manages persistent storage
    - Handles saving and loading notes
    - Abstracts storage implementation details

11. **scripts/notepad/config.lua** (~80 lines)
    - Centralizes configuration constants
    - Defines visual settings (colors, dimensions)
    - Controls behavior settings (autosave timing, etc.)

12. **scripts/notepad/draggable_widget.lua** (~70 lines)
    - Provides drag-and-drop functionality
    - Handles mouse position calculations
    - Manages drag state

13. **scripts/notepad/input_handler.lua** (~200 lines)
    - Manages global input for the notepad
    - Handles mouse and keyboard events
    - Controls dragging behavior
    - Processes outside clicks

## Component Interactions

- **NotepadWidget** acts as the central coordinator, owning instances of UI, State, Editor, and other components
- **NotepadEditor** delegates specialized handling to EditorKeyHandler and TextInputHandler
- **TextUtils** provides shared functionality used by multiple components
- **DataManager** isolates persistence logic from the rest of the application

## Data Flow

1. User presses toggle key → modmain.lua creates NotepadWidget
2. NotepadWidget initializes all components and loads saved data
3. User interacts with the notepad:
   - Typing → TextInputHandler processes input
   - Special keys → EditorKeyHandler handles navigation
   - Clicking outside → InputHandler closes notepad
4. Data is automatically saved via NotepadState's auto-save timer

## Design Principles

1. **Single Responsibility**: Each file has one clear purpose
2. **Dependency Injection**: Components receive dependencies rather than creating them
3. **Clear APIs**: Public methods have consistent signatures and documentation
4. **Manageable Size**: All files stay under 300 lines for better readability
5. **Centralized Configuration**: Settings are defined in one place (config.lua)

This architecture ensures the codebase is maintainable, testable, and can be extended with new features easily.