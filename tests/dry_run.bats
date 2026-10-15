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

@test "sync --dry-run reports a new link without creating it" {
  make_skill "$SRC" alpha
  write_conf "$SRC"
  mkdir -p "$SKILLS"

  run "$SCRIPT" sync --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"[link] alpha -> $SRC/alpha/"* ]]
  [ ! -e "$SKILLS/alpha" ]
  [ ! -L "$SKILLS/alpha" ]
}

@test "sync --dry-run does not create a missing target directory" {
  make_skill "$SRC" alpha
  make_skill "$SRC" beta
  write_conf "$SRC"

  run "$SCRIPT" sync --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"[link] alpha"* ]]
  [[ "$output" == *"[link] beta"* ]]
  [ ! -e "$SKILLS" ]
}

@test "sync --dry-run reports stale links without prompting or removing them" {
  local stale_src="$HOME/stale-src"
  make_skill "$SRC" alpha
  make_skill "$stale_src" stale
  mkdir -p "$SKILLS"
  ln -s "$stale_src/stale/" "$SKILLS/stale"
  write_conf "$SRC"

  # stdin closed: reaching the confirmation prompt would print "Aborted."
  run bash -c "'$SCRIPT' sync --dry-run </dev/null"
  [ "$status" -eq 0 ]
  [[ "$output" == *"[remove] stale (from $SKILLS)"* ]]
  [[ "$output" != *"Proceed?"* ]]
  [[ "$output" != *"Aborted."* ]]
  [[ "$output" == *"[link] alpha"* ]]
  [ -L "$SKILLS/stale" ]
  [ ! -L "$SKILLS/alpha" ]
}

@test "sync --dry-run reports a broken link as relink without rewriting it" {
  make_skill "$SRC" alpha
  write_conf "$SRC"
  mkdir -p "$SKILLS"
  # Parent is still $SRC, so this is not stale; the link phase would rewrite it.
  ln -s "$SRC/missing/" "$SKILLS/alpha"

  run "$SCRIPT" sync --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"[relink] alpha -> $SRC/alpha/ (was broken)"* ]]
  [ -L "$SKILLS/alpha" ]
  [[ "$(readlink "$SKILLS/alpha")" == "$SRC/missing/" ]]
}

@test "sync --dry-run ends with a summary of what would change" {
  local stale_src="$HOME/stale-src"
  make_skill "$SRC" alpha   # already linked -> kept
  make_skill "$SRC" beta    # new -> would be linked
  make_skill "$SRC" gamma   # real dir in the way -> skipped
  make_skill "$stale_src" stale
  mkdir -p "$SKILLS/gamma"
  ln -s "$SRC/alpha/" "$SKILLS/alpha"
  ln -s "$stale_src/stale/" "$SKILLS/stale"
  write_conf "$SRC"

  run bash -c "'$SCRIPT' sync --dry-run </dev/null"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Dry run: 1 would be linked, 1 would be removed, 1 kept, 1 skipped."* ]]
  [[ "$output" != *"Done:"* ]]
  [[ "$output" != *"[keep]"* ]]
}

@test "sync --dry-run summary counts zero removals when nothing is stale" {
  make_skill "$SRC" alpha
  write_conf "$SRC"

  run "$SCRIPT" sync --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"Dry run: 1 would be linked, 0 would be removed, 0 kept, 0 skipped."* ]]
}
