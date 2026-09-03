# Evidence policy

Small durable evidence belongs here when it helps a future agent understand a
completed decision or human validation. Examples include a calibration result in
Markdown or a licence review.

Large/generated artifacts—APKs, iOS build folders, coverage HTML and PDFs—belong
in GitHub Actions artifacts or releases, not ordinary Git history. A task should
record the workflow/commit that produced them in its PR.

Local-only evidence goes under `project/evidence/local/`, which is ignored.
