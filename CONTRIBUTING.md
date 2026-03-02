# Contributing to TrieDictionary

Thanks for your interest in contributing! Here's how to get started.

## Filing Issues

- Search existing issues before opening a new one
- For bugs, include: Swift version, platform, minimal reproduction, expected vs actual behavior
- For feature requests, describe the use case and proposed API

## Submitting Pull Requests

1. Fork the repo and create a branch from `main`
2. Make your changes
3. Run the test suite: `swift test`
4. Ensure your code compiles with `swift build`
5. Open a PR against `main`

### PR Guidelines

- Keep changes focused — one feature or fix per PR
- Add tests for new functionality
- Follow the existing code style (4-space indentation, no trailing semicolons)
- Update the README if you change public API

## Running Tests

```bash
swift test                            # All tests
swift test --filter PerformanceTests  # Benchmarks only
swift test --filter UsageExampleTests # Usage examples
```

## Code Style

- 4-space indentation
- No trailing semicolons
- Use `guard` for early returns
- Prefer value types (`struct`, `enum`) over reference types
- All public API must be `Sendable`-safe (Swift 6 concurrency)

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
