# ADR-002: The repository is the project control plane

- Status: Accepted
- Date: 2026-09-03

## Context

Implementation may pass between different coding agents. Chat history, hidden
memory and external boards cannot reliably transfer state.

## Decision

Store product scope, architecture, decisions, task state, verification commands,
store metadata and release configuration in Git. `project/plan.json` is the
canonical task state and `tool/project.py` is the common interface.

## Consequences

- Any agent can discover the next task from a clone.
- Status changes are reviewable in Git history.
- The plan must stay small and honest; it is not a substitute for source code.
- Secrets remain the sole intentional exception and live in protected stores.
