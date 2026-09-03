# ADR-001: Use Flutter for Android and iOS

- Status: Accepted
- Date: 2026-09-03

## Context

Photo Cut needs a small shared mobile UI, deterministic geometry, PDF generation,
photo selection, printing and non-consumable purchases on Android and iOS. The
project will be implemented mainly by coding agents, so one typed codebase and
repeatable tests are valuable.

## Decision

Use Flutter 3.47.2 and Dart 3.13.2 for the app. Keep geometry in pure Dart and
native/plugin behaviour behind interfaces.

## Consequences

- One codebase and shared widget/unit tests.
- Android and iOS platform folders still require native configuration and CI.
- iOS compilation/signing requires macOS and Apple credentials.
- Framework upgrades are explicit roadmap tasks.
