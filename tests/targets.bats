#!/usr/bin/env bats
#
# Behavior of the [targets] section: every skill is linked into every listed
# skills directory (e.g. Claude Code's ~/.claude/skills and Codex's
# ~/.agents/skills). There is no default target.

load test_helper

setup() {
  _skill_link_common_setup
  SRC="$HOME/src"
  mkdir -p "$SRC"
  CLAUDE_SKILLS="$HOME/.claude/skills"
  AGENTS_SKILLS="$HOME/.agents/skills"
}

teardown() {
  _skill_link_common_teardown
}

# Write a conf listing both Claude Code and Codex targets plus the given
# [dirs] entries.
write_two_target_conf() {
  printf '[targets]\n%s\n%s\n[dirs]\n' "$CLAUDE_SKILLS" "$AGENTS_SKILLS" > "$CONF"
  local line
  for line in "$@"; do
    printf '%s\n' "$line" >> "$CONF"
  done
}

@test "sync links every skill into every target" {
  make_skill "$SRC" alpha
  make_skill_with_md "$HOME/single/solo"
  write_two_target_conf "$SRC"
  printf '[skills]\n%s\n' "$HOME/single/solo" >> "$CONF"

  run "$SCRIPT" sync
  [ "$status" -eq 0 ]
  [ -L "$CLAUDE_SKILLS/alpha" ]
  [ -L "$AGENTS_SKILLS/alpha" ]
  [ -L "$CLAUDE_SKILLS/solo" ]
  [ -L "$AGENTS_SKILLS/solo" ]
  [[ "$output" == *"Done: 4 linked, 0 kept, 0 skipped."* ]]
}

@test "sync creates missing target directories" {
  make_skill "$SRC" alpha
  write_two_target_conf "$SRC"
  [ ! -d "$CLAUDE_SKILLS" ]
  [ ! -d "$AGENTS_SKILLS" ]

  run "$SCRIPT" sync
  [ "$status" -eq 0 ]
  [ -d "$CLAUDE_SKILLS" ]
  [ -d "$AGENTS_SKILLS" ]
}

@test "sync output names each target" {
  make_skill "$SRC" alpha
  write_two_target_conf "$SRC"

  run "$SCRIPT" sync
  [ "$status" -eq 0 ]
  [[ "$output" == *"$CLAUDE_SKILLS"* ]]
  [[ "$output" == *"$AGENTS_SKILLS"* ]]
}

@test "target paths expand ~" {
  make_skill "$SRC" alpha
  printf '[targets]\n~/.agents/skills\n[dirs]\n%s\n' "$SRC" > "$CONF"

  run "$SCRIPT" sync
  [ "$status" -eq 0 ]
  [ -L "$AGENTS_SKILLS/alpha" ]
}

@test "only listed targets are written; there is no implicit Claude target" {
  make_skill "$SRC" alpha
  printf '[targets]\n%s\n[dirs]\n%s\n' "$AGENTS_SKILLS" "$SRC" > "$CONF"

  run "$SCRIPT" sync
  [ "$status" -eq 0 ]
  [ -L "$AGENTS_SKILLS/alpha" ]
  [ ! -e "$CLAUDE_SKILLS" ]
}

@test "conf without [targets] is rejected" {
  make_skill "$SRC" alpha
  printf '[dirs]\n%s\n' "$SRC" > "$CONF"

  run "$SCRIPT" sync
  [ "$status" -ne 0 ]
  [[ "$output" == *"[targets]"* ]]
  [ ! -e "$CLAUDE_SKILLS" ]
  [ ! -e "$AGENTS_SKILLS" ]
}

@test "empty [targets] section is rejected" {
  make_skill "$SRC" alpha
  printf '[targets]\n[dirs]\n%s\n' "$SRC" > "$CONF"

  run "$SCRIPT" sync
  [ "$status" -ne 0 ]
  [[ "$output" == *"[targets]"* ]]
}

@test "list and clean also reject a conf without [targets]" {
  printf '[dirs]\n%s\n' "$SRC" > "$CONF"

  run "$SCRIPT" list
  [ "$status" -ne 0 ]
  [[ "$output" == *"[targets]"* ]]

  run "$SCRIPT" clean
  [ "$status" -ne 0 ]
  [[ "$output" == *"[targets]"* ]]
}

@test "prefix form is rejected inside [targets]" {
  printf '[targets]\nclaude = %s\n' "$CLAUDE_SKILLS" > "$CONF"

  run "$SCRIPT" sync
  [ "$status" -ne 0 ]
  [[ "$output" == *"[targets]"* ]]
  [[ "$output" == *"line 2"* ]]
}

@test "conf under the Claude config dir is not read" {
  make_skill "$SRC" alpha
  mkdir -p "$HOME/.claude"
  printf '[targets]\n%s\n[dirs]\n%s\n' "$CLAUDE_SKILLS" "$SRC" > "$HOME/.claude/skill-link.conf"

  run "$SCRIPT" sync
  [ "$status" -ne 0 ]
  [[ "$output" == *"$CONF"* ]]
  [[ "$output" == *"not found"* ]]
}

