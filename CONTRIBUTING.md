# Contributing

## Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>[optional scope]: <description>
```

**Types:** `feat`, `fix`, `chore`, `ci`, `test`, `docs`

**Scopes (optional):** `android`, `ios`

**Examples:**
- `feat: add student query service`
- `fix(android): resolve notification permission crash`
- `docs: update architecture section`

## Branch Names

Use kebab-case: `add-student-query-service`, `fix-login-crash`

## Dependencies

Pin exact versions (no caret `^` constraints). Renovate manages updates.

```bash
flutter pub add dio
```

Then edit `pubspec.yaml` to remove the caret:

```yaml
# Before
dio: ^5.9.1

# After
dio: 5.9.1
```
