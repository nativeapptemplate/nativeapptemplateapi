# Contributing to NativeAppTemplate API

Thanks for your interest in contributing! This document explains how to report issues, propose changes, and submit pull requests.

## Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold it.

## Reporting Bugs

Before opening an issue, please:

1. Search existing [issues](https://github.com/nativeapptemplate/nativeapptemplateapi/issues) to avoid duplicates.
2. Confirm the bug reproduces on the `main` branch.
3. Include:
   - Ruby and Rails versions (`ruby -v`, `bin/rails -v`)
   - PostgreSQL version
   - Steps to reproduce
   - Expected vs actual behavior
   - Relevant log output or stack traces

## Reporting Security Vulnerabilities

**Do not open public issues for security vulnerabilities.** See [SECURITY.md](SECURITY.md) for the disclosure process.

## Proposing Changes

For non-trivial changes, please open an issue first to discuss the approach before investing implementation time.

## Pull Requests

1. Fork the repository and create a feature branch from `main`.
2. Make your changes with clear, focused commits.
3. Add or update tests for any behavioral changes.
4. Run the full test suite locally:
   ```bash
   bin/rails test
   ```
5. Run the linter and security scanner:
   ```bash
   bin/rubocop
   bin/brakeman --no-pager
   ```
6. Push your branch and open a pull request against `main`.
7. In the PR description, explain *what* changed and *why*.

### Style

This project uses [RuboCop with the Rails Omakase style](https://github.com/rails/rubocop-rails-omakase). Please ensure `bin/rubocop` passes before submitting.

### Tests

- Tests use Minitest with parallel execution.
- Place new tests under `test/` mirroring the source structure.
- Use fixtures (`test/fixtures/`) for test data.
- Mock external HTTP calls with WebMock.

## Development Setup

See [README.md](README.md) for full setup instructions.

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).
