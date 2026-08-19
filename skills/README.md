# Skills

This directory is the versioned source of truth for personal agent skills.

## Layout

- `shared/` contains skills managed with `npx skills`. `~/.agents/skills` links to this directory.
- `.skill-lock.json` is the global `npx skills` registry. `~/.agents/.skill-lock.json` links to it.
- `THIRD_PARTY.md` records upstream sources and license status.
- `licenses/` contains notices required when the vendored skills are redistributed.
- `audit.sh` checks skill structure and common private-data mistakes before publication.

Everything under `~/.codex/skills`, including feature-provided and locally installed Codex skills, remains outside this repository. This avoids assuming that Codex installers or updaters preserve symlinks.

## Updating shared skills

Use the pinned CLI version so updates behave consistently across machines:

```bash
npx --yes skills@1.5.23 list -g --json
npx --yes skills@1.5.23 update -g
./skills/audit.sh
git diff -- skills
```

`npx skills` replaces complete skill directories during updates. Do not keep personal edits inside an upstream-managed skill. Copy it under a new name or maintain a fork instead.

## Installing the links

Run the repository installer:

```bash
./install.sh
```

The installer preserves a pre-existing real file or directory as `<path>.bak`. It refuses to overwrite an existing backup.
