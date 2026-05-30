# skill-link

`skill-link` は、複数のディレクトリに散在する Claude Code skill を `~/.claude/skills/` 配下にシンボリックリンクで集約する Bash 製の CLI です。

- 実装本体: `bin/skill-link`
- テスト: `tests/*.bats` (bats-core)
- Homebrew Formula: `Formula/skill-link.rb`

## 開発ワークフロー

**このリポジトリでの実装は必ず `tdd` skill を使い、TDD (red → green → refactor) で進めること。**

新機能の追加・バグ修正を行うときは、まず `tdd` skill を起動して以下のループを回す:

1. **Red**: `tests/*.bats` に失敗するテストを追加し、`make test` で失敗することを確認する。
2. **Green**: `bin/skill-link` を最小限の変更で修正し、テストを通す。
3. **Refactor**: テストが通った状態のまま、重複の除去や可読性の改善を行う。

テストを書かずに `bin/skill-link` を編集してはならない。先にテストを失敗させてから実装に入る。

## バージョン bump はしない

`bin/skill-link` の `VERSION`、`Formula/skill-link.rb` の `url` / `sha256` / `test` 内バージョン文字列、`tests/basic.bats` の version 期待値は **手動で変更しないこと**。リリースは `.github/workflows/` のリリースワークフロー側で一括して bump するため、機能変更の PR では現行バージョンのままにしておく。

## よく使うコマンド

```bash
make test    # bats テストスイートを実行
make lint    # shellcheck を bin/skill-link に実行
make check   # lint → test
```

## テストの書き方

- 各テストファイルはコマンド/機能単位 (`sync.bats`, `clean.bats`, `init.bats`, `single_skill.bats` など) に分割する。
- 共通のセットアップは `tests/test_helper.bash` に置く。
- 新しいサブコマンドや挙動の分岐を追加するときは、対応する `*.bats` を新規作成するか既存ファイルに `@test` を足す。
