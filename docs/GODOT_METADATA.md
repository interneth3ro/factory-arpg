# Godot metadata policy

- Commit stable `.uid` sidecars for production resources that use them, such as
  GDScript files and shaders. Some Godot resources, including `.tscn` scenes
  and `.tres` resources, can store UIDs in the resource itself.
- Commit source-side `<asset>.import` files next to committed imported assets
  once Godot generates them. These files store import settings and can carry
  the asset UID. Keep generated caches, including `.godot/imported/`, ignored
  under `.godot/`. Leave `*.uid` and `*.import` out of global ignore rules.
- Preserve existing UID identities during renames and moves where possible.
  Move a `.uid` alongside its source and review import metadata and resource
  references when moving an imported asset. Never fabricate, regenerate, or
  rewrite UID values just to clear a validator finding.
- Review orphaned or suspicious sidecars with the owner. Never delete them
  automatically. Treat unknown and ignored files as protected.

See Godot's [UID guidance](https://godotengine.org/article/uid-changes-coming-to-godot-4-4/)
and [import process documentation](https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/import_process.html).

## Experiments

Keep production resources in their appropriate project directories. Use
`experiments/` for committed experiments and the Git-ignored `scratch/` for
disposable work. Keep playable experiments discoverable by Godot by keeping
them outside directories marked with `.gdignore`. Promote useful experiments
through an explicit reviewed change that includes the applicable metadata.

## Read-only validation

From the repository root, run the [validator](../tools/validate_godot_metadata.py)
with Python 3.7 or later and Git available.

```powershell
python tools/validate_godot_metadata.py
python tools/validate_godot_metadata.py --working-tree
```

The default checks all tracked paths and sidecar contents in the Git index. Stage
the source and sidecar together to check what a commit will contain. The
working-tree mode reads current files and includes unignored untracked files.
It excludes deleted files and ignores untracked files under `scratch/`.

The validator reports orphaned sidecars, missing expected script or shader UID
sidecars, and import metadata whose `[deps] source_file` disagrees with its
neighboring source path. Missing `.import` files for common asset formats are
informational because extension alone cannot establish import intent. Unusual
UID text or import declarations that cannot be interpreted are also
informational. Keep/skip imports can omit `source_file`. Missing-sidecar checks
skip hidden paths and paths under `.gdignore` in the selected snapshot.

Exit status `0` means no errors were found, `1` means the snapshot has findings
to review, and `2` means the check could not complete or arguments were
invalid. Resolve findings through review. The check covers a limited set of
built-in formats and does not run Godot, validate the UID registry or resource
references, inspect cache outputs, or change files or Git state.
