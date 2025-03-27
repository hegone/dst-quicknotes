# QuickNotes: Technical Documentation

## Architecture Overview

QuickNotes employs a modular architecture with clear separation of concerns. The mod is structured using several design patterns:

1. **Component-Based Architecture**: UI elements and behaviors are encapsulated in reusable components
2. **MVC-like Pattern**: Separation between data (notes content), presentation (UI), and control logic
3. **Module Pattern**: Functionality is divided into focused, single-responsibility modules
4. **Event-Driven Communication**: Components interact through events rather than direct coupling

## Directory Structure

```
dst-quicknotes/
├── modinfo.lua           # Mod metadata and configuration
├── modmain.lua           # Entry point and initialization
├── images/               # UI assets and textures
├── scripts/
│   ├── notepad/          # Core functionality modules
│   │   ├── config.lua            # Centralized configuration constants
│   │   ├── data_manager.lua      # Data persistence layer
│   │   ├── draggable_widget.lua  # Drag-and-drop functionality
│   │   ├── editor_key_handler.lua # Keyboard navigation handling
│   │   ├── focus_manager.lua     # Input focus management
│   │   ├── input_handler.lua     # General input event handling
│   │   ├── notepad_editor.lua    # Text editing component
│   │   ├── sound_manager.lua     # Audio feedback management
│   │   ├── text_input_handler.lua # Text input processing
│   │   └── text_utils.lua        # Text manipulation utilities
│   └── widgets/          # UI widget components
│       ├── notepad_state.lua     # State management for notepad
│       ├── notepad_ui.lua        # UI components and layout
│       └── notepadwidget.lua     # Main widget controller
└── modicon.tex           # Mod icon
```

## Core Components

### 1. Entry Points

#### `modmain.lua`
- Initializes the mod in the DST environment
- Registers key bindings
- Sets up the global toggle action
- Loads required assets

#### `modinfo.lua`
- Provides metadata about the mod (name, author, description)
- Defines user-configurable options
- Specifies compatibility information

### 2. Main Components

#### `notepadwidget.lua`
- **Purpose**: Main controller and screen manager
- **Responsibilities**:
  - Initializes all subcomponents
  - Coordinates between UI, state, and data
  - Handles screen lifecycle (show/hide/close)
  - Routes input to appropriate handlers
- **Key Methods**:
  - `OnBecomeActive`: Setup when screen becomes visible
  - `OnBecomeInactive`: Cleanup when screen closes
  - `SaveNotes`: Persists content to storage
  - `LoadNotes`: Retrieves content from storage

#### `notepad_editor.lua`
- **Purpose**: Core text editing functionality
- **Responsibilities**:
  - Wraps DST's TextEdit widget with enhanced features
  - Manages text content and cursor position
  - Coordinates with specialized handlers for input
- **Key Methods**:
  - `GetText`/`SetText`: Text content manipulation
  - `ScrollToCursor`: Ensures cursor remains visible
  - `SetupHighlighting`: Prepares text selection support

### 3. Input Processing

#### `editor_key_handler.lua`
- **Purpose**: Handles advanced keyboard navigation and editing commands within the text editor.
- **Responsibilities**:
  - Processes special keys: Arrow keys (multi-line), Home/End (line start/end), PageUp/Down (~10 lines), **Ctrl+Left/Right (word jump)**.
  - Manages cursor movement logic based on plain text representation.
  - Implements text selection state management (logical only) via Shift modifier.
  - Handles Backspace, Delete, and Enter key actions, respecting selections.
- **Key Methods**:
  - `ProcessKey`: Main dispatcher for raw key events.
  - `HandleCursorMovement`: Calculates new cursor position based on navigation keys.
  - `HandleBackspace`/`HandleDelete`/`HandleEnterKey`: Perform text modifications.
  - `FindPreviousWordPosition`/`FindNextWordPosition`: Helper functions for word navigation.
  - `GetCurrentLineInfo`: Determines line information based on plain cursor position.
  - `SplitTextIntoLines`: Parses plain text into lines for navigation calculations.

