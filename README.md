# Quran App

A comprehensive Quran companion app for iOS and Android, built with Flutter. Read, listen, memorize, and explore the Holy Quran with prayer tools, tafsir, translations, quizzes, and a personalized daily experience. 100% ad-free.

## Features

- **Quran Reading** - Full Uthmani script with adjustable font size, surah/juz/page navigation
- **Audio Playback** - Listen to recitations from popular Quran reciters with offline support
- **Memorization (Hifz)** - Custom memorization plans with progress tracking and self-testing
- **Prayer Times** - Accurate prayer times based on location with multiple calculation methods
- **Qibla Compass** - Find the direction of the Kaaba using the device compass
- **Tafsir** - Read tafsir from multiple classical sources (Ibn Kathir, Tabari, Qurtubi, etc.)
- **Search** - Full-text search across the entire Quran
- **Bookmarks & Favorites** - Save and organize important ayahs with notes and color labels
- **Quran Quizzes (Mosabqat)** - Multiple quiz types with daily challenges and statistics
- **Translations** - Read translations alongside Arabic text
- **Dark Mode** - Full dark theme support with Islamic-inspired color palette
- **RTL Support** - Native right-to-left layout for Arabic text

## Tech Stack

- **Flutter** 3.16+ with Dart 3.2+
- **Riverpod** for state management
- **GoRouter** for navigation
- **SQLite** for bundled Quran data
- **Isar** for user data persistence
- **just_audio** for audio playback
- **adhan_dart** for prayer time calculations
- **Firebase** Analytics & Crashlytics

## Getting Started

### Prerequisites

- Flutter SDK >= 3.16.0
- Xcode (macOS, for iOS)
- Android Studio (for Android)

### Installation

```bash
git clone https://github.com/OmarHamdan95/QuranApp.git
cd QuranApp
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

## Architecture

Clean Architecture with feature-based module organization:

```
lib/
  core/        # Theme, constants, routing, extensions
  features/    # Feature modules with data/domain/presentation layers
  shared/      # Cross-feature shared widgets and models
```

See [CLAUDE.md](CLAUDE.md) for detailed architecture documentation.

## License

This project is private and not licensed for redistribution.
