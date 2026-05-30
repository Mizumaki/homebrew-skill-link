#!/usr/bin/env bats
#
# Behavior of `skill-link init`: create skill-link.conf from a template only
# when it does not already exist; otherwise leave the existing file untouched.

load test_helper

setup() {
  _skill_link_common_setup
}

teardown() {
  _skill_link_common_teardown
}

@test "init creates skill-link.conf when missing" {
  rm -f "$CONF"
  [ ! -e "$CONF" ]

  run "$SCRIPT" init
  [ "$status" -eq 0 ]
  [ -f "$CONF" ]
  [[ "$output" == *"Created"* ]]
  [[ "$output" == *"$CONF"* ]]
  # Freshly init'ed template must be a no-op when synced: empty [dirs]/[skills]
  # sections, all example entries commented out.
  run "$SCRIPT" sync
  [ "$status" -eq 0 ]
  [[ "$output" == *"Done: 0 linked, 0 kept, 0 skipped."* ]]
  [[ "$output" != *"[warn]"* ]]
}

@test "init leaves an existing skill-link.conf untouched" {
  printf '%s\n' "$HOME/preexisting" > "$CONF"
  local before
  before="$(cat "$CONF")"

  run "$SCRIPT" init
  [ "$status" -eq 0 ]
  [[ "$output" == *"already exists"* ]]
  [ "$(cat "$CONF")" = "$before" ]
}

@test "init creates the Claude config dir if missing" {
  rm -rf "$HOME/.claude"
  [ ! -d "$HOME/.claude" ]

  run "$SCRIPT" init
  [ "$status" -eq 0 ]
  [ -d "$HOME/.claude" ]
  [ -f "$CONF" ]
}

@test "init template mentions [dirs] and [skills] sections" {
  rm -f "$CONF"
  run "$SCRIPT" init
  [ "$status" -eq 0 ]
  run grep -E '^\s*#.*\[dirs\]' "$CONF"
  [ "$status" -eq 0 ]
  run grep -E '^\s*#.*\[skills\]' "$CONF"
  [ "$status" -eq 0 ]
}

@test "init honors CLAUDE_CONFIG_DIR" {
  local custom="$HOME/custom-claude"
  CLAUDE_CONFIG_DIR="$custom" run "$SCRIPT" init
  [ "$status" -eq 0 ]
  [ -f "$custom/skill-link.conf" ]
  [ ! -f "$HOME/.claude/skill-link.conf" ]
}

@test "init followed by sync works end-to-end" {
  rm -f "$CONF"
  run "$SCRIPT" init
  [ "$status" -eq 0 ]

  # Append a real conf line on top of the template.
  mkdir -p "$HOME/src"
  make_skill "$HOME/src" alpha
  printf '[dirs]\n%s\n' "$HOME/src" >> "$CONF"

  run "$SCRIPT" sync
  [ "$status" -eq 0 ]
  [ -L "$SKILLS/alpha" ]
}
