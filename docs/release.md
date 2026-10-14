# Release process

GitHub Actions workflows release `skill-link`, and nobody edits version strings by hand.
A maintainer starts a release by running one workflow with the new version number.
The maintainer then merges the Formula PR that the workflow opens.

## Workflows involved in a release

Three workflows in `.github/workflows/` take part in a release.

| Workflow           | Trigger                                    | What it does                                                 |
| ------------------ | ------------------------------------------ | ------------------------------------------------------------ |
| `bump-release.yml` | Manual run (`workflow_dispatch`)           | Bumps the version, tags it, and opens a Formula update PR    |
| `release.yml`      | Push of a `v*` tag                         | Publishes a GitHub Release with generated release notes      |
| `ci.yml`           | Push to `main` or `release/**`, and any PR | Runs shellcheck, bats on Linux and macOS, and `brew style`   |

The diagram below shows the order of the steps, starting from the manual run.

```
workflow_dispatch (version=X.Y.Z)
  └─ bump-release.yml
       ├─ validate version
       ├─ bump bin/skill-link and tests/basic.bats
       ├─ make check
       ├─ commit "Bump up version to vX.Y.Z" → push to main
       ├─ tag vX.Y.Z → push tag ──────────────► release.yml → GitHub Release
       ├─ compute sha256 of the tag tarball
       ├─ update Formula/skill-link.rb (url, sha256)
       └─ push release/formula-vX.Y.Z → open PR ─► ci.yml
                                                    │
                                     maintainer merges the PR
                                                    │
                                  `brew upgrade skill-link` picks up vX.Y.Z
```

## Version fields that feature PRs leave alone

The release workflow owns the following version fields, so feature and bug-fix PRs must not change them:

- `VERSION` in `bin/skill-link`
- The expected version in `tests/basic.bats` (the `version flag prints version` test)
- `url` and `sha256` in `Formula/skill-link.rb`

Merge feature PRs into `main` at the current version, and the next release ships them.

The `test` block of `Formula/skill-link.rb` builds its expected output from `#{version}`.
Homebrew parses `version` from the tag in `url`, so the `test` block needs no bump.
Don't hardcode a version string in the `test` block, or the string goes stale at the next release.

## How to cut a release

1. Make sure that everything you want to ship is merged into `main` and that CI on `main` passes.
   Choose the next version by [Semantic Versioning](https://semver.org/).
   For example, after `1.2.1`, use `1.3.0` for a new feature or `1.2.2` for a fix.
2. Run the "Bump and release" workflow with the version number, and leave out the `v` prefix.
   In the GitHub UI, open the Actions tab, select "Bump and release", and click "Run workflow".
   From the command line, run the following command.

   ```bash
   gh workflow run bump-release.yml -f version=1.3.0
   ```

3. Wait for the workflow to finish.
   When it succeeds, the workflow has done the following:
   - pushed a commit named `Bump up version to v1.3.0` to `main`
   - pushed the tag `v1.3.0`, which starts `release.yml` and publishes the GitHub Release
   - opened a PR named `Update Formula to v1.3.0` from the branch `release/formula-v1.3.0`
4. Review the Formula PR, check that CI passes, and merge the PR.
   The tap reads the Formula from `main` of this repository, so Homebrew users get the new version at their next `brew update` after the merge.
   To check the install, run the following commands.

   ```bash
   brew update
   brew upgrade skill-link
   skill-link --version
   ```

## What `bump-release.yml` does

### Validation before any change

The workflow first checks the input, and it stops if any of the following conditions holds:

- The input isn't a plain `MAJOR.MINOR.PATCH` version.
  A `v` prefix or a pre-release suffix such as `-rc.1` fails the check.
- The input equals the current `VERSION` in `bin/skill-link`.
- The tag `vX.Y.Z` already exists.

### Version bump and checks

The workflow rewrites the version with `sed` in two files.
In `bin/skill-link`, it replaces the `VERSION="..."` line.
In `tests/basic.bats`, it replaces every `skill-link X.Y.Z` string.
It then runs `make check`, which runs shellcheck and then the bats suite.
If `make check` fails, the workflow stops before it pushes anything.

### Commit, tag, and push

The workflow commits the bump as `github-actions[bot]` and pushes the commit directly to `main`.
It then creates the annotated tag `vX.Y.Z` on the commit and pushes the tag.

Both pushes go over SSH with the deploy key in the `RELEASE_DEPLOY_KEY` secret, because GitHub doesn't start new workflow runs for events that `GITHUB_TOKEN` creates.
If the workflow pushed the tag with `GITHUB_TOKEN`, `release.yml` wouldn't run, and no GitHub Release would be published.
If `main` is protected, the deploy key must also be allowed to bypass the protection, or the push to `main` fails.

### Formula update PR

After the tag push, the workflow downloads the source tarball for the tag from `https://github.com/Mizumaki/homebrew-skill-link/archive/refs/tags/vX.Y.Z.tar.gz` and computes its sha256.
GitHub may not serve the tarball right after the tag push, so the workflow tries up to five times and waits five seconds between attempts.
The workflow then writes the new `url` and `sha256` into `Formula/skill-link.rb`.
The Formula `test` block picks up the new version without an edit, because `#{version}` comes from the new `url`.

The workflow commits the Formula change to a new branch, `release/formula-vX.Y.Z`, and pushes the branch with the deploy key.
Because the deploy key made the push, the `release/**` push trigger in `ci.yml` runs CI on the branch.
Finally, the workflow opens a PR against `main` with `gh pr create`, which authenticates with `GITHUB_TOKEN`.

## Secrets and permissions

The workflow uses two credentials:

- `RELEASE_DEPLOY_KEY`: the private SSH key of a deploy key with write access.
  The workflow uses it for the checkout and for every git push.
- `GITHUB_TOKEN`: the token that GitHub provides to every workflow run.
  The workflow uses it for `gh pr create`, and the `permissions` block of the workflow grants it `contents: write` and `pull-requests: write`.

## Recovery from a failed release run

The way to recover depends on whether the workflow failed before or after its first push.

### Failure before the first push

The workflow runs validation and `make check` before it pushes anything, so a failure at those steps leaves the repository unchanged.
Fix the cause, such as a malformed version input or a failing test on `main`, and run the workflow again.

### Failure after the bump commit or the tag reached GitHub

The workflow doesn't roll back a pushed commit or tag.
A second run with the same version fails validation, because `VERSION` in `bin/skill-link` already matches the input.
You have to finish the remaining steps by hand.

If the bump commit reached `main` but the tag didn't, create the tag on the bump commit and push it.

```bash
git fetch origin
git tag -a vX.Y.Z -m vX.Y.Z <bump-commit-sha>
git push origin vX.Y.Z
```

If the tag reached GitHub but the workflow didn't open the Formula PR, compute the sha256 of the tag tarball first.

```bash
curl -fsSL https://github.com/Mizumaki/homebrew-skill-link/archive/refs/tags/vX.Y.Z.tar.gz \
  | shasum -a 256
```

Then update `url` and `sha256` in `Formula/skill-link.rb` on a branch named `release/formula-vX.Y.Z`, and open a PR named `Update Formula to vX.Y.Z`.

### Missing GitHub Release

`release.yml` runs on every push of a `v*` tag, except a push that `GITHUB_TOKEN` makes.
If the tag exists but the GitHub Release doesn't, create the GitHub Release from the tag.

```bash
gh release create vX.Y.Z --generate-notes
```
