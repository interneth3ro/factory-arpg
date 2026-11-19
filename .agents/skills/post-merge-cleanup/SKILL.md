---
name: post-merge-cleanup
description: Safely synchronize main and retire verified feature branches for an explicitly requested merged PR number in interneth3ro/factory-arpg. Branch-only development is the default; retain all safety gates for historical or explicitly authorized worktrees. Stop on uncertain preservation, incorporation, chat attachment or applicable Windows locks.
---

# Post-merge cleanup

Invoke only in a separate cleanup conversation when the owner explicitly requests
cleanup for a specific PR number in `interneth3ro/factory-arpg`. Read the
preservation and ZIP policy in [AGENTS.md](../../../AGENTS.md). Limit the work to synchronizing and retiring
verified targets. Merging, implementing follow-up work and archiving conversations
are outside this skill. Use ordinary Git and available read-only inspection tools.

Establish and record which case applies before making changes. Expect branch-only
development and confirm it using the evidence below.

- **Branch-only development (Case B, expected).** Require reliable development/session
  history establishing that no separate feature worktree was created, corroborated
  by current worktree registrations and checks that no associated residual
  directory exists. An empty registration list for the feature, a missing path or
  unknown history alone is insufficient. Uncertainty blocks cleanup. Never create
  a worktree to satisfy these checks. Worktree retirement and directory-specific
  handle inspection are not applicable. Retain every PR, incorporation, fresh
  local/remote branch-tip, clean-state, preservation, fast-forward-only, guarded
  branch-deletion and conversation archival reporting requirement below.
- **Associated worktree (Case A).** Apply all worktree identity, preservation,
  session-attachment, Windows handle-inspection and safe retirement gates below.

## Establish identity before mutation

1. Retrieve live GitHub PR URL/number, merged status/time, base/head repositories,
   base/head branch names, historical head SHA and merge SHA. Require merged into
   this repository's `main`, with the head in this repository too. Closed without
   merge, forks, missing metadata or ambiguous historical identity stop cleanup.
   Reject `main` or any protected/default branch as a feature retirement target.
2. Resolve canonical absolute Git roots/common directories and
   `git worktree list --porcelain`. Identify the surviving primary checkout on
   `main` or, in Case B, still on the exact historical feature branch pending the
   guarded switch in step 6. Identify that feature branch. In Case A identify the
   feature worktree by registered branch and HEAD. Verify that both roots share
   the expected Git common directory. In Case B verify that no separate worktree
   uses the branch. Resolve path casing and aliases on Windows. Stop for uncertain
   links or overlapping roots. Verify both origin URLs identify this repository.
   Check fetch refspecs
   and configuration for unexpected ref updates/pruning. Do not touch unrelated
   repositories, worktrees, branches, preservation refs, tags or snapshots.
3. Establish the requesting chat's current attached checkout using supported
   current-chat metadata. Historical artifact lists, shell cwd and command
   `workdir` cannot establish attachment. If metadata is unavailable, stop for the owner's
   explicit confirmation of this chat's exact attached checkout. Require this chat
   at the verified surviving primary checkout in Case B. In Case A require it outside
   the retiring root (and its descendants). If self-attached, retain everything
   and request cleanup from a chat based at the verified surviving primary checkout.
   Changing shell cwd does not relocate the chat or persistent MCP/REPL servers.
4. Record local/live `main` and feature tips plus relevant preservation refs.
   Every surviving feature tip must equal the historical PR head. A changed/reused
   branch, ambiguous detached checkout, locked/missing expected registration or inaccessible
   path blocks retirement. If targets are already absent, verify historical identity
   and actual absence. Leave them absent. An unregistered residual directory blocks
   cleanup until its ownership and preservation are resolved.

## Verify incorporation and synchronize

5. After these gates, fetch narrowly without pruning or tags, for example
   `git fetch --no-prune --no-prune-tags --no-tags origin refs/heads/main:refs/remotes/origin/main`.
   Require the recorded merge result reachable from fresh `origin/main`.
   For a normal merge also verify the historical head is incorporated.
   For squash/rebase, obtain the original PR base/commits and exact incorporated
   delta/series; compare stable patch IDs or `git range-diff` **and review actual
   diffs**. Merge-commit ancestry alone does not prove squash/rebase equivalence.
   Explain conflict resolutions and later changes. Stop retirement for unavailable
   history, unexplained differences or reverted/absent work. Never undo later edits.
6. Require clean tracked state in every affected checkout (the primary only in
   Case B), no in-progress Git operations, and local `main` equal to or an ancestor
   of fetched `origin/main`.
   Inspect the incoming diff and exact destination paths/ancestors for untracked
   or ignored collisions and protected local assets, settings, saves and evidence.
   Git can overwrite ignored files even when tracked status is clean.
   Do not recursively scan unrelated primary material. Stop on collisions,
   inaccessible paths, links/reparse points or uncertain preservation.
   In Case B, if the primary checkout remains on the verified historical feature
   branch, use `git switch --no-overwrite-ignore main` only after the preceding
   identity, incorporation, attachment and preservation checks pass.
   Before switching, inspect the feature-to-local-main diff and its exact
   destination paths/ancestors for the same untracked/ignored collisions and
   protected material described above. Stop on any preservation uncertainty or
   switch refusal. Leave unrelated branches alone. Recheck clean tracked state
   and inspect incoming paths and preservation again after switching.
   From the verified primary checkout on `main`, run
   `git merge --ff-only --no-overwrite-ignore origin/main` (equal tips are a no-op). Never stash, reset
   or force-update `main` to make this succeed. Case A still requires the primary
   checkout already on `main`.

