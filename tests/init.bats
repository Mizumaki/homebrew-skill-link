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
  # Every example entry is commented out, including targets, so a freshly
  # init'ed conf has no target and sync refuses to guess one.
  run "$SCRIPT" sync
  [ "$status" -ne 0 ]
  [[ "$output" == *"[targets]"* ]]
  [ ! -e "$HOME/.claude/skills" ]
  [ ! -e "$HOME/.agents/skills" ]
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

@test "init creates the config dir if missing" {
  rm -rf "$XDG_CONFIG_HOME"
  [ ! -d "$XDG_CONFIG_HOME" ]

  run "$SCRIPT" init
  [ "$status" -eq 0 ]
  [ -d "$XDG_CONFIG_HOME/skill-link" ]
  [ -f "$CONF" ]
}

@test "init template mentions [targets], [dirs] and [skills] sections" {
  rm -f "$CONF"
  run "$SCRIPT" init
  [ "$status" -eq 0 ]
  run grep -E '^\s*#.*\[targets\]' "$CONF"
  [ "$status" -eq 0 ]
  run grep -E '^\s*#.*\[dirs\]' "$CONF"
  [ "$status" -eq 0 ]
  run grep -E '^\s*#.*\[skills\]' "$CONF"
  [ "$status" -eq 0 ]
}

@test "init template suggests Claude Code and Codex targets, both commented out" {
  rm -f "$CONF"
  run "$SCRIPT" init
  [ "$status" -eq 0 ]
  run grep -E '^\s*#\s*~/\.claude/skills\s*$' "$CONF"
  [ "$status" -eq 0 ]
  run grep -E '^\s*#\s*~/\.agents/skills\s*$' "$CONF"
  [ "$status" -eq 0 ]
}

@test "init honors XDG_CONFIG_HOME" {
  local custom="$HOME/custom-xdg"
  XDG_CONFIG_HOME="$custom" run "$SCRIPT" init
  [ "$status" -eq 0 ]
  [ -f "$custom/skill-link/skill-link.conf" ]
  [ ! -f "$CONF" ]
}

@test "init falls back to ~/.config when XDG_CONFIG_HOME is unset" {
  unset XDG_CONFIG_HOME
  run "$SCRIPT" init
  [ "$status" -eq 0 ]
  [ -f "$HOME/.config/skill-link/skill-link.conf" ]
}

@test "init no longer writes into the Claude config dir" {
  CLAUDE_CONFIG_DIR="$HOME/custom-claude" run "$SCRIPT" init
  [ "$status" -eq 0 ]
  [ ! -e "$HOME/custom-claude/skill-link.conf" ]
  [ ! -e "$HOME/.claude/skill-link.conf" ]
  [ -f "$CONF" ]
}

@test "init followed by sync works end-to-end" {
  rm -f "$CONF"
  run "$SCRIPT" init
  [ "$status" -eq 0 ]

  # Append a real conf line on top of the template.
  mkdir -p "$HOME/src"
  make_skill "$HOME/src" alpha
  printf '[targets]\n%s\n[dirs]\n%s\n' "$SKILLS" "$HOME/src" >> "$CONF"

  run "$SCRIPT" sync
  [ "$status" -eq 0 ]
  [ -L "$SKILLS/alpha" ]
}
