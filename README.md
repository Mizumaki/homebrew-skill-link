# Skill Link

A small CLI that exposes Claude Code skills kept across multiple source directories under a single `~/.claude/skills/` tree via symlinks.

Useful when you maintain skills in several repos (personal, work, experimental) and want Claude Code to discover all of them from one place without copying.

## Install

### Homebrew

The Formula lives in this repo and can be installed directly

```bash
brew tap Mizumaki/homebrew-skill-link
brew install skill-link
```

## Configuration

Create `skill-link.conf` inside your Claude config directory (defaults to `~/.claude`, override with `CLAUDE_CONFIG_DIR`). It uses two INI-style sections — `[dirs]` for parent directories whose subdirectories are each a skill, and `[skills]` for single skill directories. Lines starting with `#` are comments.

```
[dirs]
~/Documents/dev/personal-skills/skills
~/Documents/dev/work-skills/skills

[skills]
~/Documents/dev/work/special-skill
```

Each direct subdirectory of a `[dirs]` path is linked as `~/.claude/skills/<subdir>`. Each `[skills]` path must itself contain `SKILL.md` and is linked as `~/.claude/skills/<basename>`; otherwise `skill-link` prints a `[warn]` and skips it. Removing an entry from `skill-link.conf` makes the corresponding link a stale-removal candidate on the next `sync`.

If you use a non-default Claude config directory, set `CLAUDE_CONFIG_DIR` (the same variable Claude Code itself honors), e.g.

```bash
export CLAUDE_CONFIG_DIR="$HOME/.config/claude"
```

`skill-link` will then read `$CLAUDE_CONFIG_DIR/skill-link.conf` and write symlinks under `$CLAUDE_CONFIG_DIR/skills/`.

### Namespacing skills with a prefix

Any entry in either section may be written as `<prefix> = <path>`. The resulting symlink is named `<prefix>:<basename>`, matching the way plugin-namespaced skills already appear to Claude Code.

```
[dirs]
personal = ~/Documents/dev/personal-skills/skills
work = ~/Documents/dev/work-skills/skills

[skills]
work = ~/Documents/dev/work/slack-helper
```

A `personal`-prefixed `[dirs]` entry whose path contains `tdd/` produces `~/.claude/skills/personal:tdd`. Prefixes must match `[A-Za-z0-9_-]+`; `:` and whitespace are not allowed in a prefix. Unprefixed and prefixed entries with the same basename can coexist.

> [!NOTE]
> The prefix changes the **invocation name** (the directory name under `~/.claude/skills/`, e.g. `personal:tdd`), but Claude Code's **skill recommender** surfaces skills by the `name:` field inside each `SKILL.md` frontmatter. Two skills whose `SKILL.md` both declare `name: tdd` will compete for the same recommendation slot even when their directories are `personal:tdd` and `work:tdd`. If you want a prefixed skill to also be recommended under its prefixed identity, edit `SKILL.md`'s `name:` to match (e.g. `name: personal:tdd`).

## Usage

```bash
skill-link init      # create skill-link.conf from a template if it does not
                     # already exist
skill-link sync      # create symlinks under $CLAUDE_CONFIG_DIR/skills/ and
                     # remove stale symlinks whose source dir is no longer in conf
skill-link list      # show configured dirs and current link status
skill-link clean     # remove only broken symlinks
skill-link --version
skill-link --help
```

Editing files inside a linked skill takes effect immediately — no re-sync needed.

### `sync` vs `clean`

`sync` and `clean` both delete symlinks, but they use different criteria and cover different failure modes.

- `sync` removes **stale** links — those whose parent directory is no longer listed in `skill-link.conf`. It does not check whether the link target still exists on disk.
- `clean` removes **broken** links — those whose target no longer exists, regardless of what `skill-link.conf` says. It does not read the conf at all and does not prompt for confirmation.

This means there are cases `sync` cannot clean up by itself, and you need `clean` to finish the job:

- You deleted or renamed a single skill directory under a conf-listed parent. The symlink's parent path is still in conf, so `sync` leaves it alone, and the link creation loop never sees the old name, so it stays broken.
- You moved or renamed the parent directory itself. The recorded link parent still string-matches the (now stale) conf entry, so `sync` keeps the link; the link-creation phase just prints `[warn] ... not found, skipping.` and never relinks.

In both cases run `skill-link clean` to drop the broken links. (For the second case, also update `skill-link.conf` to the new path and run `sync` again.)

The split is intentional: a missing target can mean "the source is genuinely gone" or "an external drive is temporarily unmounted," so `sync` deliberately avoids deleting links just because the target is currently unreachable. `clean` is the explicit opt-in for that cleanup.

## License

MIT — see [LICENSE](LICENSE).
