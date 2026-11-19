# Factory ARPG development conventions

Factory ARPG is developed in Godot 4.7.2. The repository is
`interneth3ro/factory-arpg` and its default branch is `main`.

## Git workflow

- Use traditional Git feature branches in the primary local checkout. Create
  Git worktrees or use Codex Worktree mode only at the owner's explicit request.
- Begin each implementation from a clean `main` synchronized with live remote
  `main`. Verify the checkout and preserve any owner changes that block setup.
- Create one focused feature branch per implementation. Work on one feature
  branch at a time in the primary checkout, which may stay on that branch
  while implementation is underway.
- Commit and push changes on the feature branch, then open a pull request
  targeting `main`. The owner performs final review, required Godot runtime
  acceptance, and merging. Never merge a PR automatically.
- Use [documentation sync](.agents/skills/documentation-sync/SKILL.md) before PR
  review to reconcile affected documentation on the same feature branch.
- Use a separate Codex conversation for [post-merge cleanup](.agents/skills/post-merge-cleanup/SKILL.md)
  only when the owner explicitly requests cleanup for a specific merged PR.
  Never retire the requesting conversation's attached checkout.

## Development and validation

- Keep changes small, focused and independently testable. Maintain stable,
  clearly defined interfaces and separate gameplay logic from presentation.
- Preserve approved gameplay and narrative decisions and keep narrative
  content independently editable when present.
- Add abstractions, managers and tooling only when they meet a demonstrated
  need. Obtain owner approval before adding third-party plugins.
- Obtain explicit owner authorization before launching Godot, executing scenes,
  running headless engine tests or performing performance probes. This applies
  to graphical and headless launches, including imports and benchmark runs.
- Static inspection and nonexecuting validation are permitted. Report the
  checks actually performed and their scope and limits. Identify any pending
  engine, headless or graphical verification.

## Preservation

- Preserve user-authored artwork and source assets, local settings, saves,
  uncommitted work and meaningful historical evidence. Treat unknown files as
  protected even if ignored or located in a cache or temporary directory.
- Verify ownership and preservation before destructive cleanup. Never stash,
  reset or discard owner files to make a checkout appear clean.
- Keep generated caches and temporary validation output out of Git. Prefer
  console output for routine checks. Obtain explicit publication approval and
  review privacy before committing historical evidence.
- During authorized cleanup, preserve verified, meaningful PR evidence outside
  any retiring checkout. If a ZIP is needed, place it in a verified surviving
  location without overwriting an existing archive. Include a manifest with PR
  provenance, original relative paths, sizes and SHA-256 hashes. Reopen the
  archive independently, check the exact safe entry set, read entries fully to
  verify integrity, and compare decompressed sizes and hashes with the originals.
  Recheck the source and verified destination immediately before any authorized
  source removal. Retain originals if anything is uncertain or fails. Saves,
  source assets, settings, secrets and unrelated personal files require an
  explicit owner decision about preservation.