#### `text_input_handler.lua`
- **Purpose**: Handles character input and automatic formatting.
- **Responsibilities**:
  - Handles text insertion at cursor position.
  - Implements automatic line breaking (word wrap) based on calculated visual width of plain text.
  - Processes paste events (Ctrl+V).
  - Filters invalid input characters.
- **Key Methods**:
  - `HandleTextInput`: Processes incoming characters for insertion or selection replacement.
  - `CheckLineBreaking`: Calculates line width and inserts `\n` if needed.
  - `SetupPasteHandler`: Integrates with paste system.

### 4. UI Components

#### `notepad_ui.lua`
- **Purpose**: Visual presentation layer
- **Responsibilities**:
  - Creates and arranges visual elements
  - Manages appearance settings
  - Sets up clickable areas and interactions
- **Key Methods**:
  - `InitializeUIComponents`: Creates all UI elements
  - `InitializeTitleBar`: Sets up draggable header
  - `IsMouseInWidget`: Hit testing for clicks

### 5. State and Data

#### `notepad_state.lua`
- **Purpose**: Manages notepad lifecycle and state
- **Responsibilities**:
  - Tracks open/closed state
  - Handles auto-save timers
  - Manages focus timing
- **Key Methods**:
  - `StartAutoSave`: Begins periodic saving
  - `ShowSaveIndicator`: Visual feedback for saves
  - `Activate`/`Deactivate`: State transitions

#### `data_manager.lua`
- **Purpose**: Data persistence layer
- **Responsibilities**:
  - Saves and loads notes content
  - Manages data format and storage location
  - Handles backup and recovery
- **Key Methods**:
  - `SaveNotes`: Persists notes to storage
  - `LoadNotes`: Retrieves notes from storage
  - `CreateBackup`: Creates safety copies

## Technical Implementation Details

### Text Editing Engine

The text editing functionality is built on DST's `TextEdit` widget with significant enhancements:

1. **Cursor Management**
   - The mod implements fully custom multi-line navigation logic in `EditorKeyHandler`.
   - Supports standard Arrow keys, Home/End for line boundaries, PageUp/PageDown for larger jumps, and **Ctrl+Left/Right for word-by-word movement.**
   - Cursor position is carefully tracked and updated based on logical plain text indices, translated back to raw indices for the underlying widget.
   - Column position is preserved during vertical movement where possible, clamping to the destination line's length otherwise.


2. **Input Processing Flow**
   ```
   User Input -> OnRawKey/OnTextInput -> ProcessKey/HandleTextInput -> Specialized Handlers (Movement/Edit/Wrap) -> Text Manipulation (Plain Text) -> _UpdateEditorState (Set Raw Text & Raw Cursor) -> UI Update
   ```

3. **Line Navigation System**
   - Each line's boundaries are calculated dynamically
   - Cursor column position is preserved during vertical movement when possible
   - Home/End keys use specialized line detection to ensure consistent behavior

### Persistence Mechanism

Notes are saved using DST's persistent storage system:

1. **Storage Format**
   - JSON-encoded state object containing:
     - Content: The note text
     - Position: Window coordinates
     - Timestamp: For versioning

2. **Save Triggers**
   - Automatic saving every 30 seconds
   - Manual saving (Ctrl+S)
   - On notepad close
   - On game exit

3. **Error Recovery**
   - Backup creation before potentially destructive operations
   - Fallback loading if primary file is corrupted
   - Graceful handling of JSON parsing failures

### UI Integration

The mod integrates with DST's UI system while providing enhanced functionality:

1. **Widget Hierarchy**
   ```
   Screen
   ├── Background
   ├── Root Widget
   │   ├── Shadow
   │   ├── Frame
   │   ├── Title Bar
   │   ├── Save Indicator
   │   ├── Buttons
   │   └── Editor
   ```

