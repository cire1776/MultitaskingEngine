## Lint Stepper

The **Lint Stepper** is a terminal-based interactive debugger designed to visually step through the execution of **ULang hensions** (ULang comprehensions) and entity operations. It enables introspection into step-by-step execution, context changes, and entity output, helping developers understand and debug their logic in a clear and structured way.

## 🌿 Project Philosophy

This debugger is part of the broader ULang ecosystem. It emphasizes:
- **Structured panes** for clarity.
- **Clean UI-MVC separation** to enable future migration to GUI or web.
- **Context-aware presentation**, where logic and UI are decoupled through presenters.

---

## 🧱 Project Structure

```plaintext
Sources/lint_stepper/
├── Application/              <- Entry point (`@main`), renders and routes commands.
├── Extensions/               <- Utility extensions (e.g., ANSI-safe string handling).
├── Model/                    <- Debugger state model (`LintDebugger`).
├── Panes/                    <- Individual visual panes (History, EC, Next, etc).
├── Presenters/               <- Presenter layer, formats and exposes model state to panes.
├── TUI/                      <- Terminal handling (raw mode, key input, ANSI rendering).
├── UI/                       <- Focus, pane switching, and navigation logic.
```

### ✅ **Application**
- `list_stepper.swift`: Main loop. Receives input, executes commands, triggers rendering.

### ✅ **Model**
- `lint-debugger.swift`: Owns execution state, capture control, step logic, and highlighted steps.

### ✅ **TUI**
- `text_ui.swift`: Runs the key loop and communicates with the model through Commands.
- `terminal_state.swift`: Raw terminal input, ANSI key decoding, screen utilities.

### ✅ **UI**
- `ui_controller.swift`: Tracks current pane focus and selection states.
- `focus_navigator.swift`: Cycles across **main panes** (`history`, `ec`, `next`).
- `focus_sub_pane_navigator.swift`: Cycles within **subpanes** (`lint`, `output`).

### ✅ **Presenters**
- E.g., `execution_contextPanePresenter.swift`, `render_rows.swift`
- Presenters hold formatting and visibility logic—no model mutation.
- They expose visible rows and EC state based on selection in `UIController`.

### ✅ **Panes**
Each `Pane` conforms to `Pane`, and optionally:
- `HorizontallyScrollable`
- `VerticallyScrollable`
- `HasSelection`

Examples:
- `lint_pane.swift` → Shows lint label history
- `output_pane.swift` → Shows output text for each step
- `execution_contextPane.swift` → Shows EC snapshot per step

---

## 🔄 Input Keys

| Key           | Action                             |
|---------------|------------------------------------|
| `n`           | Step to next lint                  |
| `c`           | Capture mode (run until end)       |
| `space`       | Pause/resume capture               |
| `r`           | Reset debugger                     |
| `q`           | Quit                               |
| `tab`         | Cycle forward through panes        |
| `shift-tab`   | Cycle backward through panes       |
| `[` / `]`     | Move between subpanes              |
| Arrow Keys    | Navigate selections and scroll     |
| `command-.`   | Interrupt capture (macOS)          |

---

## 🧠 Design Highlights

### Pane Rendering Model

Each pane is responsible for rendering itself in a defined `rect`:
- **Only the content area** is passed (no borders).
- Panes do not own borders—they’re handled by the layout manager or `list_stepper.swift`.

### Pane Selection & Navigation

- Focus state is held in `UIController`.
- Presenters derive the data needed to render the selected step, including scrolling offsets and EC state.

### Step Results & Highlighting

- Each step generates a `StepResult`.
- Steps captured via `c` are marked in `highlightedStepIds` and drawn with a **celadon background**.
- Currently selected step is drawn with ANSI inverted colors.

---

## 🚧 In Progress / Vision

- 🔜 Collapsible widgets for non-focused panes.
- 🔜 GUI support using SwiftUI (keeping model/presenter separation).
- 🔜 Nested pane groups (multi-layered views).
- 🔜 Diff viewer between execution contexts.
- 🔜 Keyboard focus manager.

---

## 🤝 Contributing

This tool is part of the broader ULang vision. Contributions are welcome, especially in:

- Improving presenter abstraction
- Exploring visual diffs of Execution Contexts
- GUI migration support
- Formalizing protocol hierarchies for panes

---

## 🐛 Debugging Tips

- Use `print(renderedOutput)` with ANSI codes stripped if terminal layout is failing.
- Use `Command + .` to escape infinite loops in capture mode.
- Keep `highlightedStepIds` consistent—clear it before `n` and `c`.

---

## 📜 License

MIT. Open source, built with love for exploring what programming *could be*.

---

Happy stepping! 🐾

