# AGENTS.md — Photo Cut operating contract

This file is the first and highest-priority repository instruction for every
coding agent. It applies to the entire repository unless a deeper `AGENTS.md`
explicitly narrows a directory.

## 1. Mission

Build a small, reliable Android/iOS app that turns one source image into a PDF
containing repeated copies at an exact physical size.

The core promise is:

> Select a photo, enter exact measurements, choose copies and paper, export PDF.

Optimise for correctness, clarity, privacy and a short path to release. Do not
turn Photo Cut into a generic editor, print-shop suite or cloud product.

## 2. Source-of-truth order

When information conflicts, use this order:

1. `AGENTS.md`
2. `project/product.md`
3. `project/architecture.md`
4. accepted ADRs in `project/decisions/`
5. `project/plan.json`
6. implementation and tests
7. PR/issue/chat history

Conversations and agent memory are never authoritative. Persist durable decisions
in the repository before relying on them.

## 3. Mandatory startup protocol

Run these commands before editing:

```bash
python3 tool/project.py doctor
python3 tool/project.py validate
python3 tool/project.py status
python3 tool/project.py next
```

Then read the selected task in full:

```bash
python3 tool/project.py show <TASK_ID>
```

Also read every product, architecture or ADR document referenced by that task.

## 4. Task selection and states

`project/plan.json` is canonical. Allowed task states are:

- `backlog`: defined but not yet selectable.
- `ready`: dependencies are done and an agent may take it.
- `blocked`: cannot proceed; `statusReason` must explain why.
- `awaiting_human`: a real-device, store-account or physical-print gate.
- `done`: acceptance criteria are implemented and verified.

There is intentionally no committed `in_progress` state. An open branch or PR
named after the task represents work in progress and cannot become stale in
`main`.

Select only one `ready` task whose `executor` is `agent`. Do not silently work on
future tasks. If adjacent work is essential, add a narrowly scoped task to the
plan first.

## 5. Branch, commit and PR protocol

Branch names:

```text
task/<TASK_ID>-short-kebab-description
```

Commit messages:

```text
<TASK_ID>: imperative summary
```

A PR must:

- mention exactly one primary task ID;
- explain the product-visible and technical change;
- map changes to every acceptance criterion;
- list commands actually run and their results;
- attach or link required evidence;
- update `project/plan.json` only when the task state truly changed;
- call out any human validation still required.

Use `.github/pull_request_template.md`. Do not claim a device, purchase, print or
store validation that did not happen.

## 6. Definition of done

A task may be marked `done` only when all of the following are true:

1. Every dependency is `done`.
2. Every acceptance criterion is satisfied.
3. Applicable task checks pass locally or in the declared CI runner.
4. Relevant unit/widget/integration tests were added or updated.
5. Documentation and ADRs reflect durable behaviour.
6. Required evidence exists.
7. The complete PR CI is green for the final head commit.
8. No unrelated refactor or dependency upgrade is hidden in the change.

Use:

```bash
python3 tool/project.py verify <TASK_ID>
```

The CLI checks the current operating system and refuses to treat skipped
platform checks as a complete verification. CI remains the final merge gate.

## 7. Architecture rules

- Flutter and Dart are the application stack.
- Target Android and iOS only unless an ADR changes the scope.
- Domain geometry must be pure Dart and independent of Flutter widgets/plugins.
- Physical lengths use explicit value types; never pass ambiguous naked doubles
  across domain boundaries.
- PDF dimensions use points: `points = millimetres * 72 / 25.4`.
- Platform/plugin calls live behind small interfaces so tests can use fakes.
- Keep state local and simple. Do not introduce BLoC, Riverpod, GetX, service
  locators, code generation or dependency injection frameworks without an ADR.
- No backend, account system, analytics, advertising SDK or remote image upload.
- No dependency may be added merely for convenience. Record why it is needed.
- Flutter and package upgrades are dedicated tasks, never incidental edits.

## 8. Product non-goals

Do not implement any of these unless `project/product.md` and the roadmap are
explicitly changed:

- free-form Canva-like canvas;
- multiple different source images on one sheet;
- text, stickers, filters or background removal;
- passport-compliance guarantees;
- direct integrations for specific printer brands;
- cloud sync, web dashboard or user accounts;
- subscriptions, ads or consumable credits;
- automatic face enhancement or generative AI.

## 9. Privacy, security and secrets

- Source images and generated PDFs remain local to the device.
- Never log image bytes, local paths, purchase tokens or personal metadata.
- Do not commit Apple certificates, provisioning profiles, Android keystores,
  signing passwords, API keys or store credentials.
- Secret material belongs in GitHub Environments/Secrets or local ignored files.
- Test assets must be synthetic, licensed for reuse or created for this repo.

## 10. Testing expectations

Use the cheapest reliable test first:

- pure unit tests for unit conversion and layout geometry;
- widget tests for form validation and navigation;
- integration tests for app flows using fake gateways;
- platform tests only for plugin/native behaviour;
- human checks only for physical printing, real purchases and store submission.

Geometry tests should compare numbers, not screenshots. PDF tests should inspect
page boxes and object placement where possible. Golden images are supplementary,
not proof of physical dimensions.

## 11. Human gates

The following cannot be asserted by an autonomous agent without evidence from a
real person/device/account:

- a physical 50 mm calibration square measured with a ruler;
- sandbox purchases on real Android/iPhone store accounts;
- final store listing review and submission;
- final bundle/application ID ownership confirmation;
- signing credentials and legal/tax account setup.

Set these tasks to `awaiting_human` and provide exact instructions.

## 12. Scope-control rule

When tempted to add “just one more feature”, ask whether it is necessary to make
this sentence work:

> One image, exact measurements, repeated copies, print-ready PDF.

If not, leave it out or create a post-launch backlog task.
