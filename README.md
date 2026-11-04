# EventEase - Comprehensive Event Management System

EventEase is a modern, full-featured event management mobile application built using **Flutter** and **Firebase**. It provides an end-to-end event lifecycle experience catering to three primary user roles: **Attendees**, **Organizers**, and **Platform Administrators**.

---

## 👥 User Roles & Detailed Responsibilities

### 1. 🎟️ Attendee (General User)
Designed for participants seeking to explore, register, attend, and review events.
- **Home & Discover Feed**: Browse upcoming, trending, and nearby events with categorization and banners.
- **Search & Advanced Filtering**: Filter events by category, date range, location, and keywords.
- **Interactive Event Details**: Comprehensive view of event agenda, description, pricing, capacity, and organizer details.
- **Interactive Venue Map**: View exact event location on an OpenStreetMap interface powered by `flutter_map`.
- **Registration & Instant QR Pass**: Register for events and receive a dynamic QR code pass (`qr_flutter`) stored locally and in Cloud Firestore.
- **Favorites & Bookmarks**: Save events to a personal wishlist for quick access.
- **My Events Tracking**: Dedicated dashboard tab displaying registered, past, and upcoming events.
- **Certificate Generation & Preview**: Download or preview participation/attendance certificates (`pdf` & `printing`).
- **Feedback & Rating**: Rate attended events with multi-star reviews and comments (`flutter_rating_bar`).
- **Event Gallery**: View event highlights and photos uploaded by organizers.

---

### 2. 🎪 Organizer
Designed for event creators, hosts, and coordinators.
- **Organizer Analytics Dashboard**: Real-time stats on total registrations, active events, attendee engagement, and revenue/check-ins.
- **Create & Edit Events**:
  - Set title, description, category, datetime, and capacity.
  - Upload event banner/images to Cloudinary CDN (`ImageUploadService`).
  - **Location Picker**: Interactive map to drop a pin and set exact GPS coordinates (`LocationPickerScreen`).
- **Participant Roster Management**: View attendee lists, search registered participants, and view their registration status.
- **Live Attendance QR Scanner**: Scan attendee QR passes at the entrance using the camera scanner (`mobile_scanner`) for real-time check-in validation.
- **Broadcast Announcements**: Send instant push notifications and updates to registered attendees (`firebase_messaging` & Google APIs auth).
- **Gallery Upload**: Upload post-event images to share with attendees.
- **Feedback Review**: Inspect ratings and constructive feedback submitted by attendees.

---

### 3. 🛡️ Platform Administrator
Designed for platform owners and moderators to ensure platform safety and quality.
- **Admin Command Center**: Platform-wide metrics including user count, organizer approvals, total events, and reports.
- **User & Role Management**: View, activate, suspend, or update permissions of users and organizers.
- **Event Moderation & Management**: Edit or take down events that violate platform guidelines.
- **Organizer Approvals**: Review verification requests from users applying to become organizers.
- **Content & Media Moderation**: Inspect flagged gallery uploads, reviews, or comments.
- **Reports & Escalations**: Resolve user complaints and reported policy infractions.

---

## 🗺️ Map Feature Architecture

EventEase integrates modern map visualization without requiring expensive Google Maps billing keys by leveraging **OpenStreetMap**:
1. **Packages Used**:
   - `flutter_map`: Leaflet-style tile rendering for OpenStreetMap.
   - `latlong2`: Geospatial latitude/longitude coordinates manipulation.
   - `geolocator`: Device GPS location fetching and distance calculations.
2. **Location Picker (`LocationPickerScreen`)**:
   - Used by organizers during event creation.
   - Organizers can tap or drag a pin on the map to accurately pinpoint the venue address and GPS coordinates (`latitude`, `longitude`).
3. **Event Map Viewer (`EventMapScreen`)**:
   - Embedded or accessible directly from the event details screen.
   - Attendees can inspect venue placement, view surrounding landmarks, and open navigation apps via `url_launcher`.