@test "sync detects stale links in every target" {
  make_skill "$SRC" alpha
  make_skill "$HOME/old" stale
  mkdir -p "$CLAUDE_SKILLS" "$AGENTS_SKILLS"
  ln -s "$HOME/old/stale/" "$CLAUDE_SKILLS/stale"
  ln -s "$HOME/old/stale/" "$AGENTS_SKILLS/stale"
  write_two_target_conf "$SRC"

  run bash -c "echo y | '$SCRIPT' sync"
  [ "$status" -eq 0 ]
  [[ "$output" == *"$CLAUDE_SKILLS/stale"* ]]
  [[ "$output" == *"$AGENTS_SKILLS/stale"* ]]
  [[ "$output" == *"2 symlink(s) removed."* ]]
  [ ! -L "$CLAUDE_SKILLS/stale" ]
  [ ! -L "$AGENTS_SKILLS/stale" ]
  [ -L "$CLAUDE_SKILLS/alpha" ]
  [ -L "$AGENTS_SKILLS/alpha" ]
}

@test "sync asks for confirmation only once across targets" {
  make_skill "$HOME/old" stale
  mkdir -p "$CLAUDE_SKILLS" "$AGENTS_SKILLS"
  ln -s "$HOME/old/stale/" "$CLAUDE_SKILLS/stale"
  ln -s "$HOME/old/stale/" "$AGENTS_SKILLS/stale"
  write_two_target_conf

  run bash -c "echo y | '$SCRIPT' sync"
  [ "$status" -eq 0 ]
  # `read -p` only shows the prompt on a tty, so count the removal listing
  # that precedes it instead.
  local listings
  listings="$(grep -c 'will be removed' <<<"$output")"
  [ "$listings" -eq 1 ]
  [[ "$output" == *"2 symlink(s) removed."* ]]
}

@test "sync abort leaves stale links in every target" {
  make_skill "$HOME/old" stale
  mkdir -p "$CLAUDE_SKILLS" "$AGENTS_SKILLS"
  ln -s "$HOME/old/stale/" "$CLAUDE_SKILLS/stale"
  ln -s "$HOME/old/stale/" "$AGENTS_SKILLS/stale"
  write_two_target_conf

  run bash -c "echo n | '$SCRIPT' sync"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Aborted."* ]]
  [ -L "$CLAUDE_SKILLS/stale" ]
  [ -L "$AGENTS_SKILLS/stale" ]
}

@test "sync does not treat unlisted skills dirs as targets" {
  make_skill "$HOME/old" stale
  mkdir -p "$CLAUDE_SKILLS"
  ln -s "$HOME/old/stale/" "$CLAUDE_SKILLS/stale"
  printf '[targets]\n%s\n' "$AGENTS_SKILLS" > "$CONF"

  run "$SCRIPT" sync
  [ "$status" -eq 0 ]
  [[ "$output" == *"No stale symlinks found."* ]]
  [ -L "$CLAUDE_SKILLS/stale" ]
}

@test "list shows configured targets and per-target status" {
  make_skill "$SRC" alpha
  write_two_target_conf "$SRC"
  mkdir -p "$CLAUDE_SKILLS"
  ln -s "$SRC/alpha/" "$CLAUDE_SKILLS/alpha"

  run "$SCRIPT" list
  [ "$status" -eq 0 ]
  [[ "$output" == *"Configured targets:"* ]]
  [[ "$output" == *"Skills in $CLAUDE_SKILLS:"* ]]
  [[ "$output" == *"Skills in $AGENTS_SKILLS:"* ]]
  # alpha is linked in the Claude target but not yet in the Codex target.
  local agents_section
  agents_section="${output#*"Skills in $AGENTS_SKILLS:"}"
  [[ "$agents_section" == *"[unlinked] alpha"* ]]
  local claude_section
  claude_section="${output#*"Skills in $CLAUDE_SKILLS:"}"
  claude_section="${claude_section%%"Skills in $AGENTS_SKILLS:"*}"
  [[ "$claude_section" == *"[linked] alpha"* ]]
  [[ "$claude_section" != *"[unlinked] alpha"* ]]
}

@test "clean removes broken symlinks in every target" {
  mkdir -p "$CLAUDE_SKILLS" "$AGENTS_SKILLS"
  ln -s "$HOME/missing" "$CLAUDE_SKILLS/ghost"
  ln -s "$HOME/missing" "$AGENTS_SKILLS/ghost"
  write_two_target_conf

  run "$SCRIPT" clean
  [ "$status" -eq 0 ]
  [ ! -L "$CLAUDE_SKILLS/ghost" ]
  [ ! -L "$AGENTS_SKILLS/ghost" ]
  [[ "$output" == *"Done: 2 broken symlinks removed."* ]]
}

@test "clean skips a target directory that does not exist" {
  mkdir -p "$AGENTS_SKILLS"
  ln -s "$HOME/missing" "$AGENTS_SKILLS/ghost"
  write_two_target_conf

  run "$SCRIPT" clean
  [ "$status" -eq 0 ]
  [[ "$output" == *"No $CLAUDE_SKILLS directory found."* ]]
  [ ! -L "$AGENTS_SKILLS/ghost" ]
  [[ "$output" == *"Done: 1 broken symlinks removed."* ]]
}
