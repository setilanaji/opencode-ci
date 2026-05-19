# Fixtures — Risk Tiering

Reference diffs used to construct manual smoke-test PRs in `validation.md`
§ 2.

| File | Used in | Scenario |
|---|---|---|
| `trivial-readme.diff` | § 2.1 | Tiny README typo → trivial → skip |
| `threshold-10loc.diff` | § 2.2 | Exactly at threshold → trivial |
| `threshold-11loc.diff` | § 2.3 | One LOC over threshold → standard |
| `sensitive-auth-tiny.diff` | § 2.5 | Tiny auth change → forced to full |
| `sensitive-plus-readme.diff` | § 2.6 | Sensitive + non-sensitive → full |
| `migration-tiny.diff` | § 2.8 | Tiny migration → full |

## How to use

1. Fork a sandbox repo.
2. `git apply specs/.../fixtures/<name>.diff`.
3. Commit, push, open a PR.
4. Verify the tier outcome matches `validation.md` § 2.
