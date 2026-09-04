# Photo Cut

Photo Cut is a small Flutter app for printing one photo at an exact physical size.
The user selects an image, enters its width and height, chooses a paper size and
copy count, and receives a print-ready PDF.

> One image + exact measurements + number of copies -> a correctly laid-out PDF.

The product is deliberately narrow: no account, no cloud, no ads, no AI and no
subscription. The planned commercial model is one free export followed by a
single lifetime purchase.

## Current state

Photo Cut can select a real image, configure exact geometry, choose crop-to-fill
or fit-inside, adjust the focus and preview app-owned colour or grayscale. The
repository remains in **M2 — Usable MVP flow**; the next task builds the final
read-only PDF review, sharing and explicit native print handoff.

The canonical status is always [`project/plan.json`](project/plan.json), not a
chat transcript, issue board or agent memory.

## Start here

Every human or coding agent must follow this order:

```bash
cat AGENTS.md
python3 tool/project.py doctor
python3 tool/project.py status
python3 tool/project.py next
```

With Flutter 3.47.2 installed:

```bash
flutter pub get
flutter test
flutter run
```

Android and iOS platform folders are committed. If either is ever lost, restore
them deterministically with:

```bash
bash tool/bootstrap_platforms.sh
```

## Useful project commands

```bash
python3 tool/project.py validate
python3 tool/project.py status
python3 tool/project.py next
python3 tool/project.py show M2-T04
python3 tool/project.py verify M2-T04
python3 tool/project.py render-status
```

## Repository map

```text
AGENTS.md                  Agent operating contract
lib/                       Flutter application code
project/product.md         Product scope and non-goals
project/architecture.md    Technical boundaries
project/plan.json          Canonical milestone/task state
project/decisions/         Architecture decision records
project/evidence/          Evidence policy and durable small artifacts
store/                     Store identity, products and future metadata
tool/project.py             Task/status CLI
.github/workflows/ci.yml   Android/iOS verification
.devcontainer/             Reproducible Flutter development environment
```

## Product constraints

- Android and iPhone from one Flutter codebase.
- Exact PDF geometry is more important than visual flourishes.
- Images stay on-device.
- The app must remain useful offline.
- Printer drivers may still scale output; the app will make that risk explicit
  and provide a calibration sheet.
- Changes outside the active task require a new task or an ADR.

## Ownership and licence

This is a commercial, source-visible project. See [`LICENSE`](LICENSE). No
permission to reuse or redistribute the code is granted by the public repository.
