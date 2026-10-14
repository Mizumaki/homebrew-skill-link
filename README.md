# Skill Link

A small CLI that exposes agent skills kept across multiple source directories under one or more agent skill directories — e.g. Claude Code's `~/.claude/skills/` and Codex's `~/.agents/skills/` — via symlinks.

Useful when you maintain skills in several repos (personal, work, experimental) and want every agent you use to discover all of them without copying.

## Install

### Homebrew

The Formula lives in this repo and can be installed directly

```bash
brew tap Mizumaki/homebrew-skill-link
brew install skill-link
```

## Configuration

Create `skill-link.conf` at `${XDG_CONFIG_HOME:-~/.config}/skill-link/skill-link.conf` (`skill-link init` writes a template there). It uses three INI-style sections. Lines starting with `#` are comments.

- `[targets]` — skills directories that agents read. Every skill is linked into every target. At least one target is required; there is no default.
- `[dirs]` — parent directories whose subdirectories are each a skill.
- `[skills]` — single skill directories.

```
[targets]
# Claude Code
~/.claude/skills
# Codex
~/.agents/skills

[dirs]
~/Documents/dev/personal-skills/skills
~/Documents/dev/work-skills/skills

[skills]
~/Documents/dev/work/special-skill
```

Each direct subdirectory of a `[dirs]` path is linked as `<target>/<subdir>` in every target. Each `[skills]` path must itself contain `SKILL.md` and is linked as `<target>/<basename>`; otherwise `skill-link` prints a `[warn]` and skips it. Removing an entry from `skill-link.conf` makes the corresponding links stale-removal candidates on the next `sync`. Removing a target stops `skill-link` from managing that directory at all; links already there are left as they are.

Common targets:

| Agent | Target |
|---|---|
| Claude Code | `~/.claude/skills` (or `$CLAUDE_CONFIG_DIR/skills`) |
| Codex | `~/.agents/skills` |

### Namespacing skills with a prefix

Any entry in `[dirs]` or `[skills]` may be written as `<prefix> = <path>`. The resulting symlink is named `<prefix>:<basename>`, matching the way plugin-namespaced skills already appear to Claude Code. Prefixes are not allowed in `[targets]`.

```
[dirs]
personal = ~/Documents/dev/personal-skills/skills
work = ~/Documents/dev/work-skills/skills

[skills]
work = ~/Documents/dev/work/slack-helper
```

A `personal`-prefixed `[dirs]` entry whose path contains `tdd/` produces `<target>/personal:tdd`. Prefixes must match `[A-Za-z0-9_-]+`; `:` and whitespace are not allowed in a prefix. Unprefixed and prefixed entries with the same basename can coexist.

> [!NOTE]
> The prefix changes the **invocation name** (the directory name under the target, e.g. `personal:tdd`), but Claude Code's **skill recommender** surfaces skills by the `name:` field inside each `SKILL.md` frontmatter. Two skills whose `SKILL.md` both declare `name: tdd` will compete for the same recommendation slot even when their directories are `personal:tdd` and `work:tdd`. If you want a prefixed skill to also be recommended under its prefixed identity, edit `SKILL.md`'s `name:` to match (e.g. `name: personal:tdd`).

> [!NOTE]
> Whether Codex accepts `:` in skill directory names has not been verified.

## Usage

```bash
skill-link init      # create skill-link.conf from a template if it does not
                     # already exist
skill-link sync      # create symlinks in every target and remove stale
                     # symlinks whose source dir is no longer in conf
skill-link list      # show configured targets/dirs and per-target link status
skill-link clean     # remove only broken symlinks in every target
skill-link --version
skill-link --help
```

Editing files inside a linked skill takes effect immediately — no re-sync needed.

### `sync` vs `clean`

`sync` and `clean` both delete symlinks, but they use different criteria and cover different failure modes.

- `sync` removes **stale** links — those whose parent directory is no longer listed in `skill-link.conf`. It does not check whether the link target still exists on disk. Note that every symlink in a target counts, including ones placed by other tools in a shared directory such as `~/.agents/skills`; the confirmation prompt lets you abort.
- `clean` removes **broken** links — those whose target no longer exists, regardless of which `[dirs]` / `[skills]` entries `skill-link.conf` lists. It reads the conf only to find the targets, and does not prompt for confirmation.

This means there are cases `sync` cannot clean up by itself, and you need `clean` to finish the job:

- You deleted or renamed a single skill directory under a conf-listed parent. The symlink's parent path is still in conf, so `sync` leaves it alone, and the link creation loop never sees the old name, so it stays broken.
- You moved or renamed the parent directory itself. The recorded link parent still string-matches the (now stale) conf entry, so `sync` keeps the link; the link-creation phase just prints `[warn] ... not found, skipping.` and never relinks.

In both cases run `skill-link clean` to drop the broken links. (For the second case, also update `skill-link.conf` to the new path and run `sync` again.)

The split is intentional: a missing target can mean "the source is genuinely gone" or "an external drive is temporarily unmounted," so `sync` deliberately avoids deleting links just because the target is currently unreachable. `clean` is the explicit opt-in for that cleanup.

## License

MIT — see [LICENSE](LICENSE).
