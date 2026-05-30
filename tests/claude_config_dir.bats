#!/usr/bin/env bats
#
# Behavior of CLAUDE_CONFIG_DIR: when set, skill-link should read the conf
# and write the skills tree under that directory instead of ~/.claude.

load test_helper

setup() {
  SCRIPT="${BATS_TEST_DIRNAME}/../bin/skill-link"
  TMP_HOME="$(mktemp -d)"
  export HOME="$TMP_HOME"
  export CLAUDE_CONFIG_DIR="$TMP_HOME/custom-claude"
  mkdir -p "$CLAUDE_CONFIG_DIR"
  CONF="$CLAUDE_CONFIG_DIR/skill-link.conf"
  SKILLS="$CLAUDE_CONFIG_DIR/skills"
  SRC="$HOME/src"
  mkdir -p "$SRC"
}

teardown() {
  unset CLAUDE_CONFIG_DIR
  if [[ -n "${TMP_HOME:-}" && -d "$TMP_HOME" ]]; then
    case "$TMP_HOME" in
      /tmp/*|/var/folders/*|/private/tmp/*|/private/var/folders/*)
        rm -rf "$TMP_HOME"
        ;;
    esac
  fi
}

@test "sync uses CLAUDE_CONFIG_DIR for both conf and skills tree" {
  make_skill "$SRC" alpha
  write_conf "$SRC"

  [ ! -d "$HOME/.claude" ]
  run "$SCRIPT" sync
  [ "$status" -eq 0 ]
  [ -L "$SKILLS/alpha" ]
  [ -d "$SKILLS/alpha" ]
  [ ! -d "$HOME/.claude/skills" ]
  [[ "$output" == *"Done: 1 linked, 0 kept, 0 skipped."* ]]
}

@test "list without conf under CLAUDE_CONFIG_DIR mentions the custom path" {
  rm -f "$CONF"
  run "$SCRIPT" list
  [ "$status" -ne 0 ]
  [[ "$output" == *"$CLAUDE_CONFIG_DIR/skill-link.conf"* ]]
  [[ "$output" == *"not found"* ]]
}

@test "clean operates on CLAUDE_CONFIG_DIR skills tree" {
  mkdir -p "$SKILLS"
  ln -s "$HOME/does-not-exist" "$SKILLS/ghost"
  [ -L "$SKILLS/ghost" ]

  run "$SCRIPT" clean
  [ "$status" -eq 0 ]
  [ ! -L "$SKILLS/ghost" ]
  [[ "$output" == *"[removed] ghost"* ]]
}
