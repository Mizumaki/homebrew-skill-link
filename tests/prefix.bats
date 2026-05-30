#!/usr/bin/env bats
#
# Behavior of prefix-attached entries: skills are exposed as
# "<prefix>:<basename>" in ~/.claude/skills/ instead of just "<basename>".

load test_helper

setup() {
  _skill_link_common_setup
}

teardown() {
  _skill_link_common_teardown
}

@test "sync links [dirs] subdirs with prefix as <prefix>:<name>" {
  make_skill "$HOME/matt-skills" tdd
  make_skill "$HOME/matt-skills" lint
  write_dirs_entry "$HOME/matt-skills" matt

  run "$SCRIPT" sync
  [ "$status" -eq 0 ]
  [ -L "$SKILLS/matt:tdd" ]
  [ -L "$SKILLS/matt:lint" ]
  [[ "$output" == *"[link] matt:tdd"* ]]
  [[ "$output" == *"[link] matt:lint"* ]]
  [[ "$output" == *"Done: 2 linked, 0 kept, 0 skipped."* ]]
}

@test "sync links a [skills] entry with prefix as <prefix>:<basename>" {
  make_skill_with_md "$HOME/work/slack-helper"
  write_skill_entry "$HOME/work/slack-helper" work

  run "$SCRIPT" sync
  [ "$status" -eq 0 ]
  [ -L "$SKILLS/work:slack-helper" ]
  [ -d "$SKILLS/work:slack-helper" ]
  [[ "$output" == *"[link] work:slack-helper"* ]]
}

@test "unprefixed and prefixed entries with the same basename can coexist" {
  make_skill "$HOME/personal" tdd
  make_skill "$HOME/matt-skills" tdd
  write_dirs_entry "$HOME/personal"
  write_dirs_entry "$HOME/matt-skills" matt

  run "$SCRIPT" sync
  [ "$status" -eq 0 ]
  [ -L "$SKILLS/tdd" ]
  [ -L "$SKILLS/matt:tdd" ]
  local dest1 dest2
  dest1="$(readlink "$SKILLS/tdd")"
  dest2="$(readlink "$SKILLS/matt:tdd")"
  [[ "$dest1" == "$HOME/personal/tdd/" ]]
  [[ "$dest2" == "$HOME/matt-skills/tdd/" ]]
}

@test "removing a prefixed entry from conf flags its link as stale" {
  make_skill "$HOME/matt-skills" tdd
  write_dirs_entry "$HOME/matt-skills" matt
  run "$SCRIPT" sync
  [ "$status" -eq 0 ]
  [ -L "$SKILLS/matt:tdd" ]

  : > "$CONF"
  run bash -c "echo y | '$SCRIPT' sync"
  [ "$status" -eq 0 ]
  [[ "$output" == *"will be removed"* ]]
  [[ "$output" == *"matt:tdd"* ]]
  [ ! -L "$SKILLS/matt:tdd" ]
}

@test "list shows prefix annotation for configured dirs" {
  mkdir -p "$HOME/matt-skills"
  write_dirs_entry "$HOME/matt-skills" matt

  run "$SCRIPT" list
  [ "$status" -eq 0 ]
  [[ "$output" == *"matt: $HOME/matt-skills"* ]]
}

@test "list shows prefix annotation for configured skills" {
  make_skill_with_md "$HOME/work/slack-helper"
  write_skill_entry "$HOME/work/slack-helper" work

  run "$SCRIPT" list
  [ "$status" -eq 0 ]
  [[ "$output" == *"work: $HOME/work/slack-helper"* ]]
}

@test "list reports an unlinked prefixed dir entry with the prefixed name" {
  make_skill "$HOME/matt-skills" tdd
  write_dirs_entry "$HOME/matt-skills" matt

  run "$SCRIPT" list
  [ "$status" -eq 0 ]
  [[ "$output" == *"[unlinked] matt:tdd"* ]]
}

@test "prefix containing a colon is rejected" {
  mkdir -p "$HOME/x"
  printf '[dirs]\nbad:prefix = %s\n' "$HOME/x" > "$CONF"

  run "$SCRIPT" sync
  [ "$status" -ne 0 ]
  [[ "$output" == *"invalid prefix"* ]] || [[ "$output" == *"Error"* ]]
  [ ! -L "$SKILLS/bad:prefix:x" ]
}

@test "empty prefix on lhs of = is rejected" {
  mkdir -p "$HOME/x"
  printf '[dirs]\n = %s\n' "$HOME/x" > "$CONF"

  run "$SCRIPT" sync
  [ "$status" -ne 0 ]
  [[ "$output" == *"Error"* ]]
}

@test "prefix containing whitespace is rejected" {
  mkdir -p "$HOME/x"
  printf '[dirs]\nbad prefix = %s\n' "$HOME/x" > "$CONF"

  run "$SCRIPT" sync
  [ "$status" -ne 0 ]
  [[ "$output" == *"Error"* ]]
}
