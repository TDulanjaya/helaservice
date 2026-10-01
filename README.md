# HelaService

HelaService is an on-demand home and local services mobile application built with Flutter and Firebase. It seamlessly connects customers seeking reliable home repairs and services with skilled, verified local service providers and technicians.

---

## Features

- **Role-Based Experience**: Dedicated workflows for Customers and Service Providers, with seamless role switching.
- **Job Requests & Quoting**: Customers can post broadcast job requests; providers can review requests and submit price estimates/quotes.
- **Direct Bookings**: Customers can discover nearby providers by trade, view ratings, and book services directly.
- **Live Location Tracking**: Real-time provider en-route tracking and interactive map views powered by `flutter_map`.
- **In-App Messaging**: Real-time direct chat between customers and service providers.
- **Provider Verification**: Identity verification workflow (NIC document submission and approval).
- **Ratings & Reviews**: Transparent post-service rating and review system.
- **Trilingual Support**: Fully localized in English, Sinhala (`si`), and Tamil (`ta`).

---

## Tech Stack

- **Framework**: [Flutter](https://flutter.dev/) (Dart)
- **Backend & Database**: [Google Firebase](https://firebase.google.com/) (Cloud Firestore, Firebase Authentication, Firebase Remote Config)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Maps & Geospatial**: `flutter_map`, `latlong2`, Stadia Maps / OpenStreetMap
- **Security Rules**: Granular Firestore Security Rules with unit test coverage

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.x or higher)
- [Dart SDK](https://dart.dev/get-dart)
- [Firebase CLI](https://firebase.google.com/docs/cli) (optional, for deploying Firestore rules)

### 1. Clone the Repository

```bash
git clone https://github.com/your-username/helaservice.git
cd helaservice
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Firebase Configuration

> **Firebase config: create your own project**  
> This repository does not bundle production Firebase credentials. You must connect your own Firebase project to run the application.

1. Create a new Firebase project in the [Firebase Console](https://console.firebase.google.com/).
2. Enable the following services in your Firebase project:
   - **Authentication**: Enable Email/Password and Google Sign-In.
   - **Cloud Firestore**: Create a Firestore database in your preferred region.
   - **Remote Config** (optional): For dynamic configuration values.
3. Configure the Flutter application with your Firebase project:
   - Use the [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/):
     ```bash
     flutterfire configure
     ```
   - Alternatively, manually place your `google-services.json` in `android/app/` and `GoogleService-Info.plist` in `ios/Runner/`.
4. Deploy the Firestore security rules:
   ```bash
   firebase deploy --only firestore:rules
   ```

### 4. Environment Variables

An example configuration file is provided at `secrets.env.example`.

To supply local keys during development:

```bash
cp secrets.env.example secrets.env
```

Configure any necessary keys (such as `STADIA_MAPS_KEY` or object storage credentials for document uploads). Run Flutter with the environment file if defined:

```bash
flutter run --dart-define-from-file=secrets.env
```

Or run normally with fallback base map providers:

```bash
flutter run
```

---

---

## License

This project is licensed under the terms specified in the repository.
