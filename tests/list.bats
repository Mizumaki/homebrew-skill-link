#!/usr/bin/env bats

load test_helper

setup() {
  _skill_link_common_setup
  SRC="$HOME/src"
  mkdir -p "$SRC"
}

teardown() {
  _skill_link_common_teardown
}

@test "list prints configured directories" {
  local src2="$HOME/src2"
  mkdir -p "$src2"
  write_conf "$SRC" "$src2"

  run "$SCRIPT" list
  [ "$status" -eq 0 ]
  [[ "$output" == *"Configured directories:"* ]]
  [[ "$output" == *"$SRC"* ]]
  [[ "$output" == *"$src2"* ]]
}

@test "list reports (none) when no skills dir and no conf skills exist" {
  write_conf "$SRC"
  run "$SCRIPT" list
  [ "$status" -eq 0 ]
  [[ "$output" == *"(none)"* ]]
}

@test "list shows (none) when skills dir exists but is empty" {
  write_conf "$SRC"
  mkdir -p "$SKILLS"

  run "$SCRIPT" list
  [ "$status" -eq 0 ]
  [[ "$output" == *"(none)"* ]]
}

@test "list tags a conf skill with no symlink as [unlinked]" {
  make_skill "$SRC" alpha
  write_conf "$SRC"

  run "$SCRIPT" list
  [ "$status" -eq 0 ]
  [[ "$output" == *"[unlinked] alpha"* ]]
  [[ "$output" == *"$SRC/alpha"* ]]
  [[ "$output" == *"skill-link sync"* ]]
}

@test "list does not show [unlinked] once the skill has been synced" {
  make_skill "$SRC" alpha
  write_conf "$SRC"
  "$SCRIPT" sync >/dev/null

  run "$SCRIPT" list
  [ "$status" -eq 0 ]
  [[ "$output" == *"[linked] alpha"* ]]
  [[ "$output" != *"[unlinked]"* ]]
}

@test "list shows [unlinked] even before the skills dir is created" {
  make_skill "$SRC" alpha
  write_conf "$SRC"
  [ ! -d "$SKILLS" ]

  run "$SCRIPT" list
  [ "$status" -eq 0 ]
  [[ "$output" == *"[unlinked] alpha"* ]]
}

@test "list separates [linked] and [unlinked] across conf dirs" {
  local src2="$HOME/src2"
  mkdir -p "$src2"
  make_skill "$SRC" alpha
  make_skill "$src2" beta
  write_conf "$SRC" "$src2"
  # only sync the first one (simulate beta added after the last sync)
  mkdir -p "$SKILLS"
  ln -s "$SRC/alpha/" "$SKILLS/alpha"

  run "$SCRIPT" list
  [ "$status" -eq 0 ]
  [[ "$output" == *"[linked] alpha"* ]]
  [[ "$output" == *"[unlinked] beta"* ]]
}

@test "list tags a healthy symlink as [linked]" {
  make_skill "$SRC" alpha
  write_conf "$SRC"
  "$SCRIPT" sync >/dev/null

  run "$SCRIPT" list
  [ "$status" -eq 0 ]
  [[ "$output" == *"[linked] alpha"* ]]
}

@test "list tags a dangling symlink as [broken]" {
  write_conf "$SRC"
  mkdir -p "$SKILLS"
  ln -s "$HOME/nope" "$SKILLS/ghost"

  run "$SCRIPT" list
  [ "$status" -eq 0 ]
  [[ "$output" == *"[broken] ghost"* ]]
  [[ "$output" == *"target missing"* ]]
}

@test "list tags a non-symlink entry as [manual]" {
  write_conf "$SRC"
  mkdir -p "$SKILLS/manual-skill"

  run "$SCRIPT" list
  [ "$status" -eq 0 ]
  [[ "$output" == *"[manual] manual-skill"* ]]
}

@test "list shows linked, broken, and manual entries together" {
  make_skill "$SRC" alpha
  write_conf "$SRC"
  "$SCRIPT" sync >/dev/null
  ln -s "$HOME/nope" "$SKILLS/ghost"
  mkdir -p "$SKILLS/manual-skill"

  run "$SCRIPT" list
  [ "$status" -eq 0 ]
  [[ "$output" == *"[linked] alpha"* ]]
  [[ "$output" == *"[broken] ghost"* ]]
  [[ "$output" == *"[manual] manual-skill"* ]]
}
