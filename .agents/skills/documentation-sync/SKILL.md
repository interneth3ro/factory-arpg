---
name: documentation-sync
description: Reconcile Factory ARPG documentation with a specified feature branch, diff or pull request, normally before PR review. Preserve approved gameplay and narrative decisions and flag conflicts for the owner.
---

# Documentation sync

Use for a specified feature branch, diff or PR in `interneth3ro/factory-arpg`.
Update affected documentation on the same feature branch, normally before PR
review. For a dry run, propose edits in the response without writing files.

1. Read [AGENTS.md](../../../AGENTS.md) and [README.md](../../../README.md).
   Inspect the branch and status, the scoped diff against its actual base
   (usually `main`), and the affected code and existing documentation.
   Preserve unrelated changes.
2. Locate the existing authoritative records affected by changes to behavior,
   interfaces, ownership, setup or validation. Make minimal, factual edits and
   link to existing specifications where useful. If an authoritative design
   document is absent, use the relevant records available and report evidence
   gaps. Create a document only for a concrete documentation need within scope.
3. Distinguish approved design, unresolved proposals and implemented behavior.
   Identify feature-branch behavior as pending merge. Describe what the evidence
   verifies, including any gaps in player access or narrative completion.
   Preserve established gameplay and narrative decisions. Flag conflicts and
   missing decisions for the owner, and leave approval and design resolution
   to them.
4. Preserve historical evidence and avoid cosmetic churn. If the scoped change
   affects no documentation, explain why. For a post-merge request, verify the
   live PR merge and inspect current `main` before claiming delivery. Make any
   authorized correction on a feature branch.
5. Validate changed Markdown links and anchors, run `git diff --check` on the
   relevant changes, and review final changed-file scope. Reuse validation
   evidence with its provenance and limits. Follow AGENTS.md for explicit
   owner authorization of any Godot execution.

Report changed or proposed files, supporting evidence, validation limits and
unresolved decisions in the response. Keep the work scoped to documentation.
Merging, cleanup, unrelated edits and external writes require separate
authorization. Avoid separate reports and duplicate specifications.