## Preserve material and establish retirement safety

7. In Case A inspect the feature worktree's untracked and ignored material with
   compact queries such as
   `git ls-files --others --exclude-standard --directory -z` and the same query
   with `--ignored`. Parse NUL-delimited paths safely. Inspect filesystem entries
   along indexed directories for Git-invisible/empty material, nested repositories,
   submodules, links/junctions and access failures. Git output alone is insufficient.
   Expand only flagged paths needed for a preservation decision. Any unknown material blocks removal.
   In Case B there is no feature directory to inventory or remove. Preserve all
   material in the surviving checkout; retain step 6's collision checks and step 8's
   preservation policy. Do not classify primary material as disposable or create a
   ZIP merely because a feature branch is being retired.
8. Preserve saves, source artwork, settings, tools and unverified evidence. Ignore
   status, extensions or cache names (including `.godot/`) prove no disposal right.
   Archive only verified meaningful PR evidence under AGENTS.md's ZIP policy,
   outside the retiring checkout. Verify contents, integrity and unchanged originals
   before exact eligible source retirement. No meaningful evidence means no ZIP.
   Remove disposable output only when it is proven task-owned, regenerable and
   within the authorized cleanup scope.
   Use native PowerShell literal paths for exact file operations; verify resolved
   targets and ancestors remain in the intended root. Never recursively delete a
   checkout or unknown directory. Stop for clarification on uncertain preservation. Report retained paths without disclosing private file contents.
9. Immediately before retirement, require quiescence and fresh chat-attachment,
   local and live branch-tip, HEAD, registration, tracked-state and material checks
   in both cases.
   In Case B confirm there is still no associated worktree or residual path. Concurrent writers or uncertain quiescence still block branch retirement.
   In Case A on Windows use an already available read-only handle inspection tool
   covering the exact root and descendants, including directory cwd owners and relevant
   file handles. Record tool/method, scope, owners and coverage limits in the
   response. Process names or a lack of Git locks do not establish lock safety.
   Known locks, incomplete access/coverage, concurrent writers or unavailable
   inspection tools stop Case A retirement of the worktree **and branches**.
   Do not kill processes, close handles remotely or bypass app removal guards.
   Apply the Git removal check after all preceding checks pass.

## Retire only verified targets and verify the result

10. In Case B report worktree retirement as not applicable and proceed to step 11
    only after all applicable gates pass. In Case A, from a surviving directory,
    run `git worktree remove <exact-feature-path>`
    without force, only after all gates pass. Never remove the primary checkout,
    requesting chat's checkout or a containing directory. On refusal or partial
    removal stop and retain branches. Inspect and report registration and residual
    path state. Never fall back to recursive deletion, forced removal or pruning.
11. Recheck exact local feature tip and that no registered worktree uses it.
    Use `git branch -d <feature-branch>` when the historical head is an ancestor
    of synchronized `main`. For verified squash/rebase equivalence without head
    ancestry, first establish that no unique work remains, then compare-and-delete
    with `git update-ref -d refs/heads/<feature-branch> <historical-head-sha>`.
    Select the operation before attempting deletion. Any refusal stops cleanup.
    Never use `git branch -D`.
    Recheck the remote feature tip. If still the historical head, delete with an
    exact lease: `git push --force-with-lease=refs/heads/<feature-branch>:<historical-head-sha>
    origin :refs/heads/<feature-branch>`. Never retry a rejected lease with a new
    expected SHA or unguarded force. Already-absent branches are no-ops.
12. Verify live `main`/feature tips, local `main` equality to current remote,
    incorporation, expected worktree/branch absence, clean tracked primary state
    and unchanged preservation refs/material. If live `main` moved, reassess rather
    than claiming equality to stale tracking refs. Do not routinely prune refs or
    worktree registrations. Missing targets are repeatable no-ops only after all
    applicable identity and incorporation checks. Unresolved residuals remain blockers.

Never use blanket `git clean`, hard resets, forced worktree removal or destructive
shortcuts. Do not launch Godot or run save-writing checks as part of cleanup.
Stop on any failure. Retain remaining targets and report any partial completion.
If quiescence cannot be established, preserve the target and report the uncertainty.

Report PR/merge/head identity, primary/local/live `main` state, exact worktree and
branch outcomes, preserved material/archive verification, checks and limitations,
and any blocker with the action needed to resolve it. Do not generate a separate
report file. Distinguish completed phases, intentional no-ops and pending work.

## Conversation archival eligibility

Every final cleanup report, including blocked or partial results, must include a
**Conversation archival eligibility** section. Identify the original feature
conversation and the separate cleanup conversation. Assess each independently
and give one of the following outcomes for each.

- **Safe to archive** if the original feature PR is merged, its changes are verified
  as incorporated, the local/remote feature branches are safely retired or
  verified absent, any associated feature worktree is safely retired or verified
  absent (not applicable in Case B), and no unresolved preservation or session
  dependencies remain for the conversation being assessed.
- **Not safe to archive** if cleanup is incomplete or blocked, or known dependencies
  remain for the conversation being assessed.
- **Requires owner review** if cleanup status or the conversation's identity,
  attachment or preservation state cannot be established confidently. This
  includes uncertainty about the original feature conversation even when the
  separate cleanup conversation's state is known.

Give the evidence and reasoning supporting each result, remaining blockers and
what would resolve them. In Case B, the feature conversation remaining attached to
the surviving primary checkout does not itself prevent safe archival once all
relevant preservation, Git and session dependencies are resolved. Do not require
directory-specific Windows handle inspection when no directory is retired.
The owner decides whether to archive either conversation after reviewing its
session dependencies and cleanup outcome.
