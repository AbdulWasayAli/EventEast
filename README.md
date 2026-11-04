# EventEast — Comprehensive Event Management System

> A modern, full-featured event management mobile application built with **Flutter** and **Firebase**, supporting three distinct user roles: **Attendees**, **Organizers**, and **Platform Administrators**.

---

## 📱 App Overview

**EventEast** provides a complete end-to-end event lifecycle experience:
- Attendees discover, register, and attend events with QR passes.
- Organizers create, manage, and monitor their events in real time.
- Admins oversee the entire platform — users, content, and approvals.

---

## 👥 User Roles & Features

### 1. 🎟️ Attendee (General User)
- **Onboarding**: Smooth onboarding screens on first install.
- **Home Dashboard**: Browse upcoming, trending, and nearby events with banners and category filters.
- **Search & Filter**: Filter events by category, date range, location, and keywords.
- **Event Details**: Full event view — description, agenda, pricing, capacity, organizer info.
- **Interactive Map**: View exact venue location on OpenStreetMap (`flutter_map`).
- **Register & QR Pass**: Instant QR pass generation (`qr_flutter`) stored in Firestore.
- **My Events**: Track registered, upcoming, and past events.
- **Favorites**: Bookmark events to a personal wishlist.
- **Certificate**: Download/preview attendance certificate (PDF via `pdf` & `printing`).
- **Gallery**: Browse event highlight photos uploaded by organizers.
- **Feedback & Rating**: Submit multi-star reviews and comments (`flutter_rating_bar`).
- **Notifications**: Receive push & local alerts for event updates.

---

### 2. 🎪 Organizer
- **Organizer Dashboard**: Real-time stats — total events, registrations, attendance, check-ins.
- **Create & Edit Events**: Set title, description, category, datetime, capacity, and banner image.
- **Location Picker**: Drop a pin on interactive map to set exact GPS coordinates.
- **Participants Roster**: View and search registered attendees and their status.
- **QR Attendance Scanner**: Scan attendee QR passes for real-time check-in (`mobile_scanner`).
- **Broadcast Announcements**: Send instant push notifications to all registered attendees.
- **Gallery Upload**: Upload post-event photos for attendees to browse.
- **Feedback Review**: View attendee ratings and comments on your events.

---

### 3. 🛡️ Platform Administrator
- **Admin Dashboard**: Platform-wide metrics — user count, organizer approvals, total events.
- **User & Role Management**: View, activate, suspend, or update user permissions.
- **Event Moderation**: Edit or remove events that violate platform guidelines.
- **Organizer Approvals**: Review and approve/reject organizer verification requests.
- **Content Moderation**: Inspect flagged gallery uploads, reviews, or comments.
- **Reports & Escalations**: Resolve user complaints and policy violation reports.

---

## 📂 Project Folder Structure

