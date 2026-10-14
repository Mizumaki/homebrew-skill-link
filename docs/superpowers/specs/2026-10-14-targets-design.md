# Multi-target support (`[targets]`) design

## Goal

Let `skill-link` link the same set of skills into several agent skill
directories (e.g. Claude Code `~/.claude/skills`, Codex `~/.agents/skills`)
without treating any agent as the default. Backward compatibility is not
required.

## Configuration

- Location: `${XDG_CONFIG_HOME:-$HOME/.config}/skill-link/skill-link.conf`.
  `CLAUDE_CONFIG_DIR` is no longer consulted. Legacy `skill-dirs.conf`
  detection is removed.
- Sections: `[targets]`, `[dirs]`, `[skills]`.
- `[targets]`: one path per line. The `<prefix> = <path>` form is an error
  inside `[targets]`.
- A conf without any `[targets]` entry is an error (no default target).

```
[targets]
~/.claude/skills
~/.agents/skills

[dirs]
superpowers = ~/Documents/dev/superpowers/skills

[skills]
~/Documents/dev/work/special-skill
```

## Commands

- `init`: creates the XDG conf (and its parent dir) from a template.
  The template lists `~/.claude/skills` and `~/.agents/skills` as
  commented-out examples under `[targets]`.
- `sync`: collects stale links across all targets, asks for confirmation
  once, removes them, then links every skill into every target
  (`mkdir -p` on each target). Link naming rules are unchanged and shared by
  all targets.
- `list`: prints configured targets, dirs, skills, then the link status per
  target.
- `clean`: reads the conf and removes broken symlinks in every target.

## Implementation notes

- `get_entries` additionally emits `target` records.
- `_link_one` takes the target directory as an argument; the global
  `SKILLS_DIR` goes away.

## Testing

- `tests/test_helper.bash` pins `XDG_CONFIG_HOME` inside the sandbox HOME and
  writes a `[targets]` section by default.
- `tests/claude_config_dir.bats` is removed; `tests/targets.bats` covers
  multi-target linking, missing targets, per-target stale removal, prefix
  rejection in `[targets]`, and `clean` across targets.

## Out of scope

- Per-entry target selection.
- Excluding third-party links in shared dirs such as `~/.agents/skills` from
  stale detection.
- Whether Codex accepts `:` in skill directory names (unverified).
- Version bump.
