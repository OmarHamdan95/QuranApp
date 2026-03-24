# CLAUDE.md - Quran App Project Guide

## Project Overview

A comprehensive Quran companion app for iOS and Android, built with Flutter. Features include Quran reading (Uthmani script with RTL support), audio playback by multiple reciters, memorization tracking (Hifz), prayer times and Qibla compass, tafsir, search, bookmarks, and Quran quizzes (Mosabqat). 100% ad-free.

## Architecture

### Clean Architecture (3-layer)

```
lib/
  core/              # App-wide utilities
    constants/       # App constants, enums
    extensions/      # Dart extension methods
    routing/         # GoRouter configuration
    theme/           # Colors, text styles, ThemeData
  features/          # Feature modules (each self-contained)
    <feature>/
      data/          # Models, repository implementations, data sources
        models/      # Data transfer objects / serialization models
        repositories/# Repository implementations
      domain/        # Business logic, pure Dart (no Flutter imports)
        entities/    # Core business objects
        repositories/# Abstract repository contracts
        usecases/    # Single-purpose use case classes
      presentation/  # UI layer
        providers/   # Riverpod providers and state notifiers
        screens/     # Full-screen widgets (pages)
        widgets/     # Reusable UI components for this feature
  shared/            # Cross-feature shared code
    widgets/         # Common widgets (scaffold, loading, error)
    models/          # Shared data models
```

### Feature Modules

| Feature | Description |
|---------|-------------|
| `quran` | Core reading experience: surah/juz index, reader, font sizing |
| `audio` | Reciter selection, playback controls, download management |
| `bookmarks` | Bookmark and favorite ayahs with notes and color labels |
| `tafsir` | Quran interpretation from multiple sources |
| `search` | Full-text search across ayahs |
| `prayer` | Prayer times calculation, Qibla compass |
| `hifz` | Memorization plans, progress tracking, self-testing |
| `mosabqat` | Quran quizzes, daily challenges, statistics |
| `settings` | Theme, font size, reciter, prayer method preferences |
| `onboarding` | Splash screen and first-launch tutorial |
| `downloads` | Offline audio file management |
| `home` | Dashboard with daily ayah, last read, prayer countdown |

## Tech Stack

- **Framework**: Flutter 3.16+ / Dart 3.2+
- **State Management**: Riverpod (Provider + StateNotifier pattern)
- **Routing**: GoRouter with StatefulShellRoute for bottom nav
- **Local DB (user data)**: Isar
- **Bundled DB (Quran text)**: SQLite via sqflite
- **Audio**: just_audio + audio_service
- **Prayer Times**: adhan_dart
- **Qibla**: flutter_compass + geolocator
- **Analytics**: Firebase Analytics + Crashlytics
- **Networking**: Dio
- **Serialization**: freezed + json_serializable (code generation)

## Coding Conventions

### Dart Style

- Follow the official [Effective Dart](https://dart.dev/effective-dart) guide.
- Use `const` constructors everywhere possible.
- Prefer `final` for local variables and fields.
- Use `super` parameters in constructors.
- Private classes/members: prefix with `_`.
- Abstract classes for interfaces: use `abstract class`, not `abstract interface class`.
- Use `abstract final class` for utility classes with only static members.

### Naming

- Files: `snake_case.dart`
- Classes: `PascalCase`
- Variables/functions: `camelCase`
- Constants: `camelCase` (not SCREAMING_CAPS)
- Providers: descriptive name ending with `Provider` (e.g., `surahsProvider`, `audioPlayerProvider`)
- Screens: suffix with `Screen` (e.g., `HomeScreen`, `QuranReaderScreen`)
- Widgets: descriptive name, no suffix (e.g., `SurahListTile`, `AudioControlsWidget`)

### Arabic Text

- Always use `textDirection: TextDirection.rtl` for Arabic text widgets.
- Use `AmiriQuran` font family for Quran ayah text.
- Use `Amiri` font family for Arabic UI text.
- System font for Latin/English text.
- Use `.toArabicNumerals` extension for Eastern Arabic numerals in UI.

### Riverpod Patterns

- `Provider` for static/computed values and repository singletons.
- `StateProvider` for simple mutable state (theme mode, font size).
- `FutureProvider` for async data fetching.
- `FutureProvider.family` for parameterized fetches (e.g., ayahs by surah).
- `StateNotifierProvider` for complex mutable state with business logic.
- Override `quranRepositoryProvider` at app startup after DB initialization.

### Imports

- Use package imports (`package:quran_app/...`), not relative imports.
- Group imports: Dart SDK, Flutter, packages, local (separated by blank lines in the linter but not enforced in all files currently).

## Branch Strategy

- `main` - production-ready releases
- `develop` - integration branch for features
- `feature/<name>` - individual feature branches (e.g., `feature/audio-player`)
- `fix/<name>` - bug fix branches
- `release/<version>` - release preparation branches

All PRs target `develop`. Releases merge `develop` into `main` with version tags.

## How to Build and Run

### Prerequisites

- Flutter SDK >= 3.16.0
- Dart SDK >= 3.2.0
- Xcode (for iOS builds)
- Android Studio (for Android builds)
- CocoaPods (for iOS dependencies)

### Setup

```bash
# Get dependencies
flutter pub get

# Run code generation (freezed, json_serializable, isar, riverpod)
dart run build_runner build --delete-conflicting-outputs

# Run on a connected device or emulator
flutter run

# Run tests
flutter test

# Analyze code
flutter analyze
```

### Asset Setup

Place the following in the `assets/` directory:
- `assets/fonts/` - Amiri, AmiriQuran, ScheherazadeNew font files
- `assets/data/quran.db` - Pre-built SQLite database with surahs and ayahs tables
- `assets/images/` - App images and illustrations
- `assets/icons/` - Custom icons

### Firebase Setup

1. Create a Firebase project at console.firebase.google.com
2. Add Android app: place `google-services.json` in `android/app/`
3. Add iOS app: place `GoogleService-Info.plist` in `ios/Runner/`
4. Uncomment Firebase initialization in `lib/main.dart`

## Key Files

- `lib/main.dart` - App entry point, ProviderScope, MaterialApp.router
- `lib/core/routing/app_router.dart` - All route definitions
- `lib/core/theme/app_theme.dart` - Light and dark ThemeData
- `lib/core/constants/app_constants.dart` - Global constants and enums
- `lib/features/quran/presentation/providers/quran_providers.dart` - Quran state management
- `pubspec.yaml` - Dependencies and asset declarations
