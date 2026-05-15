# Fixtures — Diff Filtering

Reference diffs used to construct manual smoke-test PRs in `validation.md`
§ 2. These are NOT consumed by automation today.

| File | Used in | Scenario |
|---|---|---|
| `lockfile-and-real-code.diff` | § 2.2 | Lockfile noise alongside real code |
| `lockfile-only.diff` | § 2.3, 2.8 | All-filtered case → skip comment |
| `generated-marker.diff` | § 2.6 | File with `@generated` first-line marker |
| `migration-exempt.diff` | § 2.7 | Migration that contains a generated-marker but must NOT be filtered |

## How to use

1. Create a fork of a sandbox repo (any small repo works).
2. Apply the fixture: `git apply specs/.../fixtures/<name>.diff`.
3. Commit, push, open a PR against the fork's main branch.
4. Verify the expected behavior from `validation.md` § 2.
