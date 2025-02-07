# Development Guidelines for D&D TikTok Clone

This document establishes our coding standards, integration protocols, and best practices to ensure our code remains organized, maintainable, and free from redundant implementations. It also provides guidance on how to effectively collaborate with AI assistants (e.g., CursorAI, Claude) by sharing context from our documentation.

## Code Organization & Naming Conventions

- **Directory Organization:**
  - **lib/models/:** Contains data models (e.g., `user.dart`, `video.dart`, `collection.dart`). Follow Dart's class naming conventions (PascalCase for classes, snake_case for files).
  - **lib/screens/:** Contains all UI screens. Files should be named with the feature purpose (e.g., `login_screen.dart`, `video_feed_screen.dart`).
  - **lib/services/:** Houses all business logic and Firebase integrations. Use clear names like `auth_service.dart`, `firestore_service.dart`, etc.
  - **lib/widgets/:** Contains reusable UI components. Name these components based on their functionality (e.g., `video_card.dart`, `video_interaction.dart`, `common_button.dart`).

- **Naming Conventions:**
  - Class names: Use PascalCase (e.g., `AuthService`).
  - File names: Use snake_case corresponding to their functionality (e.g., `auth_service.dart`).
  - Method names: Use camelCase (e.g., `signInUser()`).
  - Constant names: Use uppercase with underscores (e.g., `API_KEY`).

## Integration Guidelines

- **Feature Registration:**
  - Before implementing new features or modifications, consult the [Feature Inventory](./feature_inventory.md) to check for overlapping functionality.
  - Once a new feature is implemented, update its status and location in the [Feature Inventory](./feature_inventory.md).

- **Code Reusability:**
  - Reuse components from `lib/widgets/` whenever possible.
  - For common logic (e.g., Firebase initialization, API calls), centralize code in the service classes under `lib/services/`.

- **State Management:**
  - Use the state management solution defined in `docs/architecture.md` (e.g., Provider or BLoC) to ensure uniform handling of application state across screens.
  - Clearly separate presentation logic from business logic by keeping them in screens/widgets vs. services.

- **Documentation & Comments:**
  - Write clear comments at the top of each file explaining its purpose.
  - Use inline comments sparingly to elucidate complex logic.
  - Update documentation promptly when any significant changes are made.

## Guidelines for Working with AI Tools (CursorAI/Claude)

- **Providing Context:**
  - Before starting any new session with an AI assistant, provide excerpts from these documents (especially `architecture.md` and `feature_inventory.md`) to ensure context awareness.
  - If requested, include file paths and relevant code snippets to prevent duplicate logic generation or unconventional patterns.

- **Review & Consolidation:**
  - When AI tools suggest new code, always cross-check against existing modules to prevent duplication.
  - If a feature already exists (as listed in the [Feature Inventory](./feature_inventory.md)), verify and use the existing implementation rather than introducing redundant code.

## Updating the Documentation

- **Feature Inventory:**  
  Update the status, file locations, and sub-task checklist for each feature post-implementation or when modifications occur.

- **Architecture Overview:**  
  Revise the `docs/architecture.md` if the project structure or architectural patterns change significantly.

- **Development Standards:**  
  Amend this document (`development_guidelines.md`) as needed when new practices or tools are adopted by the team.

### State Management with Freezed

- Use Freezed for all immutable state classes
  ```dart
  @freezed
  class SearchState with _$SearchState {
    const factory SearchState({
      required String query,
      @Default(false) bool isLoading,
      String? error,
      @Default([]) List<Video> videoResults,
      @Default([]) List<Map<String, dynamic>> userResults,
      @Default([]) List<String> recentSearches,
    }) = _SearchState;
  }
  ```

- Follow these patterns for Freezed classes:
  - Always declare factory constructors as `const`
  - Use `@Default` for fields with default values
  - Implement `fromJson/toJson` for classes that need serialization
  - Use private constructors for internal state
  - Keep state classes focused and single-purpose

- Generate Freezed files:
  ```bash
  flutter pub run build_runner build --delete-conflicting-outputs
  ```
  - Run after any changes to Freezed classes
  - Use `--delete-conflicting-outputs` to avoid conflicts
  - Consider using `watch` instead of `build` during development

- State Updates:
  - Use `copyWith` for immutable updates
  - Avoid direct state modification
  - Handle all edge cases in state transitions
  - Provide clear error states
  - Use factory constructors for common states

### Dependency Management

- Use exact versions in pubspec.yaml for stability
- Keep dependencies up to date with `flutter pub outdated`
- Run `flutter pub upgrade` regularly
- Document major dependency changes
- Use dev_dependencies appropriately:
  ```yaml
  dev_dependencies:
    build_runner: ^2.4.8
    freezed: ^2.4.7
    json_serializable: ^6.7.1
  ```

--- 