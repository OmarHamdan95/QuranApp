# Quran App — Project Roadmap

> **Last Updated:** 2026-03-24
> **Platform:** iOS & Android (Flutter)
> **Repo:** https://github.com/OmarHamdan95/QuranApp
> **Branch Strategy:** `develop` (active) → `main` (production releases)

---

## Status Legend

| Icon | Meaning |
|------|---------|
| Done | Completed and merged into develop |
| In Progress | Currently being worked on |
| Not Started | Planned but not yet started |
| Future | Post-v1.0, not in current scope |

---

## Phase 1 — MVP Core (Weeks 1–4)

> **Goal:** A working Quran reader with audio — the foundation everything else builds on.

| # | Task | Status | Branch | Notes |
|---|------|--------|--------|-------|
| 1.1 | Project setup, folder structure, clean architecture | Done | main | 74 files, 12 feature modules |
| 1.2 | Theming (dark/light mode, Islamic-inspired colors) | Done | feature/quran-reader | AppColors, AppTheme, AppTextStyles |
| 1.3 | Navigation setup (GoRouter) | Done | main | All 26 routes defined |
| 1.4 | Quran text data integration (local SQLite) | Done | feature/quran-reader | DatabaseHelper with bundled SQLite |
| 1.5 | Surah Index with search & Makki/Madani filter | Done | feature/quran-reader | 114 surahs, filter chips |
| 1.6 | Juz Index (1–30) | Done | feature/quran-reader | All 30 juz with metadata |
| 1.7 | Quran Reader (Mushaf + list view, ayah highlighting) | Done | feature/quran-reader | Scroll view, tap-to-highlight |
| 1.8 | Last-read position auto-save & resume | Done | feature/quran-reader | SharedPreferences + SQLite |
| 1.9 | Audio playback (verse-by-verse & continuous) | Done | feature/audio-player | just_audio + audio_service |
| 1.10 | Reciter selection (10+ reciters) | Done | feature/audio-player | 12 reciters with EveryAyah.com URLs |
| 1.11 | Background playback & lock-screen controls | Done | feature/audio-player | QuranAudioHandler |
| 1.12 | Repeat modes (single ayah, range, surah loop) | Done | feature/audio-player | 4 repeat modes |
| 1.13 | Home Dashboard (last-read, quick links) | Done | feature/quran-reader | Daily Ayah, Last Read, Prayer countdown |
| 1.14 | Settings screen (theme, font size, reading mode) | Done | feature/prayer-qibla | 7 setting sections |
| 1.15 | Splash screen with animations | Done | feature/quran-reader | 3-stage animation |
| 1.16 | Onboarding walkthrough | Done | feature/quran-reader | 5-page carousel |
| 1.17 | Populate SQLite with actual Quran text data | Not Started | — | Need to bundle Tanzil.net or Alquran.cloud data |
| 1.18 | Connect audio to real EveryAyah.com streaming | Not Started | — | URLs built, need network integration |
| 1.19 | Integration testing on physical devices | Not Started | — | Requires Flutter SDK installed |

---

## Phase 2 — Personalization & Study (Weeks 5–7)

> **Goal:** Make the app personal — bookmarks, tafsir, translation, and search.

| # | Task | Status | Branch | Notes |
|---|------|--------|--------|-------|
| 2.1 | Bookmarks system with folders & notes | Done | feature/bookmarks-tafsir-search | Full CRUD, SharedPreferences (Isar-ready) |
| 2.2 | Favorites (favorite surahs) | Done | feature/bookmarks-tafsir-search | Grid/list view, quick play |
| 2.3 | Tafsir integration (5 sources) | Done | feature/bookmarks-tafsir-search | Ibn Kathir, Al-Saadi, Al-Tabari, Al-Qurtubi, Muyassar |
| 2.4 | Multi-language translation (inline toggle) | Not Started | — | UI ready, need translation data bundles |
| 2.5 | Full-text Quran search (Arabic + translation) | Done | feature/bookmarks-tafsir-search | Debounced, filters, highlighted matches |
| 2.6 | Downloads Manager (audio & tafsir packs) | Done | feature/audio-player | Batch download, progress tracking, storage mgmt |
| 2.7 | Daily Ayah card on home + push notification | Done | feature/quran-reader | Card done; push notification not yet wired |
| 2.8 | Bundle actual tafsir text data | Not Started | — | Need tafsir JSON/SQLite packs |
| 2.9 | Bundle translation data (English default) | Not Started | — | Need Sahih International / Pickthall data |
| 2.10 | Migrate bookmarks to Isar for production | Not Started | — | Currently SharedPreferences, Isar schema ready |

