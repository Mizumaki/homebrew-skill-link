# Skill Link

A small CLI that exposes Claude Code skills kept across multiple source directories under a single `~/.claude/skills/` tree via symlinks.

Useful when you maintain skills in several repos (personal, work, experimental) and want Claude Code to discover all of them from one place without copying.

## Configuration

Create `skill-dirs.conf` inside your Claude config directory (defaults to `~/.claude`, override with `CLAUDE_CONFIG_DIR`) listing the directories that contain your skill folders, one per line:

```
~/Documents/dev/personal-skills/skills
~/Documents/dev/work-skills/skills
```

Each direct subdirectory of a listed path is treated as one skill. Lines that start with `#` are comments.

If you use a non-default Claude config directory, set `CLAUDE_CONFIG_DIR` (the same variable Claude Code itself honors)
e.g.

```bash
export CLAUDE_CONFIG_DIR="$HOME/.config/claude"
```

`skill-link` will then read `$CLAUDE_CONFIG_DIR/skill-dirs.conf` and write symlinks under `$CLAUDE_CONFIG_DIR/skills/`.

## Usage

```bash
skill-link init      # create skill-dirs.conf from a template if it does not
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

- `sync` removes **stale** links — those whose parent directory is no longer listed in `skill-dirs.conf`. It does not check whether the link target still exists on disk.
- `clean` removes **broken** links — those whose target no longer exists, regardless of what `skill-dirs.conf` says. It does not read the conf at all and does not prompt for confirmation.

This means there are cases `sync` cannot clean up by itself, and you need `clean` to finish the job:

- You deleted or renamed a single skill directory under a conf-listed parent. The symlink's parent path is still in conf, so `sync` leaves it alone, and the link creation loop never sees the old name, so it stays broken.
- You moved or renamed the parent directory itself. The recorded link parent still string-matches the (now stale) conf entry, so `sync` keeps the link; the link-creation phase just prints `[warn] ... not found, skipping.` and never relinks.

In both cases run `skill-link clean` to drop the broken links. (For the second case, also update `skill-dirs.conf` to the new path and run `sync` again.)

The split is intentional: a missing target can mean "the source is genuinely gone" or "an external drive is temporarily unmounted," so `sync` deliberately avoids deleting links just because the target is currently unreachable. `clean` is the explicit opt-in for that cleanup.

## License

MIT — see [LICENSE](LICENSE).
