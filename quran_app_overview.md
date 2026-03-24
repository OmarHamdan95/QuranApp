# 📖 Quran App — Mobile Application Overview

> **Platform:** iOS & Android (Flutter)
> **Project Type:** Mobile Application
> **Primary Language:** Arabic (with multi-language support)

---

## 1. App Vision

A beautiful, modern Quran companion app that allows users to **read**, **listen**, and **memorize** the Holy Quran — with built-in prayer tools, tafsir, translations, and a personalized daily experience.

### Monetization Policy
- ✅ **100% Ad-Free** — No ads of any kind, ever. The Quran experience must remain clean and distraction-free.
- ✅ **Free core features** — Reading, listening, bookmarks, prayer times, search, and daily ayah are all free.
- 💡 **Optional future revenue model (if needed):**
  - Donation / Sadaqah button (voluntary support from users)
  - Premium question packs for Mosabqat (one-time purchase, not subscription)
  - Premium reciter collections (rare/exclusive reciters)
  - Remove no features behind paywall — premium is additive only

---

## 2. Core Features

### 2.1 Quran Reading
- Full Quran text with authentic Uthmani script
- Page-by-page view (Mushaf mode) and list/surah view
- Smooth scrolling with Juz / Surah / Page navigation
- Ayah highlighting during reading and audio playback
- Last-read position auto-saved and resumed on app open
- Surah index with surah name (Arabic & transliterated), ayah count, and revelation type (Makki / Madani)

### 2.2 Audio Recitation
- Verse-by-verse and continuous surah playback
- Multiple renowned reciters (e.g., Al-Husary, Al-Minshawi, Abdul Basit, Mishary Rashid, Maher Al-Muaiqly)
- Background audio playback with lock-screen controls
- Repeat modes: single ayah repeat, range repeat (for memorization), surah loop
- Streaming with offline download support per surah or full Quran
- Audio progress indicator synced with text highlighting

### 2.3 Bookmarks & Favorites
- Bookmark any ayah with optional custom label/note
- Favorite surahs for quick access
- Bookmark categories/folders (e.g., "Morning Adhkar", "Favorites", "Study")
- Sync bookmarks across devices (if user account is enabled)

### 2.4 Daily Ayah & Notifications
- Daily Ayah of the Day displayed on home screen card
- Push notification with a daily ayah at user-configured time
- Morning / Evening Adhkar reminders
- Customizable notification schedule (time, frequency, sound)

### 2.5 Tafsir (Verse Interpretation)
- Tap any ayah to view tafsir from renowned scholars
- Multiple tafsir sources: Ibn Kathir, Al-Saadi, Al-Tabari, Al-Qurtubi
- Side-by-side or bottom-sheet view (ayah + tafsir)
- Offline tafsir data with downloadable packs

### 2.6 Translation (Multi-Language)
- Inline translation displayed below each ayah
- Supported languages: English, Urdu, French, Turkish, Indonesian, Malay, Spanish, and more
- Multiple translators per language (e.g., Sahih International, Pickthall for English)
- Toggle translation on/off per preference

### 2.7 Prayer Times & Qibla Compass
- Accurate prayer times based on user location (auto or manual)
- Multiple calculation methods (Umm Al-Qura, ISNA, Muslim World League, etc.)
- Adhan notification for each prayer with customizable sound
- Visual Qibla compass with real-time direction using device sensors
- Countdown to next prayer on home screen

### 2.8 Quran Search
- Full-text search across all ayahs in Arabic
- Search within translations
- Search by surah name, juz number, or page number
- Recent searches and suggested/popular searches
- Instant results with ayah preview and surah reference

### 2.9 Memorization / Hifz Tracker
- Set a memorization plan (daily/weekly targets)
- Track progress per surah, juz, or custom range
- Visual progress dashboard (percentage, streaks, calendar heatmap)
- Repeat-mode audio tied to selected memorization range
- Self-test mode: hide text, play audio, reveal to check
- Notes per ayah for personal memorization tips

### 2.10 Appearance & Settings
- Dark mode / Light mode / Auto (system-based)
- Adjustable Arabic font size and style (Uthmani, IndoPak, etc.)
- Translation font size control (independent of Arabic)
- Reading mode: single-page, continuous scroll, dual-page (tablet)
- Color themes for background and text

### 2.11 Authentication Strategy

> **MVP Phase: No Login Required**

