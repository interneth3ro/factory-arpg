---
name: pre-merge-verification
description: Verify an explicitly identified Factory ARPG pull request after owner runtime acceptance and before the owner's manual merge. Check acceptance against the live PR head, Godot metadata, documentation, static integrity, and preservation.
---

# Pre-merge verification

Use for a specific PR in `interneth3ro/factory-arpg` after the owner confirms
applicable runtime acceptance. Read [AGENTS.md](../../../AGENTS.md), the
[Godot metadata policy](../../../docs/GODOT_METADATA.md), and the
[documentation index](../../../docs/README.md). The owner makes the final
merge decision.

## Establish PR and checkout identity

1. Require a PR number or URL explicitly supplied by the owner. Retrieve live
   GitHub data and record the canonical number and URL, base and head
   repositories and branches, current base and head SHAs, and open and merged
   status. Require an open, unmerged PR targeting `interneth3ro/factory-arpg:main`.
   Resolve the exact head repository and feature branch. Stop for any mismatch
   or ambiguity.
2. Verify the primary checkout root, checked-out feature branch, matching remote,
   and local HEAD against the live PR head. Inspect staged, unstaged, and
   untracked paths and check for in-progress Git operations such as a merge or
   rebase. Stop for unexpected operations, unrelated changes, or a checkout
   mismatch. Use the existing checkout and feature branch.

## Establish owner acceptance

3. Require explicit owner confirmation that applicable runtime acceptance passed.
   Record the tested commit or identifiable snapshot, coverage, and any owner
   exceptions or limitations. For a PR with no applicable runtime checks, require
   the owner to confirm that disposition. If confirmation is missing, stop.
4. Compare the accepted snapshot with the live head and review any local changes
   intended for housekeeping. Changes affecting tested gameplay, collision,
   scene execution, or any other accepted functionality require renewed owner
   acceptance. Documentation-only or metadata-only changes may retain acceptance
   when the actual diff and affected references demonstrate unchanged runtime
   behavior. Check whether base changes create a material integration difference
   for the accepted behavior. Ask the owner to review any uncertainty about the
   tested snapshot or the applicability of acceptance. A PR or passing static
   checks alone cannot establish runtime acceptance.

## Verify the final changes

5. Check required script and shader UID sidecars, applicable source-side import
   metadata, and UID continuity for moves. From the repository root run both
   `python tools/validate_godot_metadata.py` for the staged index and
   `python tools/validate_godot_metadata.py --working-tree`. Review informational
   findings as well as errors. A required sidecar can be missing even when the
   validator exits successfully. Report missing required sidecars and request an
   authorized Godot import. Preserve existing UID values and never fabricate,
   regenerate, or overwrite them to clear findings.
6. Apply [documentation sync](../documentation-sync/SKILL.md) to the verified PR.
   Use its dry-run workflow if edits are outside the owner's scope. Confirm that
   implementation documentation reflects the PR and that frozen specifications
   and decision records remain consistent with approved gameplay and narrative
   decisions. Keep edits focused and stop for unapproved design changes.
7. Select static checks based on the actual diff. Inspect affected scene and
   resource references, script dependencies, and Input Map entries where relevant.
   Run applicable repository validators and Git whitespace checks for the PR
   range and any staged or unstaged housekeeping. Review reported errors and
   warnings, including relevant PR checks where available. State which checks
   ran and their limits. Claims about Godot parsing or runtime require actual
   authorized execution with evidence for the relevant snapshot.
8. Review the live PR diff from its actual base, including the changed-file
   list. For a local comparison, use the merge base of the verified base and
   head SHAs so the comparison matches GitHub. Compare the PR diff with the
   staged and unstaged diffs and inspect untracked paths. Identify any unexpected
   files or protected owner material. Preserve unrelated work and stop if
   preservation is uncertain.

## Finalize authorized housekeeping

9. If authorized, make only scoped housekeeping corrections. Inspect the exact
   staged paths and contents before committing them on the existing feature
   branch. Rerun affected checks after changes, including both metadata modes
   for metadata corrections, and reassess runtime acceptance. Before an ordinary
   push, confirm that the live branch still points to the verified starting head.
   Stop for any concurrent update or push rejection. Never force-push or change
   gameplay to make verification pass.
10. Refresh the live PR state, base, and head before reporting, including on
    read-only runs. For a push, confirm the live PR head equals the verified
    local commit. If the base or head changes, reassess the affected checks and
    acceptance before issuing a result. Recheck local status and final diff scope.

Throughout verification, never merge or close the PR, switch to an unrelated
branch, delete branches or worktrees, or perform post-merge cleanup. Never stash,
reset, delete, or overwrite unrelated work. Launching Godot requires explicit
owner authorization under AGENTS.md.

## Report

Return one verdict.

- **PASS** when the checks are satisfactory and owner acceptance applies to the
  verified head. Recommend it for the owner's final merge decision and report
  any remaining GitHub merge prerequisites.
- **BLOCKED** when a required check or prerequisite fails or cannot be verified,
  including ambiguous PR identity or missing acceptance.
- **REQUIRES OWNER REVIEW** when renewed acceptance, a design decision, or another
  owner judgment is needed before recommending merge.

Include the PR number and URL, verified head SHA, base branch and checkout
identity, owner acceptance and whether it remains valid, metadata, documentation
and static check results, housekeeping files, outstanding findings and limits,
and a clear merge-readiness recommendation. Identify checks that could not be
completed on early exit. Report in the conversation unless the owner requests
a separate file.
