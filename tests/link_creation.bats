#!/usr/bin/env bats
#
# Behavior of the link-creation phase, exercised through `skill-link sync`
# (the only entry point now that the `install` subcommand has been removed).
# Each test uses a setup with no pre-existing stale symlinks, so sync falls
# straight through to the link-creation phase.

load test_helper

setup() {
  _skill_link_common_setup
  SRC="$HOME/src"
  mkdir -p "$SRC"
}

teardown() {
  _skill_link_common_teardown
}

@test "sync creates ~/.claude/skills when missing and links a skill" {
  make_skill "$SRC" alpha
  write_conf "$SRC"

  [ ! -d "$SKILLS" ]
  run "$SCRIPT" sync
  [ "$status" -eq 0 ]
  [ -d "$SKILLS" ]
  [ -L "$SKILLS/alpha" ]
  [ -d "$SKILLS/alpha" ]
  [[ "$output" == *"[link] alpha"* ]]
  [[ "$output" == *"Done: 1 linked, 0 kept, 0 skipped."* ]]
}

@test "sync links every skill across multiple conf dirs" {
  local src2="$HOME/src2"
  mkdir -p "$src2"
  make_skill "$SRC" alpha
  make_skill "$SRC" beta
  make_skill "$src2" gamma
  write_conf "$SRC" "$src2"

  run "$SCRIPT" sync
  [ "$status" -eq 0 ]
  [ -L "$SKILLS/alpha" ]
  [ -L "$SKILLS/beta" ]
  [ -L "$SKILLS/gamma" ]
  [[ "$output" == *"Done: 3 linked, 0 kept, 0 skipped."* ]]
}

@test "sync keeps a target that is already a valid symlink" {
  make_skill "$SRC" alpha
  write_conf "$SRC"
  run "$SCRIPT" sync
  [ "$status" -eq 0 ]
  [[ "$output" == *"[link] alpha"* ]]

  run "$SCRIPT" sync
  [ "$status" -eq 0 ]
  [[ "$output" == *"[keep] alpha"* ]]
  [[ "$output" == *"already linked"* ]]
  [[ "$output" == *"Done: 0 linked, 1 kept, 0 skipped."* ]]
}

@test "sync relinks a broken symlink that points inside a conf dir" {
  make_skill "$SRC" alpha
  write_conf "$SRC"
  mkdir -p "$SKILLS"
  # broken: points to a sibling under $SRC that does not exist. Its parent is
  # still $SRC, so sync's stale-detection leaves it alone and the link-creation
  # phase rewrites it.
  ln -s "$SRC/alpha-missing/" "$SKILLS/alpha"
  [ -L "$SKILLS/alpha" ]
  [ ! -e "$SKILLS/alpha" ]

  run "$SCRIPT" sync
  [ "$status" -eq 0 ]
  [[ "$output" == *"[relink] alpha"* ]]
  [[ "$output" == *"was broken"* ]]
  [ -L "$SKILLS/alpha" ]
  [ -e "$SKILLS/alpha" ]
  [ -d "$SKILLS/alpha" ]
}

@test "sync skips a target that exists as a real directory (not a symlink)" {
  make_skill "$SRC" alpha
  write_conf "$SRC"
  mkdir -p "$SKILLS/alpha"
  touch "$SKILLS/alpha/keep.txt"

  run "$SCRIPT" sync
  [ "$status" -eq 0 ]
  [[ "$output" == *"[skip] alpha"* ]]
  [[ "$output" == *"exists but not a symlink"* ]]
  [ ! -L "$SKILLS/alpha" ]
  [ -f "$SKILLS/alpha/keep.txt" ]
}

@test "sync warns and continues when a conf-listed dir is missing" {
  make_skill "$SRC" alpha
  write_conf "$HOME/missing-dir" "$SRC"

  run "$SCRIPT" sync
  [ "$status" -eq 0 ]
  [[ "$output" == *"[warn]"* ]]
  [[ "$output" == *"not found, skipping"* ]]
  [ -L "$SKILLS/alpha" ]
  [[ "$output" == *"Done: 1 linked"* ]]
}

@test "sync ignores blank lines and # comments in conf" {
  make_skill "$SRC" alpha
  {
    echo "# this is a comment"
    echo ""
    echo "[dirs]"
    echo "$SRC"
    echo "   "
    echo "# another comment"
  } > "$CONF"

  run "$SCRIPT" sync
  [ "$status" -eq 0 ]
  [ -L "$SKILLS/alpha" ]
  [[ "$output" == *"Done: 1 linked, 0 kept, 0 skipped."* ]]
}

@test "sync ignores comments with leading whitespace" {
  make_skill "$SRC" alpha
  {
    printf '   # leading-space comment\n'
    printf '\t# tab-indented comment\n'
    printf '[dirs]\n'
    printf '%s\n' "$SRC"
  } > "$CONF"

  run "$SCRIPT" sync
  [ "$status" -eq 0 ]
  [[ "$output" != *"[warn]"* ]]
  [ -L "$SKILLS/alpha" ]
  [[ "$output" == *"Done: 1 linked, 0 kept, 0 skipped."* ]]
}

@test "sync ignores blank lines containing only tabs/spaces" {
  make_skill "$SRC" alpha
  {
    printf '\t\t\n'
    printf '   \n'
    printf '[dirs]\n'
    printf '%s\n' "$SRC"
  } > "$CONF"

  run "$SCRIPT" sync
  [ "$status" -eq 0 ]
  [[ "$output" != *"[warn]"* ]]
  [ -L "$SKILLS/alpha" ]
}

@test "sync expands ~ in conf paths" {
  make_skill "$HOME/tildedir" alpha
  write_conf '~/tildedir'

  run "$SCRIPT" sync
  [ "$status" -eq 0 ]
  [ -L "$SKILLS/alpha" ]
  [ -d "$SKILLS/alpha" ]
  [[ "$output" == *"Done: 1 linked"* ]]
}

@test "sync handles a conf dir that contains no skill subdirectories" {
  write_conf "$SRC"
  run "$SCRIPT" sync
  [ "$status" -eq 0 ]
  [[ "$output" == *"Done: 0 linked, 0 kept, 0 skipped."* ]]
}
