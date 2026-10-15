# HelaService

An on-demand home services marketplace for Sri Lanka, built with Flutter and Firebase. Customers post jobs, receive quotes from verified local providers, and track them live on the way. Available in English, Sinhala and Tamil.

## Features

* **Job Requests & Quotes:** Post a job and receive quotes from nearby providers (firm price, estimate, or inspect first).
* **Map Location Picker:** Choose the job location with GPS, search, saved places, or by tapping the map.
* **Urgent Help:** Find online providers near you, sorted by real distance.
* **Live Tracking & Chat:** Follow the provider on the map, chat and call in-app.
* **Job Completion PIN:** Arrival check and a 6-digit PIN to confirm the job is done.
* **Verified Providers:** NIC-based identity verification before providers can accept work.
* **Flexible Pricing:** Providers choose how they charge (per hour, per day, per job, visit fee, travel per km).
* **Admin Desk:** Provider verification, user management, complaints and a live operations map.
* **Location Privacy:** Public job posts show only an approximate area; the exact location is shared only with the hired provider.
* **Multilingual:** English, Sinhala and Tamil.

## Tech Stack

* **Framework:** [Flutter](https://flutter.dev/) (Stable channel)
* **State Management:** [Provider](https://pub.dev/packages/provider) for app-wide state, `StreamBuilder` for live Firestore data, `setState` for screen-level UI
* **Backend:** [Firebase](https://firebase.google.com/) (Auth, Cloud Firestore, Cloud Messaging, Remote Config, App Check)
* **Serverless API:** [Vercel Functions](https://vercel.com/docs/functions) (Node.js)
* **File Storage:** [Backblaze B2](https://www.backblaze.com/cloud-storage)
* **Maps:** [flutter_map](https://pub.dev/packages/flutter_map) with OpenStreetMap data

## Getting Started

### Prerequisites

* [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.
* [Node.js](https://nodejs.org/) and the [Vercel CLI](https://vercel.com/docs/cli) (for the API).
* A Firebase project.
* An IDE such as Android Studio or VS Code.

### Installation

1. Clone the repository:
```
   git clone https://github.com/YOUR-GITHUB-USERNAME/helaservice.git
```
2. Navigate to the project directory:
```
   cd helaservice
```
3. Get the required dependencies:
```
   flutter pub get
```
4. Connect your own Firebase project:
```
   flutterfire configure
```
5. Run the app on a connected device or emulator:
```
   flutter run
```

### API Setup

1. Install the API dependencies:
```
   npm install
```
2. Copy `.env.local.example` to `.env.local` and fill in your own values.
3. Start the API locally:
```
   vercel dev
```

## Project Structure

* `lib/features/`: Screens grouped by role (auth, customer, provider, admin, support, shared).
* `lib/models/`: Data models (User, Technician, Job Request, Quote, Booking, Location).
* `lib/repositories/`: Firestore read and write logic for each collection.
* `lib/services/`: Auth, storage uploads, live location, routing and notifications.
* `lib/state/`: Provider state (role, language, theme).
* `lib/shared/`: Reusable widgets and shared screens.
* `lib/utils/`: Helpers for location, pricing, validation and responsive layout.
* `lib/l10n/`: Translations for English, Sinhala and Tamil.
* `api/`: Vercel serverless functions (OTP email, uploads, notifications, NIC checks).
* `firestore.rules`: Firestore security rules.

## Building for Release

To build a release-ready APK for Android:

```
flutter build apk --release
```

The generated APK will be located at `build/app/outputs/flutter-apk/app-release.apk`.

> Release builds need your own signing key (`android/key.properties`), which is not included in this repository.

## Installing on an Android Device

1. Enable Developer Options and USB Debugging on your Android device.
2. Connect your device to your computer via USB.
3. Install the app directly using Flutter:
```
   flutter install
```

Alternatively, copy the generated `app-release.apk` to your device and install it manually via a file manager.

## Map Data

Map data © OpenStreetMap contributors.
