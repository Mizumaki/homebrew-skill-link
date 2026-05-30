#!/usr/bin/env bats
#
# Edge cases of the INI-style skill-link.conf parser, plus the legacy
# skill-dirs.conf detection that hard-breaks the old format.

load test_helper

setup() {
  _skill_link_common_setup
  SRC="$HOME/src"
  mkdir -p "$SRC"
}

teardown() {
  _skill_link_common_teardown
}

@test "unknown section is rejected" {
  make_skill "$SRC" alpha
  printf '[foo]\n%s\n' "$SRC" > "$CONF"

  run "$SCRIPT" sync
  [ "$status" -ne 0 ]
  [[ "$output" == *"unknown section"* ]]
  [[ "$output" == *"[foo]"* ]]
}

@test "value before any section header is rejected" {
  make_skill "$SRC" alpha
  printf '%s\n[dirs]\n' "$SRC" > "$CONF"

  run "$SCRIPT" sync
  [ "$status" -ne 0 ]
  [[ "$output" == *"entry before"* ]]
  [[ "$output" == *"section"* ]]
}

@test "list also surfaces parser errors" {
  printf '[bogus]\n' > "$CONF"
  run "$SCRIPT" list
  [ "$status" -ne 0 ]
  [[ "$output" == *"unknown section"* ]]
}

@test "empty [dirs] and [skills] sections sync as 0 entries" {
  printf '[dirs]\n[skills]\n' > "$CONF"

  run "$SCRIPT" sync
  [ "$status" -eq 0 ]
  [[ "$output" == *"Done: 0 linked, 0 kept, 0 skipped."* ]]
}

@test "legacy skill-dirs.conf is detected and rejected with migration hint" {
  rm -f "$CONF"
  printf '%s\n' "$SRC" > "$HOME/.claude/skill-dirs.conf"

  run "$SCRIPT" sync
  [ "$status" -ne 0 ]
  [[ "$output" == *"legacy"* ]] || [[ "$output" == *"skill-dirs.conf"* ]]
  [[ "$output" == *"skill-link init"* ]]
}

@test "tabs and spaces around section headers and entries are tolerated" {
  make_skill "$SRC" alpha
  {
    printf '\t[dirs]   \n'
    printf '   %s\t\n' "$SRC"
  } > "$CONF"

  run "$SCRIPT" sync
  [ "$status" -eq 0 ]
  [ -L "$SKILLS/alpha" ]
}

@test "whitespace around '=' in prefixed entries is tolerated" {
  make_skill "$HOME/matt-skills" tdd
  printf '[dirs]\nmatt   =   %s\n' "$HOME/matt-skills" > "$CONF"

  run "$SCRIPT" sync
  [ "$status" -eq 0 ]
  [ -L "$SKILLS/matt:tdd" ]
}
