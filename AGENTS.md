# AGENTS.md — dst-quicknotes (Don’t Starve Together mod)

This repo is a DST client-only mod written in Lua. Prefer small, verifiable changes and keep docs in-sync with code.

## Read First (SoT)
- `README.md`: feature set + user-facing behavior
- `docs/structure.md`: module responsibilities + directory map
- `docs/visual_architecture.md`: interaction / state / workflow diagrams
- `DEV_TEST_PLAN.md`: Scratch Editor MVP manual regression gate

## Repo Map (practical)
- `modmain.lua`: entry point; loads mod config; toggles and pushes the notepad screen
- `modinfo.lua`: metadata + mod configuration options (Workshop-facing)
- `scripts/notepad/*`: core logic (config, persistence, input/editing helpers)
- `scripts/widgets/*`: UI/screens; `notepadwidget.lua` is the main coordinator
- Scratch Editor (experimental): `scripts/widgets/scratch_editor.lua` + `scripts/scratch/util.lua`

## Guardrails / Invariants
- Feature flags must stay safe-by-default:
  - `USE_SCRATCH_EDITOR` default **Off**
  - `DEBUG_EDITOR` default **Off**
- Scratch Editor MVP assumes **byte indices (ASCII)**; IME is out of scope (see `DEV_TEST_PLAN.md`).
- DST UI APIs are stateful and sometimes absent; keep defensive nil checks and avoid hard crashes.
- Avoid new global state. If something must be exposed on `_G`, document the “why” in the module header.

## Verification (Definition of Done)
- There is no automated test suite in this repo.
- For Scratch Editor changes, run the full manual gate in `DEV_TEST_PLAN.md`.
- For stable QuickNotes path (TextEdit-based), do a smoke pass:
  - toggle open/close, type/edit, navigation keys, save persistence after reload/reconnect.

## Docs Hygiene
If you change module boundaries, input flow, or persistence format, update:
- `docs/structure.md` (text description), and/or
- `docs/visual_architecture.md` (diagrams)

