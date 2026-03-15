# RideSync

RideSync is a Flutter-based group project for ride booking and management.

## Tech Stack

- Flutter
- Dart
- Provider

## Getting Started

### Prerequisites

- Flutter SDK
- Dart SDK
- Android Studio or VS Code
- GitHub Desktop or Git

### Run the project

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:3000
```

### Environment configuration

Use `--dart-define` for non-sensitive configuration values such as the API base URL.

Example:

```bash
flutter run --dart-define=API_BASE_URL=https://dev-api.example.com
flutter build apk --dart-define=API_BASE_URL=https://api.example.com
```

Do not store private API keys, database passwords, or backend secrets in the Flutter app.

## Branch Strategy

- `main`: stable, release-ready code
- `develop`: shared integration branch for the team
- `feature/*`: feature development branches
- `bugfix/*`: normal bug fix branches
- `hotfix/*`: urgent production fixes

## Team Workflow

1. Pull the latest `develop` branch.
2. Create a new branch from `develop`.
3. Use a branch name such as `feature/login-ui`.
4. Make changes and test them locally.
5. Commit and push your branch.
6. Open a pull request into `develop`.
7. Get at least one review before merging.
8. Merge `develop` into `main` only when the build is stable.

## Team Rules

- Do not push directly to `main`.
- Do not code directly on `develop`.
- Always create a separate branch for your task.
- Always open a pull request before merging.
- Pull the latest changes before starting new work.
- Use clear commit messages.

## Commit Message Examples

- `add login form validation`
- `create home screen layout`
- `fix profile image picker bug`
- `connect booking page to provider`

## Repository Settings

- Visibility: Private
- Default branch: `develop`
- Protected branches: `main`, `develop`
- Pull request approvals required: 1
- Merge strategy: Squash and merge

## Contributors

- Project leader and team members can be listed here.
