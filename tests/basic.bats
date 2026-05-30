#!/usr/bin/env bats

setup() {
  SCRIPT="${BATS_TEST_DIRNAME}/../bin/skill-link"
}

@test "version flag prints version" {
  run "$SCRIPT" --version
  [ "$status" -eq 0 ]
  [[ "$output" == *"skill-link 1.2.0"* ]]
}

@test "help flag prints usage" {
  run "$SCRIPT" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage"* ]]
}

@test "no args prints usage and exits non-zero" {
  run "$SCRIPT"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Usage"* ]]
}

@test "unknown command exits non-zero" {
  run "$SCRIPT" bogus
  [ "$status" -ne 0 ]
}

@test "removed 'install' subcommand is rejected" {
  run "$SCRIPT" install
  [ "$status" -ne 0 ]
  [[ "$output" == *"Usage"* ]]
}

@test "list without conf errors with setup hint" {
  tmp="$(mktemp -d)"
  HOME="$tmp" run "$SCRIPT" list
  rm -rf "$tmp"
  [ "$status" -ne 0 ]
  [[ "$output" == *"not found"* ]]
  [[ "$output" == *"skill-link init"* ]]
}
