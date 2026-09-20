# ADR-012 — Meter successful final PDF generation

## Status

Accepted — 2026-09-20

## Context

Photo Cut offers one complete use before a lifetime purchase is required. The
product flow contains several different operations that can create or hand off
PDF bytes:

1. Step 1 repeatedly creates preview PDFs while the user configures the job.
2. Entering final review creates the immutable final PDF.
3. The final review can share that PDF.
4. The final review can hand that same PDF to native printing.

Metering share or print would be both late and ambiguous: the final PDF already
exists at that point, and a user may reasonably share and print the same document
without that representing two paid uses. Metering Step 1 previews would make
normal configuration consume value before the user has committed to the result.

## Decision

- The monetized unit is a **successfully generated final review PDF**.
- Step 1 preview generation is always outside the allowance.
- The entitlement check happens immediately before the final
  `PrintJobDocumentFactory.build(...)` call.
- The free use is consumed only after that final build succeeds.
- A failed final build does not consume the allowance.
- Once the final PDF exists, review, share and native print do not consult or
  modify the allowance.
- An exhausted allowance prevents final PDF generation from starting.
- Lifetime entitlement bypasses the allowance completely.
- The free-use marker and cached lifetime flag are local device state.
- Android persists that state with SharedPreferences; iOS uses UserDefaults.
- A reinstall may clear the local free-use marker. Photo Cut has no account or
  backend solely to prevent that.
- A lifetime purchase is authoritative in the platform store and will be
  restored from the store in M4-T02.

## Consequences

The commercial boundary now matches the product boundary: "create another final
PDF" is the paid action. Share/print gateways remain simple output handoffs and
do not know about purchases.

The local free allowance is intentionally not fraud-proof. Preventing reinstall
resets would require identity/server infrastructure that conflicts with Photo
Cut's narrow, offline-first scope.
