# HelaService

An on-demand home services app built with Flutter and Firebase. Customers can book local service providers or post job requests for quotes - with real-time tracking, in-app chat, and support for English, Sinhala, and Tamil.

---

## Features

- **Job Requests & Quotes** - Post a broadcast request and receive price estimates from providers
- **Direct Bookings** - Browse nearby providers by trade, check ratings, and book instantly
- **Live Tracking & Chat** - Track providers en route and message them in-app
- **Verified Providers** - NIC-based identity verification before providers go live
- **Email Verification** - 6-digit OTP email verification before account creation
- **Multilingual** - English, Sinhala (`si`), and Tamil (`ta`)

---

## Tech Stack

| Layer    | Tools                       |
| -------- | --------------------------- |
| Frontend | Flutter                     |
| Backend  | Firebase + Vercel Functions |
| Email    | Nodemailer (Gmail SMTP)     |
| State    | Provider                    |
| Maps     | flutter_map + OpenStreetMap |

---

## Email Verification

New users must verify their email with a 6-digit code before an account is created:
- A serverless API on Vercel sends codes via Gmail SMTP
- OTPs are hashed with SHA-256 and stored in Firestore with a 5-minute expiry
- Built-in 60-second resend timer and 5-attempt limit to prevent brute force

---

## Getting Started

### Prerequisites

- Flutter SDK 3.x+
- Firebase project ([create one here](https://console.firebase.google.com/))

### Setup

```bash
git clone https://github.com/your-username/helaservice.git
cd helaservice
flutter pub get
```

> **Note:** This repo doesn't include Firebase credentials. You'll need to connect your own Firebase project.

1. Enable **Authentication** (Email/Password + Google) and **Cloud Firestore** in your Firebase project
2. Run `flutterfire configure` to link the app, or manually add `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
3. Deploy security rules: `firebase deploy --only firestore:rules`
4. Run the app: `flutter run`
