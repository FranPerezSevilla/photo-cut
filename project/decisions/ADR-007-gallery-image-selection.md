# ADR-007: Select one gallery image through an app-owned gateway

- Status: Accepted
- Date: 2026-09-04

## Context

Photo Cut needs one source image while remaining local-only and resilient to the
Android activity being destroyed while the operating-system picker is open. The
feature layer must not depend directly on plugin types or retain provider paths.

## Decision

Use `image_picker` exactly at version `1.2.3` behind `ImagePickerGateway`.

- Publisher: `flutter.dev`
- Runtime network access: none required by Photo Cut
- Requested source: the system gallery only
- Full metadata request: disabled
- Lost-data recovery: attempted once when the first screen starts
- Package notices: Apache-2.0 and BSD-3-Clause metadata are retained in release
  dependency records

The production adapter reads the selected `XFile` into memory immediately,
stores only copied bytes plus a display-safe basename, and discards the provider
path. Cancellation is a normal result rather than an error. Plugin failures are
translated into short user-readable messages without logging private paths or
bytes.

## Consequences

- Feature and domain code import only the app-owned gateway and result types.
- Tests use synthetic bytes and fake gateways; they never invoke a real gallery.
- Android `retrieveLostData()` is checked once per screen lifetime.
- iOS declares a truthful photo-library usage description.
- Selected bytes live only in the short-lived print-job flow and are not uploaded
  or persisted by this task.