---

## Phase 3 — Prayer & Qibla Tools (Weeks 8–9)

> **Goal:** Transform the app from a Quran reader into a daily Islamic companion.

| # | Task | Status | Branch | Notes |
|---|------|--------|--------|-------|
| 3.1 | Prayer times (7 calculation methods) | Done | feature/prayer-qibla | Custom astronomical calculation engine |
| 3.2 | Shafi/Hanafi madhab support | Done | feature/prayer-qibla | Configurable in settings |
| 3.3 | Monthly prayer calendar view | Done | feature/prayer-qibla | Toggle between daily/monthly |
| 3.4 | GPS auto-detect location | Done | feature/prayer-qibla | LocationService with Makkah fallback |
| 3.5 | Adhan notification per prayer | Done | feature/prayer-qibla | NotificationService interface ready |
| 3.6 | Qibla Compass (real-time, animated) | Done | feature/prayer-qibla | flutter_compass, haptic feedback on alignment |
| 3.7 | Next-prayer countdown on Home | Done | feature/quran-reader | Auto-updating timer widget |
| 3.8 | Wire adhan notifications to system | Not Started | — | Service interface built, needs platform integration |
| 3.9 | Custom adhan sound selection | Not Started | — | Settings UI ready, audio files needed |

---

## Phase 4 — Hifz / Memorization (Weeks 10–11)

> **Goal:** Support users on their memorization journey with tracking and self-testing.

| # | Task | Status | Branch | Notes |
|---|------|--------|--------|-------|
| 4.1 | Hifz Plan Setup (range, targets, reminders) | Done | feature/hifz-mosabqat | Surah/juz/custom range, completion estimator |
| 4.2 | Hifz Dashboard (progress %, streak, heatmap) | Done | feature/hifz-mosabqat | 28-day heatmap, per-surah/juz progress |
| 4.3 | Self-Test Mode (audio → hide → reveal) | Done | feature/hifz-mosabqat | Score tracking, failed ayah repeat queue |
| 4.4 | Repeat-mode audio for memorization range | Done | feature/audio-player | Range repeat mode in audio player |
| 4.5 | Persist hifz progress to local DB | Not Started | — | Currently in-memory seed data |
| 4.6 | Connect self-test audio to real playback | Not Started | — | UI ready, needs audio service integration |

---

## Phase 5 — Mosabqat / Quizzes (Weeks 12–14)

> **Goal:** Gamified Islamic knowledge quizzes to boost engagement and retention.

| # | Task | Status | Branch | Notes |
|---|------|--------|--------|-------|
| 5.1 | Question bank setup (50 seed questions) | Done | feature/hifz-mosabqat | 10 per category across 5 categories |
| 5.2 | Quiz engine (category, difficulty, timer) | Done | feature/hifz-mosabqat | 3 difficulty levels with timed questions |
| 5.3 | Quiz Play screen (countdown, answers, feedback) | Done | feature/hifz-mosabqat | Animated timer, bounce feedback |
| 5.4 | Quiz Results (score, review, share) | Done | feature/hifz-mosabqat | XP animation, question review |
| 5.5 | Daily Challenge (mixed categories) | Done | feature/hifz-mosabqat | Streak bonus, special UI theme |
| 5.6 | Mosabqat Stats (accuracy, badges, levels) | Done | feature/hifz-mosabqat | Per-category bars, 6 badges, Beginner→Scholar |
| 5.7 | Expand question bank (500+ questions) | Not Started | — | Need curated Islamic knowledge content |
| 5.8 | Persist quiz scores & stats to local DB | Not Started | — | Currently in-memory |
| 5.9 | Share score as image card | Not Started | — | UI button exists, image generation needed |

---

## Phase 6 — Polish & Launch (Weeks 15–16)

> **Goal:** Final quality pass, store preparation, and launch.

