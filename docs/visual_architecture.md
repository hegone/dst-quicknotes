# QuickNotes: Visual Architecture Guide

This document provides visual explanations of the QuickNotes mod structure and workflows using intuitive diagrams. These visualizations help understand how the different components interact to create a seamless notepad experience in Don't Starve Together.

## Module Architecture

The diagram below shows the main components of QuickNotes and how they relate to each other:

```mermaid
flowchart TD
    %% Main Components and Architecture
    subgraph Entry["Entry Points"]
        modmain["modmain.lua\nMod Initialization"]
        modinfo["modinfo.lua\nMod Metadata"]
    end
    
    subgraph Core["Core Components"]
        notepadwidget["notepadwidget.lua\nMain Controller"]
        notepad_ui["notepad_ui.lua\nUI Components"]
        notepad_editor["notepad_editor.lua\nText Editor"]
        notepad_state["notepad_state.lua\nState Management"]
    end
    
    subgraph InputHandling["Input Processing"]
        input_handler["input_handler.lua\nGeneral Input"]
        editor_key_handler["editor_key_handler.lua\nKeyboard Navigation"]
        text_input_handler["text_input_handler.lua\nText Processing"]
    end
    
    subgraph Data["Data Management"]
        data_manager["data_manager.lua\nPersistence"]
        text_utils["text_utils.lua\nText Utilities"]
    end
    
    subgraph Utilities["Support Modules"]
        focus_manager["focus_manager.lua\nFocus Control"]
        draggable_widget["draggable_widget.lua\nDrag-and-Drop"]
        sound_manager["sound_manager.lua\nAudio Feedback"]
        config["config.lua\nSettings"]
    end
    
    %% Connections between components
    modmain -->|Creates| notepadwidget
    notepadwidget -->|Uses| notepad_ui
    notepadwidget -->|Uses| notepad_editor
    notepadwidget -->|Uses| notepad_state
    notepadwidget -->|Uses| input_handler
    notepadwidget -->|Uses| data_manager
    
    notepad_editor -->|Uses| editor_key_handler
    notepad_editor -->|Uses| text_input_handler
    notepad_editor -->|Uses| text_utils
    notepad_editor -->|Uses| focus_manager
    
    notepad_ui -->|Uses| draggable_widget
    notepad_ui -->|Uses| sound_manager
    
    input_handler -->|Delegates| editor_key_handler
    input_handler -->|Delegates| text_input_handler
    
    %% Visual styling
    classDef entryPoint fill:#e9967a,stroke:#333,stroke-width:2px
    classDef core fill:#66cdaa,stroke:#333,stroke-width:2px
    classDef input fill:#ffa07a,stroke:#333,stroke-width:2px
    classDef data fill:#87cefa,stroke:#333,stroke-width:2px
    classDef utility fill:#d8bfd8,stroke:#333,stroke-width:2px
    
    class modmain,modinfo entryPoint
    class notepadwidget,notepad_ui,notepad_editor,notepad_state core
    class input_handler,editor_key_handler,text_input_handler input
    class data_manager,text_utils data
    class focus_manager,draggable_widget,sound_manager,config utility
```

## User Interaction Flow

This diagram shows the journey of user inputs through the system:

```mermaid
sequenceDiagram
    actor User
    participant Game as DST Game
    participant Notepad as NotepadWidget
    participant UI as Notepad UI
    participant Editor as Notepad Editor
    participant InputHandler as Input Handlers
    participant DataManager as Data Manager
    
    %% Opening the notepad
    User->>Game: Press 'N' key
    Game->>Notepad: Toggle Notepad
    Notepad->>DataManager: Load saved notes
    DataManager-->>Notepad: Return saved content
    Notepad->>UI: Initialize UI components
    Notepad->>Editor: Initialize text editor
    Notepad-->>User: Display notepad
    
    %% Text editing
    User->>Notepad: Type text
    Notepad->>InputHandler: Process text input
    InputHandler->>Editor: Insert text at cursor
    Editor-->>User: Update display
    
    %% Keyboard navigation
    User->>Notepad: Press navigation key
    Notepad->>InputHandler: Process key input
    InputHandler->>Editor: Move cursor
    Editor-->>User: Update cursor position
    
    %% Saving notes
    Note over Notepad: Auto-save timer or Ctrl+S
    Notepad->>DataManager: Save notes
    DataManager-->>Notepad: Confirm save
    Notepad->>UI: Show "Saved!" indicator
    UI-->>User: Display save confirmation
    
    %% Closing
    User->>Notepad: Press ESC or click outside
    Notepad->>DataManager: Final save
    Notepad->>Game: Close notepad
    Game-->>User: Return to game
```

