# Flutter and Dart Development Rules

## Description
Guidelines and rules for Flutter/Dart development in our TikTok clone project.

## Globs
- lib/**/*.dart
- test/**/*.dart

## Architecture Rules

### Clean Architecture
- Use clean architecture principles
- Organize code into:
  - Models (lib/models/)
  - Screens (lib/screens/)
  - Services (lib/services/)
  - Widgets (lib/widgets/)
  - Controllers (lib/controllers/)

### State Management
- Use Provider for state management
- Use Freezed for immutable state classes
- Controllers should only take methods as input and update UI state
- Use GetIt for dependency injection:
  - Singleton for services and repositories
  - Factory for use cases
  - Lazy singleton for controllers

## Coding Standards

### Naming Conventions
- PascalCase for classes
- camelCase for variables, functions, and methods
- snake_case for files and directories
- UPPERCASE for constants
- Start boolean variables with is/has/can
- Use complete words over abbreviations

### Function Guidelines
- Keep functions under 20 lines
- Single responsibility principle
- Early returns over nested if statements
- Use higher-order functions when possible
- Declare parameter and return types explicitly

### Widget Guidelines
- Break down large widgets into smaller components
- Avoid deeply nested widget trees
- Use const constructors where possible
- Keep build methods clean and readable
- Extract reusable widgets to lib/widgets/

### Testing Requirements
- Unit tests for all public functions
- Widget tests for UI components
- Integration tests for API modules
- Follow Arrange-Act-Assert pattern
- Use meaningful test names and variables 