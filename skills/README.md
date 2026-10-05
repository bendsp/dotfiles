# Skills

This directory is the versioned source of truth for personal agent skills.

## Layout

- `shared/` contains personal skills and skills managed with `pnpx skills`. `~/.agents/skills` links to this directory.
- `.skill-lock.json` is the global `pnpx skills` registry. `~/.agents/.skill-lock.json` links to it.
- `THIRD_PARTY.md` records upstream sources and license status.
- `licenses/` contains notices required when the vendored skills are redistributed.
- `audit.sh` checks skill structure and common private-data mistakes before publication.

OpenAI-provided Codex skills remain outside this repository. Personal skills belong here. The personal `tmux` skill lives in `shared/tmux`, with `~/.codex/skills/tmux` linked to it by the installer.

## Updating shared skills

Use the pinned CLI version so updates behave consistently across machines:

```bash
pnpx skills@1.5.23 list -g --json
pnpx skills@1.5.23 update -g -y
./skills/audit.sh
git diff -- skills
```

`pnpx skills` replaces complete skill directories during updates. Do not keep personal edits inside an upstream-managed skill. Copy it under a new name or maintain a fork instead.

The vendored `ai-seo` skill has one packaging compatibility patch: its repository-relative `../../tools/REGISTRY.md` link points to the upstream GitHub file instead. A full upstream update may overwrite this line; `./skills/audit.sh` will then reject the link for escaping the shared skill root.

## Installing the links

Run the repository installer:

```bash
./install.sh
```

The installer preserves a pre-existing real file or directory as `<path>.bak`. It refuses to overwrite an existing backup.
