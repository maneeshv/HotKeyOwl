# Contributing to HotKeyOwl

Thank you for your interest in contributing to HotKeyOwl! This document provides guidelines for contributing to the project.

## Getting Started

### Development Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/maneeshv/HotKeyOwl.git
   cd HotKeyOwl
   ```

2. Install XcodeGen (if not already installed):
   ```bash
   brew install xcodegen
   ```

3. Generate the Xcode project:
   ```bash
   xcodegen generate
   ```

4. Build and run:
   ```bash
   ./scripts/build-debug.sh
   ```

See [AGENTS.md](AGENTS.md) for detailed development instructions.

## How to Contribute

### Reporting Bugs

1. Check if the bug has already been reported in [Issues](https://github.com/maneeshv/HotKeyOwl/issues)
2. If not, create a new issue using the bug report template
3. Include:
   - macOS version
   - App version
   - Steps to reproduce
   - Expected vs actual behavior
   - Screenshots if applicable

### Suggesting Features

1. Check existing [Issues](https://github.com/maneeshv/HotKeyOwl/issues) for similar requests
2. Create a new issue using the feature request template
3. Describe the feature and its use case

### Pull Requests

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature-name`
3. Make your changes
4. Test your changes thoroughly
5. Commit with clear messages
6. Push to your fork
7. Open a Pull Request against `main`

#### PR Guidelines

- Keep PRs focused on a single change
- Update documentation if needed
- Follow existing code style (see below)
- Ensure the build passes

## Code Style

- **Swift**: Follow existing patterns in the codebase
- **Indentation**: 4 spaces
- **Imports**: System frameworks first, then third-party
- **Naming**: UpperCamelCase for types, lowerCamelCase for variables/functions
- Use `// MARK: -` to organize code sections

## Questions?

Open an issue with the "question" label or start a discussion.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
