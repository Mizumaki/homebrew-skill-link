#!/usr/bin/env bats

load test_helper

setup() {
  _skill_link_common_setup
  SRC="$HOME/src"
  STALE_SRC="$HOME/stale-src"
  mkdir -p "$SRC" "$STALE_SRC"
}

teardown() {
  _skill_link_common_teardown
}

# Set up a state where:
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

@test "sync errors when conf is missing" {
  run "$SCRIPT" sync
  [ "$status" -ne 0 ]
  [[ "$output" == *"not found"* ]]
  [[ "$output" == *"skill-link init"* ]]
}

@test "sync with no stale links proceeds to install" {
  make_skill "$SRC" alpha
  write_conf "$SRC"

  run "$SCRIPT" sync
  [ "$status" -eq 0 ]
  [[ "$output" == *"No stale symlinks found."* ]]
  [[ "$output" == *"[link] alpha"* ]]
  [ -L "$SKILLS/alpha" ]
}

@test "sync aborts when user answers N to confirmation" {
  _seed_with_stale

  run bash -c "printf 'n\n' | '$SCRIPT' sync"
  [ "$status" -eq 0 ]
  [[ "$output" == *"will be removed"* ]]
  [[ "$output" == *"stale ->"* ]]
  [[ "$output" == *"Aborted."* ]]
  # Stale symlink remains
  [ -L "$SKILLS/stale" ]
}

@test "sync aborts on empty/default answer" {
  _seed_with_stale

  run bash -c "printf '\n' | '$SCRIPT' sync"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Aborted."* ]]
  [ -L "$SKILLS/stale" ]
}

@test "sync aborts cleanly when stdin is closed (EOF on prompt)" {
  _seed_with_stale

  run bash -c "'$SCRIPT' sync </dev/null"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Aborted."* ]]
  [ -L "$SKILLS/stale" ]
}

@test "sync aborts when answer has no trailing newline (EOF after y absent)" {
  _seed_with_stale

  # printf 'y' (no newline) — answer string is "y" but read returns non-zero
  # because no delimiter was seen. We want a clean Aborted., not a silent crash.
  run bash -c "printf 'y' | '$SCRIPT' sync"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Aborted."* ]]
  [ -L "$SKILLS/stale" ]
}

@test "sync removes stale links and reinstalls when user answers y" {
  _seed_with_stale
  make_skill "$SRC" beta  # new skill that should be linked by install phase

  run bash -c "printf 'y\n' | '$SCRIPT' sync"
  [ "$status" -eq 0 ]
  [[ "$output" == *"[removed] stale"* ]]
  [[ "$output" == *"1 symlink(s) removed."* ]]
  [[ "$output" == *"[link] beta"* ]]
  [ ! -e "$SKILLS/stale" ]
  [ ! -L "$SKILLS/stale" ]
  [ -L "$SKILLS/alpha" ]
  [ -L "$SKILLS/beta" ]
}

@test "sync treats trailing-slash conf entries as matching" {
  make_skill "$SRC" alpha
  mkdir -p "$SKILLS"
  ln -s "$SRC/alpha/" "$SKILLS/alpha"
  write_conf "$SRC/"   # trailing slash in conf

  run "$SCRIPT" sync
  [ "$status" -eq 0 ]
  [[ "$output" == *"No stale symlinks found."* ]]
  [ -L "$SKILLS/alpha" ]
}

@test "sync ignores non-symlink entries during stale detection" {
  make_skill "$SRC" alpha
  write_conf "$SRC"
  mkdir -p "$SKILLS/manual-skill"

  run "$SCRIPT" sync
  [ "$status" -eq 0 ]
  [[ "$output" == *"No stale symlinks found."* ]]
  [ -d "$SKILLS/manual-skill" ]
}
