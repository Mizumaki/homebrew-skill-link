#!/usr/bin/env bats
#
# Behavior of single-skill conf entries (lines prefixed with `skill:`).

load test_helper

setup() {
  _skill_link_common_setup
  SRC="$HOME/src"
  mkdir -p "$SRC"
}

teardown() {
  _skill_link_common_teardown
}

@test "sync links a single-skill entry by basename" {
  make_skill_with_md "$HOME/standalone/my-skill"
  write_conf "skill: $HOME/standalone/my-skill"

  run "$SCRIPT" sync
  [ "$status" -eq 0 ]
  [ -L "$SKILLS/my-skill" ]
  [ -d "$SKILLS/my-skill" ]
  [[ "$output" == *"[link] my-skill"* ]]
  [[ "$output" == *"Done: 1 linked, 0 kept, 0 skipped."* ]]
}

@test "sync handles a mix of parent and skill entries in one pass" {
  make_skill "$SRC" alpha
  make_skill_with_md "$HOME/standalone/solo"
  write_conf "$SRC" "skill: $HOME/standalone/solo"

  run "$SCRIPT" sync
  [ "$status" -eq 0 ]
  [ -L "$SKILLS/alpha" ]
  [ -L "$SKILLS/solo" ]
  [[ "$output" == *"Done: 2 linked, 0 kept, 0 skipped."* ]]
}

@test "sync warns and skips a skill entry whose path is missing" {
  write_conf "skill: $HOME/does/not/exist"

  run "$SCRIPT" sync
  [ "$status" -eq 0 ]
  [[ "$output" == *"[warn]"* ]]
  [[ "$output" == *"is not a skill"* ]]
  [[ "$output" == *"Done: 0 linked, 0 kept, 0 skipped."* ]]
}

@test "sync warns and skips a skill entry that lacks SKILL.md" {
  mkdir -p "$HOME/standalone/no-md"
  write_conf "skill: $HOME/standalone/no-md"

  run "$SCRIPT" sync
  [ "$status" -eq 0 ]
  [[ "$output" == *"[warn]"* ]]
  [[ "$output" == *"is not a skill"* ]]
  [ ! -L "$SKILLS/no-md" ]
}

@test "sync expands ~ in skill entries" {
  make_skill_with_md "$HOME/standalone/tilde-skill"
  write_conf 'skill: ~/standalone/tilde-skill'

  run "$SCRIPT" sync
  [ "$status" -eq 0 ]
  [ -L "$SKILLS/tilde-skill" ]
  [ -d "$SKILLS/tilde-skill" ]
}

@test "sync tolerates whitespace around the skill: prefix" {
  make_skill_with_md "$HOME/standalone/spaced"
  {
    printf '   skill:   %s   \n' "$HOME/standalone/spaced"
  } > "$CONF"

  run "$SCRIPT" sync
  [ "$status" -eq 0 ]
  [ -L "$SKILLS/spaced" ]
  [[ "$output" == *"Done: 1 linked"* ]]
}

@test "sync flags a removed skill entry as stale" {
  make_skill_with_md "$HOME/standalone/temp-skill"
  write_conf "skill: $HOME/standalone/temp-skill"
  run "$SCRIPT" sync
  [ "$status" -eq 0 ]
  [ -L "$SKILLS/temp-skill" ]

  # User removes the line from conf.
  : > "$CONF"

  run bash -c "echo y | '$SCRIPT' sync"
  [ "$status" -eq 0 ]
  [[ "$output" == *"will be removed"* ]]
  [[ "$output" == *"temp-skill"* ]]
  [ ! -L "$SKILLS/temp-skill" ]
}

@test "sync leaves an in-conf skill entry alone across re-runs" {
  make_skill_with_md "$HOME/standalone/keepme"
  write_conf "skill: $HOME/standalone/keepme"
  run "$SCRIPT" sync
  [ "$status" -eq 0 ]

  run "$SCRIPT" sync
  [ "$status" -eq 0 ]
  [[ "$output" != *"will be removed"* ]]
  [[ "$output" == *"[keep] keepme"* ]]
  [ -L "$SKILLS/keepme" ]
}

@test "name collision: first conf entry wins (parent first)" {
  make_skill "$SRC" dupe
  make_skill_with_md "$HOME/standalone/dupe"
  # Parent listed first so its `dupe` is linked first.
  write_conf "$SRC" "skill: $HOME/standalone/dupe"

  run "$SCRIPT" sync
  [ "$status" -eq 0 ]
  [ -L "$SKILLS/dupe" ]
  # Link should still point inside the parent dir (linked first).
  local dest
  dest="$(readlink "$SKILLS/dupe")"
  [[ "$dest" == "$SRC/dupe/" ]]
  [[ "$output" == *"[link] dupe"* ]]
  [[ "$output" == *"[keep] dupe"* ]]
}

@test "name collision: first conf entry wins (skill: first)" {
  make_skill "$SRC" dupe
  make_skill_with_md "$HOME/standalone/dupe"
  # skill: listed first so the standalone dupe is linked first.
  write_conf "skill: $HOME/standalone/dupe" "$SRC"

  run "$SCRIPT" sync
  [ "$status" -eq 0 ]
  [ -L "$SKILLS/dupe" ]
  local dest
  dest="$(readlink "$SKILLS/dupe")"
  [[ "$dest" == "$HOME/standalone/dupe/" ]]
  [[ "$output" == *"[link] dupe"* ]]
  [[ "$output" == *"[keep] dupe"* ]]
}

@test "list shows 'Configured skills' only when at least one skill: entry exists" {
  make_skill "$SRC" alpha
  write_conf "$SRC"
  run "$SCRIPT" list
  [ "$status" -eq 0 ]
  [[ "$output" != *"Configured skills:"* ]]

  make_skill_with_md "$HOME/standalone/solo"
  write_conf "$SRC" "skill: $HOME/standalone/solo"
  run "$SCRIPT" list
  [ "$status" -eq 0 ]
  [[ "$output" == *"Configured skills:"* ]]
  [[ "$output" == *"$HOME/standalone/solo"* ]]
}

@test "list reports a not-yet-synced skill entry as unlinked" {
  make_skill_with_md "$HOME/standalone/pending"
  write_conf "skill: $HOME/standalone/pending"

  run "$SCRIPT" list
  [ "$status" -eq 0 ]
  [[ "$output" == *"[unlinked] pending"* ]]
  [[ "$output" == *"$HOME/standalone/pending"* ]]
}
