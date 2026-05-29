#!/usr/bin/env bats

load test_helper

setup() {
  _skill_link_common_setup
}

teardown() {
  _skill_link_common_teardown
}

@test "clean reports when skills dir does not exist" {
  run "$SCRIPT" clean
  [ "$status" -eq 0 ]
  [[ "$output" == *"No $SKILLS directory found."* ]]
}

@test "clean succeeds with no symlinks present" {
  mkdir -p "$SKILLS"
  run "$SCRIPT" clean
  [ "$status" -eq 0 ]
  [[ "$output" == *"Done: 0 broken symlinks removed."* ]]
}

@test "clean removes broken symlinks and keeps valid ones" {
  mkdir -p "$SKILLS" "$HOME/real-skill"
  ln -s "$HOME/real-skill" "$SKILLS/good"
  ln -s "$HOME/missing" "$SKILLS/bad"

  run "$SCRIPT" clean
  [ "$status" -eq 0 ]
  [[ "$output" == *"[removed] bad"* ]]
  [[ "$output" == *"broken symlink"* ]]
  [[ "$output" == *"Done: 1 broken symlinks removed."* ]]
  [ -L "$SKILLS/good" ]
  [ ! -L "$SKILLS/bad" ]
  [ ! -e "$SKILLS/bad" ]
}

@test "clean leaves non-symlink directories alone" {
  mkdir -p "$SKILLS/manual-skill"
  touch "$SKILLS/manual-skill/file.txt"

  run "$SCRIPT" clean
  [ "$status" -eq 0 ]
  [ -d "$SKILLS/manual-skill" ]
  [ -f "$SKILLS/manual-skill/file.txt" ]
  [[ "$output" == *"Done: 0 broken symlinks removed."* ]]
}

@test "clean does not require skill-dirs.conf" {
  mkdir -p "$SKILLS"
  ln -s "$HOME/missing" "$SKILLS/bad"
  [ ! -f "$CONF" ]

  run "$SCRIPT" clean
  [ "$status" -eq 0 ]
  [ ! -e "$SKILLS/bad" ]
}