- All user data (bookmarks, hifz progress, settings, last-read) stored **locally** using Hive or Isar
- Zero friction — users open the app and start immediately
- No backend dependency for core features
- Anonymous Firebase Analytics for aggregate usage tracking only

> **Future Phase: Optional Login (when community features are added)**

- **Trigger:** Introduce login when adding Community Khatmah, leaderboards, or sharing features
- **Auth Provider:** Firebase Authentication (Google Sign-In, Apple Sign-In, Phone OTP)
- **Data Migration:** On first sign-in, migrate existing local data to cloud (Firestore)
- **Principle:** App remains fully functional without login — signing in only unlocks sync & social features
- **Cloud Storage:** Firestore for synced bookmarks, hifz progress, khatmah participation

### 2.12 Mosabqat — Islamic Quizzes & Competitions (مسابقات)

An interactive quiz feature to test and strengthen Islamic knowledge across multiple categories.

#### Quiz Categories

| #  | Category               | Example Question Types                                                             |
|----|------------------------|------------------------------------------------------------------------------------|
| 1  | **Quran (القرآن)**     | Complete the ayah, identify the surah, ayah count per surah, Makki vs Madani, tafsir meaning |
| 2  | **Hadith (الحديث)**    | Identify narrator (rawi), name the hadith book (Bukhari/Muslim/etc.), complete the hadith, classify sahih/hasan/daif |
| 3  | **Fiqh (الفقه)**       | Islamic rulings on prayer/fasting/zakat, halal vs haram scenarios, pillars of Islam/Iman questions |
| 4  | **Seerah (السيرة)**    | Prophet's biography events, battles (Badr, Uhud, etc.), Hijrah timeline, key dates and places |
| 5  | **Sahabah (الصحابة)**  | Identify companion by description, match companion to achievement/title, "Who said this?", first to accept Islam, Ashra Mubashshara (العشرة المبشرين بالجنة) |

#### Quiz Modes

**MVP — Daily Challenge (no login required):**
- A new set of questions every day across all categories
- 10–15 questions per daily challenge
- Timed per question (e.g., 20 seconds for Easy, 15 for Medium, 10 for Hard)
- Score saved locally with streaks tracking (daily streak counter)
- Results screen: score, correct/wrong breakdown, correct answers review
- Share score card as image on social media

**Future — Multiplayer (requires login):**
- Challenge a friend via invite link or username
- Real-time head-to-head quiz (both answer same questions simultaneously)
- Weekly leaderboard (global & friends-only)
- Seasonal competitions with themed badges
- Lobby / matchmaking for random opponents

#### Difficulty Levels

| Level      | Description                                                                 |
|------------|-----------------------------------------------------------------------------|
| **Easy**   | Well-known ayahs, famous hadith, basic fiqh, major seerah events, famous sahabah |
| **Medium** | Less common ayahs, hadith chain details, comparative fiqh, detailed seerah timeline, lesser-known sahabah facts |
| **Hard**   | Mutashabihat ayahs, hadith classification, scholarly ikhtilaf, obscure seerah details, sahabah by rare descriptions |

#### Question Format
- Multiple choice (4 options) — primary format
- True / False — for quick rounds
- Fill in the blank — for ayah/hadith completion (type first few words)

#### Gamification Elements
- 🏆 Points system per correct answer (bonus for speed & streaks)
- 🔥 Daily streak counter (consecutive days of completing daily challenge)
- 🎖️ Badges & achievements (e.g., "Hafiz Starter" — 100 Quran questions correct, "Hadith Scholar" — 50 Hadith questions correct, "Sahabi Expert")
- 📊 Personal stats dashboard: accuracy per category, strongest/weakest category, total questions answered
- 🏅 Level progression: Beginner → Intermediate → Advanced → Scholar

#### Question Data Source
- Curated local question bank (JSON/SQLite) bundled with the app
- Categorized and tagged by: category, difficulty, language
- Expandable via remote updates (download new question packs without app update)
- Community-contributed questions (future — with moderation/review)

---

## 3. Screens List

