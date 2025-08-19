# CrypticDash Testing

This directory contains the test suite for CrypticDash, focusing on essential functionality without over-engineering.

## Test Structure

### Service Tests (`test/services/`)
- **`github_service_test.dart`** - Tests GitHub API service logic
  - Token management (set, clear, validation)
  - Error handling for missing tokens
  - Basic service initialization
- **`project_service_test.dart`** - Tests project management logic
  - Project list management (add, remove, update)
  - Unmodifiable list protection
  - Basic service functionality

### Widget Tests (`test/widgets/`)
- **`dashboard_screen_test.dart`** - Tests dashboard UI components
  - Basic widget instantiation
  - Widget structure validation
  - Smoke tests for UI components

### Integration Tests (`test/integration/`)
- **`app_flow_test.dart`** - Tests complete app workflows
  - App launch and initialization
  - Authentication flow
  - Basic navigation structure

### Test Utilities
- **`test_config.dart`** - Common test utilities and mock data
- **`run_tests.dart`** - Test runner script

## Running Tests

### Run All Tests
```bash
flutter test
```

### Run Specific Test Categories
```bash
# Service tests only
flutter test test/services/

# Widget tests only  
flutter test test/widgets/

# Integration tests only
flutter test test/integration/
```

### Run Tests with Coverage
```bash
flutter test --coverage
```

### Run Tests in Watch Mode (for development)
```bash
flutter test --watch
```

## What These Tests Cover

### Essential Functionality
1. **Service Logic** - Core business logic works correctly
   - GitHub service token management
   - Project service list operations
   - Error handling for missing dependencies
2. **UI Components** - Basic UI elements render properly
   - Widget instantiation without crashes
   - Basic structure validation
3. **App Structure** - App launches and shows correct screens
   - Authentication flow initialization
   - Basic navigation setup
4. **Error Handling** - Services handle errors gracefully
   - Missing token scenarios
   - Service initialization failures

### What They Don't Cover (Intentionally)
- Complex UI interactions (manual testing is sufficient)
- Network calls (mocked for reliability)
- Platform-specific behavior (manual testing on devices)
- Performance metrics (not needed for end users)
- Complex provider dependencies (simplified for testing)

## Test Philosophy

These tests follow the **KISS principle**:
- Keep tests simple and focused
- Test behavior, not implementation
- Use mocks for external dependencies
- Focus on catching regressions when you make changes, not achieving 100% coverage

## Current Test Status

✅ **All tests passing** - 14 tests total
- 6 service tests
- 2 widget tests  
- 2 integration tests
- 2 main app tests
- 2 test runner tests

## Adding New Tests

When adding new tests, focus on:
- **Critical paths** that would break the app
- **Business logic** that's hard to test manually
- **Error conditions** that users might encounter

Avoid testing:
- Simple UI rendering (Flutter handles this)
- Third-party library functionality
- Implementation details that change frequently

## Troubleshooting

### Common Issues
1. **SharedPreferences errors** - These are expected in tests and don't affect test results
2. **ONNX model errors** - These are expected when testing services that depend on AI models
3. **Provider not found errors** - Ensure all required providers are mocked in widget tests

### Test Best Practices
1. Use `setUpAll()` to initialize Flutter bindings
2. Mock services that access platform-specific APIs
3. Keep tests focused on single responsibilities
4. Use descriptive test names that explain what's being tested

The goal is to catch regressions when you make changes, not to replace manual testing.