## Notepad States and Transitions

This state diagram shows the lifecycle of the notepad and its possible states:

```mermaid
stateDiagram-v2
    [*] --> Closed: Game starts
    
    Closed --> Opening: Press 'N'
    Opening --> Open: Initialize complete
    
    Open --> Editing: User types
    Editing --> Open: User stops typing
    
    Open --> Dragging: Drag title bar
    Dragging --> Open: Release mouse
    
    Open --> AutoSaving: 30-second interval
    AutoSaving --> Open: Save complete
    
    Open --> ManualSaving: Press Ctrl+S
    ManualSaving --> Open: Save complete
    
    Open --> Closing: Press ESC/click outside
    Closing --> Closed: Cleanup complete
    
    Closed --> [*]: Game ends
    
    note right of Opening: Load saved notes
    note right of Editing: Cursor navigation active
    note right of AutoSaving: Silent background save
    note right of ManualSaving: Shows "Saved!" indicator
    note right of Closing: Performs final save
```

## Text Input and Cursor Management

This diagram shows how text input and cursor management work in the editor:

```mermaid
flowchart LR
    %% Text input and cursor flow
    subgraph Input["User Input"]
        keypress["Key Press"]
        typing["Text Typing"]
        navigation["Navigation Keys"]
    end
    
    subgraph Processing["Input Processing"]
        raw_input["OnRawKey\nHandler"]
        text_input["OnTextInput\nHandler"]
        input_filter["Input\nFiltering"]
        key_handler["Navigation\nHandler"]
    end
    
    subgraph Effects["Text Effects"]
        text_insert["Text\nInsertion"]
        cursor_move["Cursor\nMovement"]
        line_break["Line\nBreaking"]
        text_delete["Character\nDeletion"]
    end
    
    subgraph State["Text State"]
        content["Text\nContent"]
        cursor["Cursor\nPosition"]
        selection["Text\nSelection"]
    end
    
    %% Connections
    keypress --> raw_input
    typing --> text_input
    navigation --> raw_input
    
    raw_input --> key_handler
    text_input --> input_filter
    
    key_handler --> cursor_move
    input_filter --> text_insert
    input_filter --> line_break
    key_handler --> text_delete
    
    cursor_move --> cursor
    text_insert --> content
    text_delete --> content
    line_break --> content
    
    key_handler --> selection
    
    %% Visual styling
    classDef input fill:#ffcc99,stroke:#333,stroke-width:1px
    classDef process fill:#99ccff,stroke:#333,stroke-width:1px
    classDef effect fill:#99ff99,stroke:#333,stroke-width:1px
    classDef state fill:#cc99ff,stroke:#333,stroke-width:1px
    
    class keypress,typing,navigation input
    class raw_input,text_input,input_filter,key_handler process
    class text_insert,cursor_move,line_break,text_delete effect
    class content,cursor,selection state
```

## Data Flow and Persistence

This diagram shows how note data is saved and loaded:

```mermaid
flowchart TD
    %% Data persistence flow
    subgraph UserActions["User Actions"]
        type["Type Text"]
        save["Manual Save\n(Ctrl+S)"]
        close["Close Notepad"]
    end
    
    subgraph AutoEvents["Automatic Events"]
        timer["30s Timer"]
        world_save["World Save"]
        game_exit["Game Exit"]
    end
    
    subgraph NotepadWidget["Notepad Widget"]
        content["Current Text\nContent"]
        position["Window\nPosition"]
        save_method["SaveNotes()\nMethod"]
    end
    
    subgraph DataManager["Data Manager"]
        serialize["Serialize\nContent"]
        json_encode["JSON\nEncoding"]
        persistence["TheSim:SetPersistentString()"]
        backup["Create\nBackup"]
    end
    
    subgraph Storage["Persistent Storage"]
        main_storage["quicknotes\nStorage Key"]
        backup_storage["quicknotes_backup\nBackup Key"]
    end
    
    %% Loading flow
    subgraph LoadFlow["Load Process"]
        check_storage["Check Storage\nFor Saved Notes"]
        deserialize["Deserialize\nContent"]
        load_fallback["Try Backup\nIf Main Fails"]
    end
    
    %% Connections - Saving
    type --> content
    save --> save_method
    close --> save_method
    timer --> save_method
    world_save --> save_method
    game_exit --> save_method
    
    content --> save_method
    position --> save_method
    save_method --> serialize
    
    serialize --> json_encode
    json_encode --> persistence
    json_encode --> backup
    
    persistence --> main_storage
    backup --> backup_storage
    
    %% Connections - Loading
    check_storage --> main_storage
    main_storage --> deserialize
    deserialize --"Failure"--> load_fallback
    load_fallback --> backup_storage
    deserialize --"Success"--> content
    
    %% Visual styling
    classDef actions fill:#ffcc99,stroke:#333,stroke-width:1px
    classDef events fill:#99ccff,stroke:#333,stroke-width:1px
    classDef widget fill:#99ff99,stroke:#333,stroke-width:1px
    classDef manager fill:#cc99ff,stroke:#333,stroke-width:1px
    classDef storage fill:#ffff99,stroke:#333,stroke-width:1px
    classDef loading fill:#ff9999,stroke:#333,stroke-width:1px
    
    class type,save,close actions
    class timer,world_save,game_exit events
    class content,position,save_method widget
    class serialize,json_encode,persistence,backup manager
    class main_storage,backup_storage storage
    class check_storage,deserialize,load_fallback loading
```