| #  | Screen                     | Description                                                  |
|----|----------------------------|--------------------------------------------------------------|
| 1  | **Splash Screen**          | App logo, loading indicator, last-read quick resume           |
| 2  | **Home / Dashboard**       | Daily Ayah card, last-read resume, next prayer countdown, quick links |
| 3  | **Surah Index**            | List of 114 surahs with search, filter by Makki/Madani       |
| 4  | **Juz Index**              | Browse by Juz (1–30)                                         |
| 5  | **Quran Reader**           | Main reading screen — Mushaf or list view with audio controls |
| 6  | **Audio Player**           | Reciter selection, playback controls, repeat settings         |
| 7  | **Tafsir View**            | Bottom sheet or full screen tafsir for selected ayah          |
| 8  | **Search**                 | Full-text search with filters and instant results             |
| 9  | **Bookmarks**              | List of bookmarked ayahs organized by folders                 |
| 10 | **Favorites**              | Quick-access favorite surahs                                  |
| 11 | **Hifz Tracker Dashboard** | Progress overview, streak calendar, memorization stats        |
| 12 | **Hifz Plan Setup**        | Configure memorization plan (range, daily target, reminders)  |
| 13 | **Self-Test Mode**         | Audio-based recall test with reveal functionality             |
| 14 | **Prayer Times**           | Daily prayer schedule, countdown, monthly calendar view       |
| 15 | **Qibla Compass**          | Real-time compass pointing to Kaaba                           |
| 16 | **Settings**               | Theme, font, language, notification preferences, audio quality |
| 17 | **Downloads Manager**      | Manage offline audio/tafsir downloads                         |
| 18 | **Onboarding**             | First-time user walkthrough (language, location, preferences)  |
| 19 | **Mosabqat Home**          | Quiz categories grid, daily challenge card, streak counter, personal stats summary |
| 20 | **Quiz Setup**             | Select category, difficulty, number of questions              |
| 21 | **Quiz Play**              | Question display, countdown timer, answer options, progress bar |
| 22 | **Quiz Results**           | Score, correct/wrong breakdown, correct answers review, share button |
| 23 | **Mosabqat Stats**         | Accuracy per category, strongest/weakest areas, badges earned, level progress |
| 24 | **Daily Challenge**        | Today's challenge with mixed-category questions               |
| 25 | **Leaderboard** *(future)* | Global & friends rankings, weekly/monthly/all-time tabs       |
| 26 | **Multiplayer Lobby** *(future)* | Challenge friends, matchmaking, invite link generation   |

---

## 4. Suggested Tech Stack (Flutter)

| Layer              | Technology                                                    |
|--------------------|---------------------------------------------------------------|
| **IDE**            | JetBrains Rider (with Dart & Flutter plugins)                 |
| **Framework**      | Flutter (Dart)                                                |
| **State Mgmt**     | Riverpod or BLoC                                              |
| **Local DB**       | Isar (user data: bookmarks, hifz, scores, settings)           |
| **Bundled Data**   | SQLite (Quran text, translations, quiz bank)                  |
| **Cloud DB**       | Firebase Firestore (future: sync, multiplayer, leaderboards)  |
| **Auth**           | Firebase Auth (future: Google, Apple, Phone OTP)              |
| **Audio**          | just_audio + audio_service (background playback)              |
| **Notifications**  | flutter_local_notifications + Firebase Cloud Messaging        |
| **Prayer Times**   | adhan_dart package or custom calculation engine                |
| **Qibla**          | flutter_compass + geolocator                                  |
| **Quran Data API** | Alquran.cloud API / quran.com API                             |
| **Audio Source**    | EveryAyah.com / Quran.com CDN / mp3quran.net                 |
| **File Storage**   | Firebase Storage (future: downloadable packs hosting)         |
| **Quiz Data**      | Local SQLite question bank (bundled + downloadable packs)     |
| **Analytics**      | Firebase Analytics (anonymous/aggregate only)                 |
| **Crash Reports**  | Firebase Crashlytics                                          |

### 4.1 Data & Storage Architecture