```text
EventEast/
├── android/                        # Native Android build configs & manifests
├── ios/                            # Native iOS build configs & plists
├── assets/
│   ├── images/
│   │   └── logo.jpg                # App logo used for launcher icon
│   └── service-account.json        # Firebase admin service account (FCM notifications)
│
├── lib/
│   ├── main.dart                   # App entry point — Firebase init, MultiProvider, MaterialApp
│   ├── firebase_options.dart       # Auto-generated Firebase multi-platform configuration
│   │
│   ├── models/                     # Data models with JSON serialization
│   │   ├── event_model.dart        # Event entity & metadata
│   │   ├── user_model.dart         # User profile & role definitions
│   │   ├── registration_model.dart # Registration records & QR payload
│   │   └── notification_model.dart # In-app & push notification schema
│   │
│   ├── providers/                  # State management (Provider pattern)
│   │   ├── auth_provider.dart      # Auth state, login/logout, role resolution
│   │   ├── event_provider.dart     # Event listings, search, filtering & creation
│   │   ├── admin_provider.dart     # Admin stats, user & approval states
│   │   └── theme_provider.dart     # Dark/Light mode toggle & persistence
│   │
│   ├── screens/
│   │   ├── auth/                   # Authentication & onboarding flow
│   │   │   ├── splash_screen.dart          # Animated splash → role-based routing
│   │   │   ├── onboarding_screen.dart      # First-launch onboarding slides
│   │   │   ├── login_screen.dart           # Email/password & Google Sign-In
│   │   │   └── register_screen.dart        # New account registration with role selection
│   │   │
│   │   ├── attendee/               # Attendee-facing screens
│   │   │   ├── home_dashboard_screen.dart          # Home feed with banners & categories
│   │   │   ├── discover_events_screen.dart         # Full event listing with filters
│   │   │   ├── search_filter_screen.dart           # Advanced search & filtering
│   │   │   ├── event_details_screen.dart           # Event detail view
│   │   │   ├── registration_confirmation_screen.dart # Registration success & QR
│   │   │   ├── qr_pass_screen.dart                 # QR code pass display
│   │   │   ├── my_events_screen.dart               # Registered & past events
│   │   │   ├── favorites_screen.dart               # Bookmarked events
│   │   │   ├── gallery_view_screen.dart            # Event photo gallery
│   │   │   ├── feedback_screen.dart                # Rate & review an event
│   │   │   └── certificate_preview_screen.dart     # Attendance certificate PDF preview
│   │   │
│   │   ├── organizer/              # Organizer-facing screens
│   │   │   ├── organizer_dashboard_screen.dart     # Analytics & stats dashboard
│   │   │   ├── create_edit_event_screen.dart       # Create / edit event form
│   │   │   ├── participants_screen.dart            # Registered attendees list
│   │   │   ├── attendance_scanner_screen.dart      # Live QR scanner for check-in
│   │   │   ├── announcements_screen.dart           # Broadcast push notifications
│   │   │   ├── gallery_upload_screen.dart          # Upload post-event photos
│   │   │   └── organizer_feedback_screen.dart      # View attendee ratings & reviews
│   │   │
│   │   ├── admin/                  # Admin-facing screens
│   │   │   ├── admin_dashboard_screen.dart         # Platform-wide metrics command center
│   │   │   ├── manage_users_screen.dart            # User role & status management
│   │   │   ├── manage_events_screen.dart           # Event moderation panel
│   │   │   ├── approvals_screen.dart               # Organizer approval requests
│   │   │   ├── content_moderation_screen.dart      # Flagged content review
│   │   │   └── reports_screen.dart                 # User complaints & escalations
│   │   │
│   │   ├── common/                 # Shared screens for all roles
│   │   │   ├── profile_screen.dart                 # User profile view & edit
│   │   │   ├── settings_screen.dart                # App settings (theme, account)
│   │   │   └── notifications_screen.dart           # In-app notification history
│   │   │
│   │   ├── shared/                 # Cross-role utility screens
│   │   │   ├── event_map_screen.dart               # OpenStreetMap event venue viewer
│   │   │   └── location_picker_screen.dart         # Interactive pin-drop location picker
│   │   │
│   │   ├── about_us_screen.dart    # About the app & team
│   │   └── contact_us_screen.dart  # Contact form & support info
│   │
│   ├── services/                   # Backend & infrastructure services
│   │   ├── auth_service.dart               # Firebase Auth helper methods
│   │   ├── notification_service.dart       # FCM & local notification setup
│   │   ├── image_upload_service.dart       # Cloudinary image upload handling
│   │   ├── certificate_service.dart        # PDF certificate generation logic
│   │   ├── pdf_report_service.dart         # PDF report generation for organizers
│   │   └── page_transitions.dart           # Custom animated route transitions
│   │
│   ├── theme/
│   │   └── app_theme.dart          # Light & dark theme definitions (Material 3)
│   │
│   └── widgets/
│       ├── premium_ui.dart         # Reusable premium UI components & cards
│       └── network_aware_wrapper.dart  # Connectivity-aware wrapper widget
│
├── pubspec.yaml                    # Project dependencies and asset registry
└── README.md
```

