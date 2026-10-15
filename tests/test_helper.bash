# Shared helpers for skill-link bats tests.
# Each test gets a sandboxed HOME (and XDG_CONFIG_HOME) so no real conf or
# skills tree is touched.

_skill_link_common_setup() {
  SCRIPT="${BATS_TEST_DIRNAME}/../bin/skill-link"
  TMP_HOME="$(mktemp -d)"
  export HOME="$TMP_HOME"
  export XDG_CONFIG_HOME="$HOME/.config"
  CONF="$XDG_CONFIG_HOME/skill-link/skill-link.conf"
  # Default single target used by most tests.
  SKILLS="$HOME/.claude/skills"
  mkdir -p "$(dirname "$CONF")"
}

_skill_link_common_teardown() {
  if [[ -z "${TMP_HOME:-}" || ! -d "$TMP_HOME" ]]; then
    return
  fi
  case "$TMP_HOME" in
    /tmp/*|/var/folders/*|/private/tmp/*|/private/var/folders/*)
      rm -rf "$TMP_HOME"
      ;;
  esac
}

# Write a fresh conf containing only a [targets] section. Lists $SKILLS
# when no target is given.
# Usage: write_targets [<target>...]
write_targets() {
  printf '[targets]\n' > "$CONF"
  printf '%s\n' "${@:-$SKILLS}" >> "$CONF"
}

# Write a fresh conf with the default target and the given parent-dir entries
# (no prefixes). With no arguments, the conf has the target only.
# Usage: write_conf "/path/one" "/path/two"
write_conf() {
  write_targets
  if (( $# > 0 )); then
    printf '[dirs]\n' >> "$CONF"
    local line
    for line in "$@"; do
      printf '%s\n' "$line" >> "$CONF"
    done
  fi
}

# Append a [dirs] entry. Prefix is optional. Seeds the default target when
# the conf does not exist yet.
# Usage: write_dirs_entry <path> [<prefix>]
write_dirs_entry() {
  local path="$1" prefix="${2:-}"
  [[ -f "$CONF" ]] || write_targets
  if ! grep -q '^\[dirs\]' "$CONF"; then
    printf '[dirs]\n' >> "$CONF"
  fi
  if [[ -n "$prefix" ]]; then
    printf '%s = %s\n' "$prefix" "$path" >> "$CONF"
  else
    printf '%s\n' "$path" >> "$CONF"
  fi
}

# Append a [skills] entry. Prefix is optional. Seeds the default target when
# the conf does not exist yet.
# Usage: write_skill_entry <path> [<prefix>]
write_skill_entry() {
  local path="$1" prefix="${2:-}"
  [[ -f "$CONF" ]] || write_targets
  if ! grep -q '^\[skills\]' "$CONF"; then
    printf '[skills]\n' >> "$CONF"
  fi
  if [[ -n "$prefix" ]]; then
    printf '%s = %s\n' "$prefix" "$path" >> "$CONF"
  else
    printf '%s\n' "$path" >> "$CONF"
  fi
}

# Create an empty skill directory under a conf dir.
# Usage: make_skill <conf_dir> <skill_name>
make_skill() {
  mkdir -p "$1/$2"
}

# Create a skill directory at <path> with an empty SKILL.md, so it satisfies
# the validity check used by `skill:` conf entries.
# Usage: make_skill_with_md <path>
make_skill_with_md() {
  mkdir -p "$1"
  : > "$1/SKILL.md"
}

# Set up a state where (requires $SRC and $STALE_SRC):
#   - SRC is in conf and contains skill "alpha" (already linked)
#   - STALE_SRC is NOT in conf but contains skill "stale" (still linked from a
#     previous install)
_seed_with_stale() {
  make_skill "$SRC" alpha
  make_skill "$STALE_SRC" stale
  mkdir -p "$SKILLS"
  ln -s "$SRC/alpha/" "$SKILLS/alpha"
  ln -s "$STALE_SRC/stale/" "$SKILLS/stale"
  write_conf "$SRC"
}