| # | Task | Status | Notes |
|---|------|--------|-------|
| 6.1 | Install Flutter SDK & verify project builds | Not Started | Required before any device testing |
| 6.2 | Add pubspec.yaml platform configs (ios/, android/) | Not Started | `flutter create .` to generate platform dirs |
| 6.3 | Performance optimization (lazy loading, caching) | Not Started | |
| 6.4 | UI/UX polish (animations, transitions) | Not Started | Base animations in place |
| 6.5 | RTL layout verification across all screens | Not Started | RTL coded throughout, needs visual QA |
| 6.6 | Unit tests for all repositories & use cases | Not Started | 5 model tests exist, need full coverage |
| 6.7 | Widget tests for key screens | Not Started | |
| 6.8 | Integration tests (end-to-end flows) | Not Started | |
| 6.9 | App icon design (1024x1024) | Not Started | |
| 6.10 | App Store screenshots & descriptions | Not Started | |
| 6.11 | Privacy policy page | Not Started | |
| 6.12 | Firebase Analytics & Crashlytics setup | Not Started | |
| 6.13 | Beta testing (TestFlight / Firebase App Distribution) | Not Started | |
| 6.14 | Bug fixes from beta feedback | Not Started | |
| 6.15 | v1.0 release build & store submission | Not Started | |

---

## Phase 7 — Future / Post-Launch

> **Goal:** Social features requiring authentication, and platform expansion.

| # | Task | Status | Notes |
|---|------|--------|-------|
| 7.1 | Firebase Auth (Google, Apple, Phone OTP) | Future | Optional login, app works without it |
| 7.2 | Cross-device data sync (Firestore) | Future | Migrate local data to cloud on first sign-in |
| 7.3 | Multiplayer Mosabqat (real-time head-to-head) | Future | Requires Auth + Firestore |
| 7.4 | Leaderboards (global & friends) | Future | Weekly leaderboard |
| 7.5 | Community Khatmah (group Quran reading) | Future | Friends split juz assignments |
| 7.6 | Home screen widgets (iOS & Android) | Future | Daily Ayah + next prayer time |
| 7.7 | Apple Watch / Wear OS companion | Future | Prayer times + Qibla on wrist |
| 7.8 | Dua Collection (Quran & Sunnah) | Future | Categorized supplications |
| 7.9 | Social sharing (designed ayah cards) | Future | Beautiful shareable images |
| 7.10 | Khatmah completion tracker | Future | Track full Quran cycles |
| 7.11 | Downloadable quiz packs (remote update) | Future | Expand without app update |
| 7.12 | Accessibility (VoiceOver, TalkBack, high contrast) | Future | |
| 7.13 | Offline-first architecture | Future | Full functionality without internet |

---

## Progress Summary

| Phase | Total Items | Done | Not Started | Future |
|-------|-------------|------|-------------|--------|
| Phase 1 — MVP Core | 19 | 16 | 3 | — |
| Phase 2 — Personalization | 10 | 6 | 4 | — |
| Phase 3 — Prayer & Qibla | 9 | 7 | 2 | — |
| Phase 4 — Hifz | 6 | 4 | 2 | — |
| Phase 5 — Mosabqat | 9 | 6 | 3 | — |
| Phase 6 — Polish & Launch | 15 | 0 | 15 | — |
| Phase 7 — Future | 13 | — | — | 13 |
| **Total** | **81** | **39 (48%)** | **29 (36%)** | **13 (16%)** |

---

## Key Metrics

- **Lines of Code:** 22,000+ (Dart)
- **Feature Modules:** 12
- **Screens Implemented:** 26
- **Reciters:** 12
- **Tafsir Sources:** 5
- **Prayer Calculation Methods:** 7
- **Quiz Categories:** 5
- **Seed Quiz Questions:** 50

---

## Next Priorities

1. **Install Flutter SDK** and generate platform directories (`ios/`, `android/`)
2. **Bundle real Quran data** (text from Tanzil.net, translations, tafsir packs)
3. **Wire audio streaming** to EveryAyah.com CDN
4. **Persist user data** — migrate from SharedPreferences to Isar for bookmarks, hifz, quiz stats
5. **Add test coverage** — unit tests for repositories, widget tests for key screens
6. **Platform integration** — adhan notifications, location permissions, background audio

---

> **Estimated Timeline:** ~16 weeks from start to v1.0 launch
> **Current Status:** UI & architecture complete (48%), data integration & polish remaining (52%)