---

## ⚙️ Tech Stack & Key Libraries

| Category | Technology |
|---|---|
| **Framework** | Flutter (Material 3) |
| **Backend** | Firebase Authentication, Cloud Firestore, Cloud Storage |
| **Push Notifications** | Firebase Cloud Messaging (FCM) + `flutter_local_notifications` |
| **State Management** | `provider: ^6.1.5` |
| **Maps** | `flutter_map: ^7.0.2` (OpenStreetMap) + `latlong2` + `geolocator` |
| **Image Hosting** | Cloudinary via `ImageUploadService` |
| **QR Code** | `qr_flutter` (generation) + `mobile_scanner` (camera scan check-in) |
| **PDF / Certificates** | `pdf: ^3.10.4` + `printing: ^5.11.1` |
| **Google Sign-In** | `google_sign_in: 6.2.1` |
| **Image Picker** | `image_picker: ^1.1.2` + `cached_network_image` |
| **Ratings** | `flutter_rating_bar: ^4.0.1` |
| **Connectivity** | `connectivity_plus: ^6.0.5` |
| **Sharing** | `share_plus: ^13.3.0` |
| **Persistence** | `shared_preferences: ^2.3.2` |
| **Networking** | `http: ^1.6.0` + `googleapis_auth: ^2.3.3` |

---

## 🚀 How to Run (Step-by-Step)

### Prerequisites
- **Flutter SDK**: `^3.11.4` — verify with `flutter --version`
- **Android Studio / VS Code** with Flutter & Dart plugins
- **Connected Device** or Emulator/Simulator

### Setup

```bash
# 1. Clone the repository
git clone https://github.com/AbdulWasayAli/EventEast.git
cd EventEast

# 2. Install dependencies
flutter pub get

# 3. Verify Firebase config files are present:
#    android/app/google-services.json
#    lib/firebase_options.dart
#    assets/service-account.json

# 4. Check connected devices
flutter devices

# 5. Run the app
flutter run

# 6. Build release APK
flutter build apk --release
```

---

## 🔥 Firebase Services Used

| Service | Purpose |
|---|---|
| **Firebase Auth** | Email/password login, Google Sign-In, role-based session management |
| **Cloud Firestore** | Events, users, registrations, notifications, feedback, gallery data |
| **Cloud Storage** | Event banner images & gallery photo uploads |
| **Firebase Cloud Messaging** | Push notifications for event updates & announcements |

---

## 🗺️ Map Feature

EventEast uses **OpenStreetMap** (free, no billing key required):
- **`LocationPickerScreen`** — Organizers drop a pin to set event GPS coordinates.
- **`EventMapScreen`** — Attendees view the venue on a map and open navigation apps via `url_launcher`.

---

## 📸 App Screens Summary

| Screen | Role | Description |
|---|---|---|
| Splash Screen | All | Animated intro → auto-routes by login state & role |
| Onboarding | Guest | 4-slide first-launch introduction (shown once) |
| Login / Register | Guest | Email + Google Sign-In with role selection |
| Home Dashboard | Attendee | Event feed, banners, categories |
| Event Details | Attendee | Full event info with map & registration |
| QR Pass | Attendee | Digital QR pass for event check-in |
| My Events | Attendee | Registered & past events tracker |
| Certificate | Attendee | PDF attendance certificate download |
| Organizer Dashboard | Organizer | Analytics — events, registrations, check-ins |
| Create/Edit Event | Organizer | Full event creation form with map pin |
| QR Scanner | Organizer | Live camera QR scan for attendee check-in |
| Admin Dashboard | Admin | Platform-wide stats & control panel |
| Manage Users | Admin | User role & status management |
| Approvals | Admin | Organizer verification request review |

---

## 👨‍💻 Developer

**Abdul Wasay Ali**
GitHub: [@AbdulWasayAli](https://github.com/AbdulWasayAli)
