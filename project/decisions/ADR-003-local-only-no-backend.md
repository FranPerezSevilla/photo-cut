# ADR-003: Local-only processing and no backend for MVP

- Status: Accepted
- Date: 2026-09-03

## Context

The core job requires selecting an image and producing a PDF. A backend would add
accounts, privacy risk, cost and operational work without improving that job.

## Decision

Process images and generate PDFs on-device. Do not add accounts, cloud sync,
remote image processing, analytics or a database in the MVP.

## Consequences

- The app works offline and has a strong privacy story.
- No cross-device history or cloud recovery.
- Purchase fraud protection is limited to the platform/store integration chosen
  later unless a dedicated post-launch ADR introduces server validation.
