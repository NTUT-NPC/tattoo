# Contributing

## Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```text
<type>[optional scope]: <description>
```

**Types:**

- `feat` — end-user visible new functionality or behavior change, including performance improvements
- `fix` — end-user visible bug fixes
- `refactor` — restructuring code without changing behavior
- `chore` — dependency updates, config changes, i18n strings, other maintenance
- `ci` — GitHub Actions workflows and Fastlane
- `test` — adding or updating tests
- `docs` — documentation only, including dart doc comments (`///`)

**Scopes (optional):** only `android` or `ios`, for platform-specific changes. Omit the scope otherwise.

**Examples:**

- `feat: add student query service`
- `fix(android): resolve notification permission crash`
- `docs: update architecture section`

## Branch Names

Use kebab-case: `add-student-query-service`, `fix-login-crash`

## Code Style

Dart 3 idioms not yet covered by linter rules (see [#288](https://github.com/NTUT-NPC/tattoo/issues/288)):

- **Switch expressions** over `if`/`else` chains for producing values: `final x = switch (y) { ... };`
- **If-case null checks** outside collections: `if (x case final x?)` not `if (x != null)`
- **`.nonNulls` over `.whereType<T>()`** when filtering nulls from a known type: `.map(...).nonNulls` not `.map(...).whereType<String>()`
- **Formatter workaround:** Wrap enhanced enums (with fields/methods) in `// dart format off` / `// dart format on` — the formatter splits the last value's trailing `;` onto its own line

## Doc Comments

- **Reference typedef record fields with backticks, not brackets:** `` `UserDto.avatarFilename` `` not `[UserDto.avatarFilename]`. `dart doc` can't resolve `.field` on records (only on classes/enums) and will warn with "unresolved doc reference". The typedef itself (`[UserDto]`) still works in brackets.

## Typography & i18n

- **No CJK–Latin spaces (in-app only):** Do not insert literal spaces between CJK and alphanumeric characters in i18n strings or UI text. Spacing is a rendering concern. GitHub discussions should still use spaces for readability.

## HTML Snapshot Capture

- Use `dart run tool/html_snapshot.dart list` to inspect supported raw HTML/XML capture presets.
- Use `dart run tool/html_snapshot.dart capture <preset> [<preset>...] -m "<message>"` to capture one or more known pages.
- Use `dart run tool/html_snapshot.dart capture -a -m "<message>"` to capture every preset that can be resolved without explicit IDs.
- Captures are written to `tmp/html_snapshot/` and are local-only. Never commit raw captures because they may contain personal data.
- Each capture starts with a commented metadata block containing a raw-capture warning, `preset`, `request_url`, `fetchtime`, and `message`. Before promoting a captured page into tests, documentation, or fixtures, de-identify it, review the result manually, and replace any TODO placeholder with a meaningful `message`; snapshots without a message are not accepted for submission.
- When adding or changing a Service-layer HTML/XML parser request, check whether `tool/html_snapshot/presets.dart` should gain or update a preset for that request.

## Git and GitHub Workflows

- Updating a branch with the base branch: prefer rebase, but use merge if the branch contains commits by other contributors (rebase rewrites authorship) or if there are conflicts.
- AI review comments should be addressed and resolved by the PR author.
- Human review comments should be resolved by the reviewer.
- Fix formatting and lint errors in the same commit as the code change, not as a separate commit.
