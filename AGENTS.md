# Development Rules

## Git Workflow

- **Never push directly to `main` or `master`**
- Always create a feature branch for changes
- Use pull requests for merging
- After completing a phase, create a PR and request review

## Before Any Commit

1. Run lint/typecheck if available
2. Verify tests pass
3. Check `.gitignore` excludes secrets and runtime data
4. Never commit: `.env`, passwords, API keys, tokens, databases, logs

## Code Style

- Follow existing patterns in the codebase
- Use existing libraries before adding new dependencies
- Add comments only when necessary for understanding
