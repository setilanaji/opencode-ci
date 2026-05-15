# Fixtures — Prompt-Injection Hardening

Reference diffs that contain injection payloads. Used in `validation.md`
§ 2 to verify the sanitizer strips them and § 3 to verify end-to-end
behavior on a fork.

| File | Used in | Payload |
|---|---|---|
| `injection-section-boundary.diff` | § 2.1, § 3 | Forged `===== RULES =====` section |
| `injection-system-tag.diff` | § 2.2 | `<system>` and `</system>` instruction tags |
| `injection-jailbreak-prose.diff` | § 2.3 | "Ignore previous instructions" prose |
| `injection-im-start.diff` | § 2.4 | `<\|im_start\|>` / `<\|im_end\|>` markers |
| `legitimate-jsx-fixture.diff` | § 2.5 | Real `<system>` JSX-like tag (false-positive test) |
| `clean.diff` | § 2.6 | Plain diff with no payloads |

## How to use

1. Build the reviewer image locally:
   `docker build -f docker/Dockerfile.reviewer -t reviewer-local .`
2. Run with the fixture mounted as the diff:
   `docker run --rm -e ANTHROPIC_API_KEY=fake -v $(pwd)/<fixture>:/workspace/pr-diff.txt:ro --entrypoint sh reviewer-local -c '/entrypoint.sh; cat /tmp/prompt.txt'`
3. Inspect `/tmp/prompt.txt` for the `[redacted: ...]` sentinel where the
   payload was.

> The fixture diffs intentionally contain attack payloads. Do not apply
> them to a real repo PR unless the reviewer image you're testing against
> already includes the sanitizer.