#### Storage Strategy: Local-First + Firebase-Ready

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter App                           │
│                                                         │
│  ┌─────────────────┐       ┌──────────────────────┐     │
│  │  Bundled SQLite  │       │     Isar (Local)     │     │
│  │  (Read-Only)     │       │   (User Data - R/W)  │     │
│  │                  │       │                      │     │
│  │ • Quran text     │       │ • Bookmarks          │     │
│  │ • Base translate  │       │ • Favorites          │     │
│  │ • Quiz questions  │       │ • Hifz progress      │     │
│  │                  │       │ • Quiz scores/stats  │     │
│  │                  │       │ • Settings/prefs     │     │
│  │                  │       │ • Last-read position  │     │
│  │                  │       │ • Downloaded content  │     │
│  └─────────────────┘       └──────────┬───────────┘     │
│                                       │                 │
│  ┌────────────────────────────────────▼───────────┐     │
│  │         Download Manager (On-Demand)            │     │
│  │                                                 │     │
│  │  • Audio packs (per reciter/surah) → local dir  │     │
│  │  • Tafsir packs (per scholar) → local dir       │     │
│  │  • Extra translations → local dir               │     │
│  │  • New quiz packs → merged into SQLite          │     │
│  └─────────────────────────────────────────────────┘     │
│                                                         │
└──────────────────────────┬──────────────────────────────┘
                           │
                    (Future Phase 7)
                           │
              ┌────────────▼────────────┐
              │    Firebase Backend      │
              │                          │
              │ • Auth (login)           │
              │ • Firestore (sync data)  │
              │ • Storage (hosted packs) │
              │ • Cloud Functions        │
              │   (leaderboards, match)  │
              └─────────────────────────┘