## UI Component Hierarchy

This diagram shows the UI component structure:

```mermaid
flowchart TD
    %% UI Component hierarchy
    Screen["Screen\n(Base Class)"]
    NotepadWidget["NotepadWidget\n(Main Screen)"]
    
    Screen --> NotepadWidget
    
    subgraph UIComponents["UI Components"]
        Root["Root Widget\n(Container)"]
        BG["Background\n(Clickable Area)"]
        BGShadow["Background Shadow\n(Visual Depth)"]
        Frame["Frame\n(Border)"]
        TitleBar["Title Bar\n(Draggable)"]
        TitleText["Title Text\n(\"Quick Notes\")"]
        CloseBtn["Close Button\n(X)"]
        ResetBtn["Reset Button\n(Rotated X)"]
        SaveIndicator["Save Indicator\n(Feedback)"]
    end
    
    subgraph EditorComponents["Editor Components"]
        EditorWidget["Editor Widget\n(Text Container)"]
        TextEdit["TextEdit\n(DST Widget)"]
        InputHandlers["Custom Input\nHandlers"]
    end
    
    NotepadWidget --> Root
    Root --> BG
    Root --> BGShadow
    Root --> Frame
    Root --> TitleBar
    TitleBar --> TitleText
    Root --> EditorWidget
    Root --> CloseBtn
    Root --> ResetBtn
    Root --> SaveIndicator
    
    EditorWidget --> TextEdit
    EditorWidget --> InputHandlers
    
    %% Visual styling
    classDef base fill:#ffcccc,stroke:#333,stroke-width:1px
    classDef main fill:#ccffcc,stroke:#333,stroke-width:1px
    classDef ui fill:#ccccff,stroke:#333,stroke-width:1px
    classDef editor fill:#ffffcc,stroke:#333,stroke-width:1px
    
    class Screen base
    class NotepadWidget main
    class Root,BG,BGShadow,Frame,TitleBar,TitleText,CloseBtn,ResetBtn,SaveIndicator ui
    class EditorWidget,TextEdit,InputHandlers editor
```

## Keyboard Navigation System

This diagram shows how keyboard navigation works in the editor:

```mermaid
flowchart LR
    %% Keyboard navigation system
    subgraph Keys["Navigation Keys"]
        arrows["Arrow Keys"]
        homeend["Home/End Keys"]
        pagekeys["Page Up/Down"]
    end
    
    subgraph Handler["Key Handler"]
        process["ProcessKey()"]
        move["HandleCursorMovement()"]
    end
    
    subgraph LineManagement["Line Management"]
        split["SplitTextIntoLines()"]
        detect["GetCurrentLineInfo()"]
        target["Calculate Target\nPosition"]
    end
    
    subgraph CursorOps["Cursor Operations"]
        horiz["Horizontal\nMovement"]
        vert["Vertical\nMovement"]
        update["Update Cursor\nPosition"]
        scroll["Scroll to\nCursor"]
    end
    
    %% Connections
    arrows --> process
    homeend --> process
    pagekeys --> process
    
    process --> move
    
    move --> split
    split --> detect
    detect --> target
    
    target --> horiz
    target --> vert
    horiz --> update
    vert --> update
    update --> scroll
    
    %% Visual styling
    classDef keys fill:#ffcccc,stroke:#333,stroke-width:1px
    classDef handler fill:#ccffcc,stroke:#333,stroke-width:1px
    classDef lines fill:#ccccff,stroke:#333,stroke-width:1px
    classDef cursor fill:#ffffcc,stroke:#333,stroke-width:1px
    
    class arrows,homeend,pagekeys keys
    class process,move handler
    class split,detect,target lines
    class horiz,vert,update,scroll cursor
```

These diagrams provide a comprehensive visual overview of the QuickNotes mod architecture, workflows, and component relationships. They illustrate how the different modules interact to create a functional, persistent notepad in Don't Starve Together.