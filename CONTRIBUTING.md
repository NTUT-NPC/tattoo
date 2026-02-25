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

Include `[skip upload]` in the commit body to skip the build number bump and Firebase/TestFlight upload while still running the build. Use this to preserve upload rate limits on changes that don't need testing on device.

**Examples:**

- `feat: add student query service`
- `fix(android): resolve notification permission crash`
- `docs: update architecture section`

## Branch Names

Use kebab-case: `add-student-query-service`, `fix-login-crash`

## Git and GitHub Workflows

- Use rebase to update PRs with the base branch, unless there are conflicts.
- AI review comments should be addressed and resolved by the PR author.
- Human review comments should be resolved by the reviewer.
