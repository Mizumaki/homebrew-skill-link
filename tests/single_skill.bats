#!/usr/bin/env bats
#
# Behavior of single-skill entries (under the [skills] section).

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
  write_skill_entry "$HOME/standalone/my-skill"

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
  write_dirs_entry "$SRC"
  write_skill_entry "$HOME/standalone/solo"

  run "$SCRIPT" sync
  [ "$status" -eq 0 ]
  [ -L "$SKILLS/alpha" ]
  [ -L "$SKILLS/solo" ]
  [[ "$output" == *"Done: 2 linked, 0 kept, 0 skipped."* ]]
}

@test "sync warns and skips a skill entry whose path is missing" {
  write_skill_entry "$HOME/does/not/exist"

  run "$SCRIPT" sync
  [ "$status" -eq 0 ]
  [[ "$output" == *"[warn]"* ]]
  [[ "$output" == *"is not a skill"* ]]
  [[ "$output" == *"Done: 0 linked, 0 kept, 0 skipped."* ]]
}

@test "sync warns and skips a skill entry that lacks SKILL.md" {
  mkdir -p "$HOME/standalone/no-md"
  write_skill_entry "$HOME/standalone/no-md"

  run "$SCRIPT" sync
  [ "$status" -eq 0 ]
  [[ "$output" == *"[warn]"* ]]
  [[ "$output" == *"is not a skill"* ]]
  [ ! -L "$SKILLS/no-md" ]
}

@test "sync expands ~ in skill entries" {
  make_skill_with_md "$HOME/standalone/tilde-skill"
  write_skill_entry '~/standalone/tilde-skill'

  run "$SCRIPT" sync
  [ "$status" -eq 0 ]
  [ -L "$SKILLS/tilde-skill" ]
  [ -d "$SKILLS/tilde-skill" ]
}

@test "sync flags a removed skill entry as stale" {
  make_skill_with_md "$HOME/standalone/temp-skill"
  write_skill_entry "$HOME/standalone/temp-skill"
  run "$SCRIPT" sync
  [ "$status" -eq 0 ]
  [ -L "$SKILLS/temp-skill" ]

  # User removes the entry from conf.
  : > "$CONF"

  run bash -c "echo y | '$SCRIPT' sync"
  [ "$status" -eq 0 ]
  [[ "$output" == *"will be removed"* ]]
  [[ "$output" == *"temp-skill"* ]]
  [ ! -L "$SKILLS/temp-skill" ]
}

@test "sync leaves an in-conf skill entry alone across re-runs" {
  make_skill_with_md "$HOME/standalone/keepme"
  write_skill_entry "$HOME/standalone/keepme"
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
  # [dirs] listed first so its `dupe` is linked first.
  write_dirs_entry "$SRC"
  write_skill_entry "$HOME/standalone/dupe"

  run "$SCRIPT" sync
  [ "$status" -eq 0 ]
  [ -L "$SKILLS/dupe" ]
  local dest
  dest="$(readlink "$SKILLS/dupe")"
  [[ "$dest" == "$SRC/dupe/" ]]
  [[ "$output" == *"[link] dupe"* ]]
  [[ "$output" == *"[keep] dupe"* ]]
}

@test "name collision: first conf entry wins ([skills] first)" {
  make_skill "$SRC" dupe
  make_skill_with_md "$HOME/standalone/dupe"
  # [skills] listed first so the standalone dupe is linked first.
  write_skill_entry "$HOME/standalone/dupe"
  write_dirs_entry "$SRC"

  run "$SCRIPT" sync
  [ "$status" -eq 0 ]
  [ -L "$SKILLS/dupe" ]
  local dest
  dest="$(readlink "$SKILLS/dupe")"
  [[ "$dest" == "$HOME/standalone/dupe/" ]]
  [[ "$output" == *"[link] dupe"* ]]
  [[ "$output" == *"[keep] dupe"* ]]
}

@test "list shows 'Configured skills' only when at least one [skills] entry exists" {
  make_skill "$SRC" alpha
  write_dirs_entry "$SRC"
  run "$SCRIPT" list
  [ "$status" -eq 0 ]
  [[ "$output" != *"Configured skills:"* ]]

  make_skill_with_md "$HOME/standalone/solo"
  write_skill_entry "$HOME/standalone/solo"
  run "$SCRIPT" list
  [ "$status" -eq 0 ]
  [[ "$output" == *"Configured skills:"* ]]
  [[ "$output" == *"$HOME/standalone/solo"* ]]
}

@test "list reports a not-yet-synced skill entry as unlinked" {
  make_skill_with_md "$HOME/standalone/pending"
  write_skill_entry "$HOME/standalone/pending"

  run "$SCRIPT" list
  [ "$status" -eq 0 ]
  [[ "$output" == *"[unlinked] pending"* ]]
  [[ "$output" == *"$HOME/standalone/pending"* ]]
}