```

#### What's Bundled vs Downloaded vs Cloud

| Data                  | Delivery         | Storage Location         | Size Estimate  |
|-----------------------|------------------|--------------------------|----------------|
| Quran Arabic text     | **Bundled**      | SQLite in app assets     | ~15 MB         |
| Default translation (EN + AR tafsir summary) | **Bundled** | SQLite in app assets | ~10 MB |
| Quiz question bank    | **Bundled**      | SQLite in app assets     | ~5 MB          |
| Audio recitations     | **On-demand download** | App documents dir  | ~30-50 MB/reciter |
| Full tafsir (Ibn Kathir, etc.) | **On-demand download** | App documents dir | ~20-40 MB/tafsir |
| Additional translations | **On-demand download** | App documents dir | ~5-10 MB/language |
| New quiz packs        | **On-demand download** | Merged into local SQLite | ~2-5 MB/pack |
| User data (bookmarks, progress) | **Local** | Isar DB | < 1 MB |
| Synced user data      | **Cloud (future)** | Firestore | < 1 MB |

> **Initial app download size: ~35-40 MB** (Quran text + default translation + quiz bank + app code)

#### Firebase Services Needed

| Service               | Phase   | Purpose                                          |
|-----------------------|---------|--------------------------------------------------|
| Firebase Analytics    | MVP     | Anonymous aggregate usage tracking               |
| Firebase Crashlytics  | MVP     | Crash reporting and diagnostics                  |
| Firebase Cloud Messaging | Phase 2 | Daily Ayah & prayer push notifications        |
| Firebase Auth         | Phase 7 | Google, Apple, Phone sign-in (optional login)    |
| Cloud Firestore       | Phase 7 | Sync bookmarks, hifz, scores across devices      |
| Firebase Storage      | Phase 7 | Host downloadable packs (audio, tafsir, quiz)    |
| Cloud Functions       | Phase 7 | Multiplayer matchmaking, leaderboard calculation  |

> **MVP Firebase cost: Free tier** (Analytics + Crashlytics + FCM are free). Firestore/Auth/Storage free tier covers most small-to-medium apps.

### 4.2 Rider Setup for Flutter

1. **Install Flutter SDK** — download from https://flutter.dev and add to system PATH
2. **Install Dart & Flutter Plugins in Rider:**
   - Go to `Settings → Plugins → Marketplace`
   - Search and install **Dart** plugin
   - Search and install **Flutter** plugin
   - Restart Rider
3. **Configure Flutter SDK Path:**
   - Go to `Settings → Languages & Frameworks → Flutter`
   - Set the Flutter SDK path (e.g., `~/flutter` or `C:\flutter`)
4. **Verify Setup:** Open terminal in Rider and run `flutter doctor` — ensure all checks pass
5. **Create Project:** `File → New Project → Flutter` — select Application template
6. **Run/Debug:**
   - Connect a physical device or start an emulator
   - Use the Run/Debug configurations dropdown (auto-detected by the Flutter plugin)
   - Hot Reload: `Ctrl+\` (Windows) or `Cmd+\` (Mac)

> **Tip:** Rider's Flutter plugin supports widget inspector, performance profiler, and DevTools — accessible from the tool window bar.

---

## 5. Recommended Free Quran Data Sources

| Source              | What It Provides                          | URL                          |
|---------------------|-------------------------------------------|------------------------------|
| **Alquran.cloud**   | Quran text, translations, audio, tafsir   | https://alquran.cloud/api    |
| **Quran.com API**   | Text, translations, recitations, tafsir   | https://api.quran.com        |
| **EveryAyah.com**   | Verse-by-verse audio files (multiple reciters) | https://everyayah.com   |
| **Tanzil.net**      | Quran text in multiple scripts and formats | https://tanzil.net           |
| **mp3quran.net**    | Full surah audio files                    | https://mp3quran.net         |

---

## 6. Bonus Feature Ideas (Future Versions)

- **Khatmah Tracker** — Track full Quran completion cycles with history
- **Community Khatmah** — Group Quran reading where friends split juz assignments
- **Dua Collection** — Categorized supplications from Quran and Sunnah
- **Widgets** — Home screen widgets for Daily Ayah & next prayer time
- **Apple Watch / Wear OS** — Prayer time complications & Qibla on wrist
- **Offline-First Architecture** — Full app functionality without internet
- **Accessibility** — VoiceOver/TalkBack support, high-contrast mode
- **Gamification** — Daily streaks, badges, and achievements for reading consistency
- **Social Sharing** — Share beautifully designed ayah cards on social media

---

## 7. Phased Build Plan

### Phase 1 — MVP Core (Weeks 1–4)
> **Goal:** A working Quran reader with audio — the foundation everything else builds on.

| Week | Task                                                                  | Screens Delivered       |
|------|-----------------------------------------------------------------------|-------------------------|
| 1    | Project setup, folder structure, theming (dark/light), navigation     | Splash, Onboarding      |
| 1    | Integrate Quran text data (local SQLite or JSON from Tanzil/Alquran.cloud) | —                  |
| 2    | Surah Index & Juz Index with search/filter                           | Surah Index, Juz Index  |
| 2    | Quran Reader screen (Mushaf + list view, ayah highlighting, last-read tracking) | Quran Reader   |
| 3    | Audio playback: verse-by-verse & continuous (just_audio + audio_service) | Audio Player          |
| 3    | Reciter selection, background playback, lock-screen controls          | —                       |
| 4    | Home Dashboard (last-read resume, quick links)                        | Home / Dashboard        |
| 4    | Settings screen (theme, font size, reading mode)                      | Settings                |

**Deliverable:** Users can browse, read, and listen to the full Quran with multiple reciters.

---

### Phase 2 — Personalization & Study (Weeks 5–7)
> **Goal:** Make the app personal — bookmarks, tafsir, translation, and search.

| Week | Task                                                                  | Screens Delivered       |
|------|-----------------------------------------------------------------------|-------------------------|
| 5    | Bookmarks & Favorites system (local Hive/Isar storage, folders)       | Bookmarks, Favorites    |
| 5    | Tafsir integration (Ibn Kathir, Al-Saadi — local JSON packs)          | Tafsir View             |
| 6    | Multi-language translation (inline toggle, multiple translators)       | —                       |
| 6    | Full-text Quran search (Arabic + translation, by surah/juz/page)      | Search                  |
| 7    | Downloads Manager (offline audio packs, tafsir packs)                 | Downloads Manager       |
| 7    | Daily Ayah card on home screen + push notification                    | — (Home updated)        |

**Deliverable:** Full study experience — read, listen, understand (tafsir + translation), search, and bookmark.

---

### Phase 3 — Prayer & Qibla Tools (Weeks 8–9)
> **Goal:** Transform the app from a Quran reader into a daily Islamic companion.

| Week | Task                                                                  | Screens Delivered       |
|------|-----------------------------------------------------------------------|-------------------------|
| 8    | Prayer Times (adhan_dart, location-based, multiple calculation methods) | Prayer Times           |
| 8    | Adhan notifications per prayer with customizable sounds                | —                       |
| 9    | Qibla Compass (flutter_compass + geolocator)                          | Qibla Compass          |
| 9    | Next-prayer countdown widget on Home Dashboard                         | — (Home updated)        |

**Deliverable:** Users rely on the app for daily prayer times and Qibla direction.

---

### Phase 4 — Hifz / Memorization (Weeks 10–11)
> **Goal:** Support users on their memorization journey with tracking and self-testing.

| Week | Task                                                                  | Screens Delivered       |
|------|-----------------------------------------------------------------------|-------------------------|
| 10   | Hifz Plan Setup (select range, daily target, reminders)               | Hifz Plan Setup         |
| 10   | Hifz Tracker Dashboard (progress %, streak calendar, stats)           | Hifz Tracker Dashboard  |
| 11   | Self-Test Mode (audio play → hide text → reveal to check)             | Self-Test Mode          |
| 11   | Repeat-mode audio tied to memorization range                           | —                       |

**Deliverable:** Complete memorization workflow — plan, practice, track, and test.

---

### Phase 5 — Mosabqat / Quizzes (Weeks 12–14)
> **Goal:** Gamified Islamic knowledge quizzes to boost engagement and retention.

| Week | Task                                                                  | Screens Delivered       |
|------|-----------------------------------------------------------------------|-------------------------|
| 12   | Question bank setup (JSON/SQLite — Quran, Hadith, Fiqh, Seerah, Sahabah) | —                  |
| 12   | Quiz engine: category selection, difficulty, timer logic               | Mosabqat Home, Quiz Setup |
| 13   | Quiz Play screen (question display, countdown, answer selection)       | Quiz Play               |
| 13   | Quiz Results screen (score, review, share card)                        | Quiz Results            |
| 14   | Daily Challenge mode (auto-generated mixed-category daily quiz)        | Daily Challenge         |
| 14   | Mosabqat Stats (accuracy per category, badges, level progression)      | Mosabqat Stats          |

**Deliverable:** Fully functional solo quiz system with daily challenges, 5 categories, and gamification.

---

### Phase 6 — Polish & Launch (Weeks 15–16)
> **Goal:** Final quality pass, store preparation, and launch.

| Week | Task                                                                  |
|------|-----------------------------------------------------------------------|
| 15   | Performance optimization (lazy loading, image caching, audio buffering) |
| 15   | UI/UX polish — animations, transitions, micro-interactions             |
| 15   | RTL layout verification across all screens                             |
| 16   | App Store & Google Play assets (screenshots, descriptions, icons)      |
| 16   | Beta testing (TestFlight / Firebase App Distribution)                  |
| 16   | Bug fixes from beta feedback → **v1.0 Launch** 🚀                     |

---

### Phase 7 — Future / Post-Launch (After v1.0)
> **Goal:** Social features requiring authentication.

| Feature                        | Dependency           |
|--------------------------------|----------------------|
| Optional Firebase Auth login   | Firebase setup       |
| Cross-device data sync         | Firestore migration  |
| Multiplayer Mosabqat           | Auth + Firestore     |
| Leaderboards (global & friends)| Auth + Firestore     |
| Community Khatmah              | Auth + Firestore     |
| Home screen widgets            | Native platform code |
| Khatmah completion tracker     | Local → synced       |

---

### Build Plan Summary

| Phase | Name                    | Duration  | Screens | Key Milestone                         |
|-------|-------------------------|-----------|---------|---------------------------------------|
| 1     | MVP Core                | 4 weeks   | 8       | Read & Listen to Quran                |
| 2     | Personalization & Study | 3 weeks   | 4       | Bookmarks, Tafsir, Translation, Search|
| 3     | Prayer & Qibla          | 2 weeks   | 2       | Daily Islamic companion               |
| 4     | Hifz / Memorization     | 2 weeks   | 3       | Memorization workflow                 |
| 5     | Mosabqat / Quizzes      | 3 weeks   | 6       | Gamified quizzes live                 |
| 6     | Polish & Launch         | 2 weeks   | —       | **v1.0 on App Store & Google Play**   |
| 7     | Future                  | Ongoing   | 3+      | Social, multiplayer, sync             |
|       | **Total to v1.0**       | **16 weeks** | **26 screens** | 🚀                           |

---

> **Estimated Timeline:** ~4 months from start to v1.0 launch (working solo). Can be accelerated with focused sprints or additional developers.

---

## 8. Store Accounts & Publishing Checklist

### 8.1 Developer Accounts

| Platform | Account | Cost | URL | Notes |
|----------|---------|------|-----|-------|
| **Google Play** | Google Developer Console | **$25 USD** (one-time, lifetime) | https://play.google.com/console | Uses your Gmail account, approved in 1–2 days |
| **Apple App Store** | Apple Developer Program | **$99 USD/year** (annual renewal) | https://developer.apple.com | Requires Apple ID, enrollment takes 1–3 days |
| **Firebase** | Firebase Console | **Free** | https://console.firebase.google.com | Uses same Google account |

> **Total launch cost: ~$124 first year, then $99/year (Apple renewal only)**

### 8.2 Requirements Before Publishing

#### Hardware Requirements
- ☐ **Mac computer required for iOS** — needed to run Xcode for iOS builds and signing (MacBook, iMac, or Mac Mini)
- ☐ Android builds can be done on Windows, Linux, or Mac

#### Google Play — Pre-Launch Checklist
- ☐ Create Google Developer account and pay $25 fee
- ☐ Complete account identity verification (ID + address)
- ☐ Create app listing in Google Play Console
- ☐ Prepare store listing assets:
  - ☐ App icon: 512×512 PNG
  - ☐ Feature graphic: 1024×500 PNG
  - ☐ Screenshots: minimum 2 per device type (phone, tablet)
    - Phone: 1080×1920 or 16:9 aspect ratio
    - 7" tablet: 1200×1920
    - 10" tablet: 1600×2560
  - ☐ Short description (80 chars max)
  - ☐ Full description (4000 chars max)
- ☐ Set content rating (complete questionnaire — likely "Everyone")
- ☐ Set target audience and content (not designed for children under 13, unless you want extra compliance)
- ☐ Select app category: **Education** or **Books & Reference**
- ☐ Set pricing: **Free**
- ☐ Configure countries/regions for distribution (start with MENA + worldwide)
- ☐ Privacy policy URL (required — host on a simple webpage)
- ☐ Data safety form (declare what data the app collects)
- ☐ Generate signed release APK/AAB (Android App Bundle)
- ☐ Upload AAB to Production or Internal Testing track
- ☐ Submit for review (typically 1–7 days for first app)

#### Apple App Store — Pre-Launch Checklist
- ☐ Enroll in Apple Developer Program and pay $99/year
- ☐ Create App ID and provisioning profiles in Apple Developer portal
- ☐ Create app record in App Store Connect
- ☐ Prepare store listing assets:
  - ☐ App icon: 1024×1024 PNG (no transparency, no rounded corners)
  - ☐ Screenshots (required per device size):
    - iPhone 6.7" (1290×2796) — required
    - iPhone 6.5" (1284×2778) — required
    - iPhone 5.5" (1242×2208) — optional but recommended
    - iPad 12.9" (2048×2732) — if supporting iPad
  - ☐ App preview video (optional, up to 30 seconds)
  - ☐ Description, keywords, subtitle
- ☐ Select primary category: **Education** or **Reference**
- ☐ Set age rating (complete questionnaire)
- ☐ Privacy policy URL (required)
- ☐ App Privacy "nutrition labels" (declare data collection)
- ☐ Configure in-app purchases (if adding premium packs later)
- ☐ Build and archive app in Xcode
- ☐ Upload build via Xcode or Transporter
- ☐ Submit for App Review (typically 1–3 days)

### 8.3 Additional Assets to Prepare

| Asset | Details | When Needed |
|-------|---------|-------------|
| **App Name** | Choose a unique name (check availability on both stores) | Before creating listings |
| **App Icon** | Design at 1024×1024, export sizes for both platforms | Phase 6 |
| **Privacy Policy** | Simple webpage describing data usage (no personal data collected in MVP) | Before submission |
| **Support Email** | Public email for user support/feedback | Before submission |
| **Website / Landing Page** | Optional but recommended — simple one-page site for the app | Phase 6 or post-launch |
| **Social Media** | Instagram/Twitter/X accounts for the app (for marketing) | Optional, post-launch |

### 8.4 Recommended Publishing Timeline

| When | Action |
|------|--------|
| **Week 1** | Create Google Developer & Apple Developer accounts |
| **Week 12** | Start preparing store listing assets (screenshots, descriptions) |
| **Week 14** | Design app icon, write privacy policy, create support email |
| **Week 15** | Upload beta builds to Google Play Internal Testing & TestFlight |
| **Week 15** | Invite beta testers, collect feedback |
| **Week 16** | Fix beta feedback, prepare final builds |
| **Week 16** | Submit to both stores for review |
| **Week 16–17** | 🚀 **App Live on Google Play & App Store** |

> **Tip:** Create your developer accounts in Week 1 — Google's identity verification can take a few days, and Apple enrollment can take up to 48 hours. Don't wait until launch week!
