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

**Scopes (optional):** use `android` or `ios` when the change is platform-specific.

**Examples:**

- `feat: add student query service`
- `fix(android): resolve notification permission crash`
- `docs: update architecture section`

## Branch Names

Use kebab-case: `add-student-query-service`, `fix-login-crash`

## Code Style

Dart 3 idioms — prefer these over traditional alternatives:

- **Switch expressions** over `if`/`else` chains for producing values: `final x = switch (y) { ... };`
- **Dot shorthands** where type is inferred: `.externalApplication` not `LaunchMode.externalApplication`
- **If-case null checks**: `if (x case final x?)` not `if (x != null)`
- **Formatter workaround:** Wrap enhanced enums (with fields/methods) in `// dart format off` / `// dart format on` — the formatter splits the last value's trailing `;` onto its own line

## Typography & i18n

**CJK and Latin/numeric characters:** Do not insert literal spaces between CJK and alphanumeric characters in i18n strings or UI code. The rendering layer (or the user's browser/system) should handle the presentation-level spacing (see [#149](https://github.com/NTUT-NPC/tattoo/issues/149)).

## Git and GitHub Workflows

- Updating a branch with the base branch: prefer rebase, but use merge if the branch contains commits by other contributors (rebase rewrites authorship) or if there are conflicts.
- AI review comments should be addressed and resolved by the PR author.
- Human review comments should be resolved by the reviewer.
- Fix formatting and lint errors in the same commit as the code change, not as a separate commit.
