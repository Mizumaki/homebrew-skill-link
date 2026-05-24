# Shared helpers for skill-link bats tests.
# Each test gets a sandboxed HOME so no real ~/.claude state is touched.

_skill_link_common_setup() {
  SCRIPT="${BATS_TEST_DIRNAME}/../bin/skill-link"
  TMP_HOME="$(mktemp -d)"
  export HOME="$TMP_HOME"
  CONF="$HOME/.claude/skill-dirs.conf"
  SKILLS="$HOME/.claude/skills"
  mkdir -p "$HOME/.claude"
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

# Write conf lines. Usage: write_conf "/path/one" "/path/two"
write_conf() {
  : > "$CONF"
  local line
  for line in "$@"; do
    printf '%s\n' "$line" >> "$CONF"
  done
}

# Create an empty skill directory under a conf dir.
# Usage: make_skill <conf_dir> <skill_name>
make_skill() {
  mkdir -p "$1/$2"
}