2. **Focus System**
   - Custom focus management to handle editing states
   - Proper focus handling during window operations
   - Direct integration with DST's input system

3. **Dragging Implementation**
   - Custom hit detection for the title bar
   - Position tracking during mouse movement
   - Throttled position updates to minimize save operations

## Extension Points

Future development or customization can leverage these extension points:

1. **Adding UI Elements**
   - Extend `NotepadUI` class to add new visual components
   - Add initialization code in `InitializeUIComponents`

2. **New Keyboard Shortcuts**
   - Add handlers to `EditorKeyHandler:ProcessKey`
   - Register keys in `validrawkeys` table

3. **Enhanced Text Features**
   - Text formatting can be added to `text_utils.lua`
   - Selection handling can be extended in `editor_key_handler.lua`

4. **Multiple Pages**
   - Implement a tab system in `notepad_ui.lua`
   - Extend `data_manager.lua` to support multiple content objects

## Technical Challenges and Solutions

### Challenge: Cursor Navigation in DST's Limited Environment

**Problem**: DST's basic TextEdit widget lacks sophisticated multi-line navigation.

**Solution**: 
- Implemented custom line detection algorithm that calculates line boundaries
- Created specialized handlers for Home/End keys with precise line targeting
- Added edge-case handling for cursor at line boundaries

### Challenge: Advanced Cursor Navigation in DST's Limited Environment

**Problem**: DST's basic `TextEdit` widget lacks sophisticated multi-line navigation (Up/Down between lines, Home/End, PageUp/Down, Word Jumping).

**Solution**:
- Implemented fully custom navigation logic within `EditorKeyHandler`.
- Custom line detection (`GetCurrentLineInfo`, `SplitTextIntoLines`) and position calculation based on plain text indices.
- Specialized handlers for Home/End, PageUp/Down, and **Ctrl+Arrow keys for word jumping** (`FindPreviousWordPosition`, `FindNextWordPosition`).
- Careful management of cursor column position during vertical movement, with clamping to line ends.
- Introduced (though currently basic) `PositionMapper` infrastructure to abstract raw vs. plain text indices, crucial for future tag support or complex text manipulation.


### Challenge: Text Input at Cursor Position

**Problem**: DST's text input system doesn't naturally handle insertion at cursor position.

**Solution**:
- Created custom text input handler that splits text at cursor position
- Implemented proper cursor position maintenance during editing
- Added safety checks to handle cases where cursor position methods aren't available

### Challenge: Persistent Window Position

**Problem**: Maintaining window position across game sessions.

**Solution**:
- Extended the save state format to include position data
- Added position tracking during drag operations
- Implemented position restoration on notepad creation

## Performance Considerations

1. **Text Measurement Caching**
   - Text width calculations are cached to avoid performance penalties
   - Cache is pruned when it grows too large

2. **Position Update Throttling**
   - Window position updates are throttled to reduce save operations
   - Changes are batched and processed at appropriate intervals

3. **Defensive Programming**
   - Extensive null checking prevents errors with missing components
   - Graceful fallbacks when expected methods aren't available

## Coding Standards and Patterns

1. **Documentation**
   - All functions have descriptive comments
   - Parameters and return values are documented
   - Complex logic includes inline explanations

2. **Error Handling**
   - Functions check input validity before processing
   - Defensive programming to handle unexpected states
   - Graceful degradation rather than hard crashes

3. **Module Independence**
   - Modules communicate through well-defined interfaces
   - Dependencies are explicitly required at module top
   - Components can be tested or replaced individually

## Conclusion

QuickNotes is built with maintainability and extensibility in mind. The modular architecture allows for focused development of individual features while maintaining a clean separation of concerns. Future enhancements can build on this foundation to add new capabilities without requiring substantial rewrites of existing code.