---

## 📂 Project Folder Structure

The project follows a clean separation of concerns:

```text
EventEase/
├── android/                 # Native Android build configs & manifests
├── ios/                     # Native iOS build configs & plist
├── assets/                  # Static assets (images, icons, service credentials)
│   ├── images/              # App banners, logos, and placeholders
│   └── service-account.json # Firebase admin service account configuration
├── lib/                     # Core Dart/Flutter application code
│   ├── main.dart            # App entry point, MultiProvider setup, Firebase initialization
│   ├── firebase_options.dart# Auto-generated Firebase multi-platform configs
│   │
│   ├── models/              # Data models with JSON serialization
│   │   ├── event_model.dart         # Event entity & metadata
│   │   ├── user_model.dart          # User profile & role definitions
│   │   ├── registration_model.dart  # Event registration records & QR payload
│   │   └── notification_model.dart  # In-app and push notification schema
│   │
│   ├── providers/           # State management (Provider pattern)
│   │   ├── event_provider.dart      # Event listings, search, filtering & creation
│   │   ├── admin_provider.dart      # Admin statistics, user and approval states
│   │   └── ...                      # Additional state handlers
│   │
│   ├── screens/             # Presentation layer grouped by role & domain
│   │   ├── admin/           # Admin Dashboard, User Management, Reports, Approvals
│   │   ├── attendee/        # Event Discovery, Details, QR Pass, Feedback, Favorites
│   │   ├── organizer/       # Event Creation/Editing, QR Attendance Scanner, Participants
│   │   ├── auth/            # Login, Signup, Role onboarding, Password recovery
│   │   ├── common/          # Profile management, Settings
│   │   └── shared/          # Shared features (LocationPickerScreen, EventMapScreen)
│   │
│   ├── services/            # Background & Infrastructure Services
│   │   ├── image_upload_service.dart # Cloudinary image upload handling
│   │   ├── notification_service.dart # Firebase Cloud Messaging & local alerts
│   │   └── ...                       # Auth & Firestore helper services
│   │
│   ├── theme/               # Colors, typography, custom themes, dark/light styling
│   └── widgets/             # Reusable UI components (buttons, cards, banners, loaders)
│
└── pubspec.yaml             # Project dependencies and asset registry
```

---

## 🚀 How to Run the Project (Step-by-Step)

### 1. Prerequisites
- **Flutter SDK**: Version 3.11.4 or newer (`flutter --version`)
- **Android Studio / Xcode**: Configured with Android SDK / iOS toolchain
- **Device / Emulator**: Connected Android device/emulator or iOS Simulator

### 2. Setup Steps

1. **Open the Project Directory**:
   ```bash
   cd EventEase
   ```

2. **Install Flutter Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Firebase Configuration**:
   - Ensure `firebase_options.dart` exists in `lib/`.
   - For Android, verify `android/app/google-services.json` is present.
   - For iOS, verify `ios/Runner/GoogleService-Info.plist` is present.
   - If setting up a fresh project, run:
     ```bash
     flutterfire configure
     ```

4. **Verify Connected Devices**:
   ```bash
   flutter devices
   ```

5. **Run the Application**:
   ```bash
   flutter run
   ```

---

## ⚙️ Key Technical Stack & Libraries
- **Frontend**: Flutter (Material 3 with custom premium widgets)
- **Backend**: Firebase Authentication, Cloud Firestore, Cloud Storage, Firebase Cloud Messaging
- **State Management**: Provider (`provider: ^6.1.5`)
- **Maps**: `flutter_map: ^7.0.2` (OpenStreetMap), `latlong2`, `geolocator`
- **Image Hosting**: Cloudinary via `ImageUploadService`
- **QR Code Engine**: `qr_flutter` (Pass generation) & `mobile_scanner` (Live camera check-in)
- **Document Generation**: `pdf` and `printing` for certificates
