# Home Inventory

A Flutter Android app to track and manage household products across rooms. Built with Material 3, Riverpod, and Supabase.

## Features

- **Multi-user households** — Share inventory data with family or roommates
- **Rooms** — Organize products by room (Kitchen, Bathroom, etc.)
- **Products** — Track name, brand, quantity, price, notes, and category
- **Search & Filter** — Find products by name, brand, or note; filter by category
- **Product History** — All changes (creation, moves, quantity updates, termination) are logged
- **Categories** — Manage custom categories with descriptions
- **Invitations** — Request to join existing houses; accept or decline incoming requests
- **Themes** — Multiple light and dark Material 3 themes
- **Localization** — English and Italian support
- **Update Checker** — Automatic daily check for new releases from GitHub

## Tech Stack

- **Frontend:** Flutter (Android only), Material 3, Riverpod v2
- **Backend:** Supabase (Auth, PostgreSQL, Row Level Security)
- **State Management:** Riverpod `StateNotifier`
- **Local Storage:** `shared_preferences`

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (>=3.11.4)
- Android SDK / Android Studio
- A Supabase project

### 1. Clone and configure

```bash
git clone https://github.com/GiovanniDrago/home_inventory.git
cd home_inventory
```

### 2. Set up Supabase database

The database schema is managed in the `application-database` repository. The app uses the shared Supabase project at `riikpjuqkgpbdarodiek`.

See `supabase/README.md` for details.

### 3. Run the app

```bash
flutter pub get
flutter gen-l10n
flutter run
```

## Building for Release

### Local debug build
```bash
flutter build apk --debug
```

### Release build (requires signing config)
```bash
flutter build apk --release
```

### Automated GitHub Release

1. Create an Android signing keystore:
   ```bash
   keytool -genkey -v -keystore android/app/release.keystore -alias upload -keyalg RSA -keysize 2048 -validity 10000
   ```

2. Configure GitHub Secrets in your repository:
   - `KEYSTORE_BASE64` — Base64-encoded content of `android/app/release.keystore` (base64 -w 0 android/app/release.keystore)
   - `KEYSTORE_PASSWORD` — Your keystore password
   - `KEY_PASSWORD` — Your key password
   - `KEY_ALIAS` — `upload` (or your chosen alias)

3. Create and push a release tag:
   ```bash
   ./scripts/tag-release.sh v1.0.0
   ```

This bumps `pubspec.yaml` to `X.Y.Z+<build_number>`, commits, creates an annotated tag, and pushes it. GitHub Actions then builds 3 signed ABI-split APKs (armeabi-v7a, arm64-v8a, x86_64) and 1 AAB, and attaches all 4 artifacts to the GitHub Release.

## Project Structure

```
lib/
  models/          # Data models (House, Room, Product, etc.)
  providers/       # Riverpod state management
  screens/         # UI screens
  services/        # Supabase and Update services
  theme/           # Material 3 theme catalog
  l10n/            # Localization ARB files
  config.dart      # App configuration (Supabase URL, app identity)
  main.dart        # App entry point

supabase/
  README.md        # Supabase setup guide
```

## Localization

The app supports English and Italian. To add a new language:

1. Create `lib/l10n/app_XX.arb`
2. Add `Locale('XX')` to `supportedLocales` in `lib/main.dart`
3. Run `flutter gen-l10n`

## GitHub Release Updates

The app checks `https://github.com/GiovanniDrago/home_inventory/releases/latest` for updates:
- Automatic check once per day on app startup
- Manual check via Settings → Check for Updates
- "Remind me tomorrow" delays the prompt by 24 hours
- Opens the release page in the browser for download

## License

[LICENSE](LICENSE)
