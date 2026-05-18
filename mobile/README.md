# Bulao Mobile App
**"bolo, aur kaam ho jaye"**

Bulao is a voice-first service booking Flutter frontend. 
Users simply speak their service requests into the app, and an AI/agentic flow handles the rest. The app visually walks the user through AI agent processing, finding ranked service providers, confirming the booking, tracking the provider en-route, and submitting feedback upon completion. 

Currently, the mobile frontend is structurally complete and relies on centralized mock/demo data. Backend integration with the existing Bulao backend (which features STT, LLM agents, and lifecycle state) is planned as the immediate next step.

## Tech Stack
* **Framework:** Flutter / Dart
* **IDE:** Android Studio / VS Code / Antigravity
* **Typography:** Google Fonts (`ibmPlexSansCondensed`, `inter`)
* **State & Data:** Centralized mock models (backend-ready)
* **Future Backend Integration:** FastAPI / Firebase / Firestore / Cloud Run

## Current Frontend Status
* **Frontend UI:** Complete and demo-ready.
* **Architecture:** Feature-based modular structure with clean separation of widgets and models.
* **Backend-Ready:** Screens are implemented using structured models to allow seamless swap-out of mock data for real API streams.
* **Pending Integration:** Real voice recording (mic), real STT processing, real map rendering, real calendar/WhatsApp intents, and real backend lifecycle updates.

## Completed Screens / Features
* **Splash Screen:** Beautiful, animated entry screen featuring the main Bulao logo.
* **Login Screen:** Clean authentication UI with the Bulao vector wave.
* **Sign Up Screen:** Account creation flow.
* **Forgot Password Screen:** Password recovery UI.
* **Home Screen:** The central hub featuring the voice-recording microphone and quick-action chips.
* **Home Drawer / Sidebar:** Accessible via the hamburger menu, contains navigation for "Live Tracking", "My Bookings", and "Logout".
* **Processing Loading Screen:** An animated waveform UI simulating voice transcription.
* **Processing Agents Screen:** Displays the multi-agent AI pipeline (Intent, Discovery, Ranking, Pricing) analyzing the request in real-time.
* **Provider Selection Screen:** Shows ranked providers ("Best Match") based on the AI's analysis, including price estimates and ratings.
* **Booking Confirmed Screen:** A premium receipt UI confirming the provider dispatch, with hooks for Calendar and WhatsApp.
* **Tracking Screen:** A live tracking interface showing a map preview, provider en-route status, and a vertical lifecycle timeline.
* **Feedback Screen:** A 5-star rating UI with selectable feedback chips ("On Time", "Professional") and a comment box to rate the completed service.

## Demo Flow
The app is currently configured to follow a linear "happy path" demo flow:

**Splash** → **Login** → **Home** → *(Tap & Hold Mic)* → **Processing Loading** → **Processing Agents** → **Provider Selection** → **Confirm Booking** → **Booking Confirmed** → **Track** → **Tracking** → *(Tap 'Mark Completed' Demo)* → **Feedback** → **Send Feedback** → **Home**

*Note: You can also access the Tracking screen via the Home Drawer.*

## Folder Structure
```text
mobile/
├── assets/
│   └── images/                 # App logos, vectors, and reference graphics
├── lib/
│   ├── features/
│   │   ├── auth/               # Login, Signup, Forgot Password
│   │   ├── booking/            # Processing, Agents, Provider Selection, Confirmed Receipt
│   │   ├── feedback/           # Rating and Review UI
│   │   ├── home/               # Main Mic Screen, Drawer
│   │   ├── splash/             # Initial animated splash
│   │   └── tracking/           # Live Map tracking and Timeline
│   └── main.dart               # App entry point
├── pubspec.yaml                # Dependencies and asset declarations
└── README.md                   # This file
```

## Assets Used
The following key assets from `assets/images/` power the app's visual identity:
* `splash_main.png` / `splashLogo.png`
* `login_logo.png` / `signup_logo.png`
* `home_wave.png` / `mic_home.png`
* `provider_logo.png`
* `confirm_book_logo.png`
* `tracking_logo.png`
* `feedback_logo.png`

## Dependencies
This project relies on the following packages (as defined in `pubspec.yaml`):
* `flutter`
* `cupertino_icons` (^1.0.8)
* `google_fonts` (^6.1.0)
* `flutter_native_splash` (^2.4.7) *(dev dependency)*
* `flutter_lints` (^5.0.0) *(dev dependency)*

## Setup Requirements
1. **Flutter SDK** installed and added to PATH.
2. **Dart SDK** (comes bundled with Flutter).
3. **Android Studio** (or VS Code with Flutter extensions).
4. **Android SDK** configured.
5. **Physical Device:** USB debugging enabled (if testing on a real Android phone).
6. **Git** installed.

## How to Clone and Run
Open your terminal and run the following commands:

```bash
git clone https://github.com/muhammadhamad1104/Bulao.git
cd Bulao/mobile
flutter pub get
flutter devices
flutter run
```

If you pull new changes and the app shows an older UI, refresh your build cache:
```bash
flutter clean
flutter pub get
flutter run
```

## Running on Real Android Phone
1. Connect your Android phone to your computer via USB cable.
2. Go to **Settings > Developer Options** on your phone and enable **USB Debugging**.
3. Accept the RSA prompt that appears on your phone screen to allow your computer access.
4. In your terminal, run `flutter devices` to ensure your phone is listed.
5. Run `flutter run`.

## Branch / Git Workflow
All frontend UI work should be committed to the `taha-fayyaz` branch unless the team dictates otherwise.

**If creating the branch for the first time:**
```bash
git checkout -b taha-fayyaz
git status
git add mobile/
git commit -m "Complete Bulao Flutter mobile frontend"
git push origin taha-fayyaz
```

**If the branch already exists:**
```bash
git checkout taha-fayyaz
git pull origin taha-fayyaz
git add mobile/
git commit -m "Update Bulao Flutter mobile frontend"
git push origin taha-fayyaz
```

---

## Backend Integration Pending / Future Work
The UI is structurally complete, but the following areas require backend integration:

### A) Auth
* Replace mock login/signup flows with Firebase Auth or backend custom auth.
* Fetch and store the logged-in user's profile.
* Update the Home greeting (`Hey Wajeeha`) with the actual user's name.

### B) Voice / Home
* Replace the mock mic tap navigation with a real audio recorder plugin (e.g., `record`).
* Capture the user's voice, implement local STT, or send the audio payload to the backend for transcription.

### C) ProcessingLoading
* Show real upload/transcription progress.
* Animate the waveform based on real audio amplitude instead of a loop.

### D) ProcessingScreen
* Replace the hardcoded transcript with the real transcribed text.
* Populate the keyword chips dynamically from the backend's NLP analysis.
* Update the Agent status cards (Intent, Discovery, Ranking, Pricing, Booking) via WebSockets or polling based on real pipeline progress.

### E) ProviderScreen
* Fetch the ranked provider list directly from the backend.
* Make provider names, estimated prices, star ratings, and the expanded "Ranking Factors" dynamic.
* The "Confirm Booking" action should execute a real backend booking/dispatch endpoint.

### F) BookingConfirmed
* The receipt data (Booking ID, time, location, total amount) should come from the successful booking API response.
* Calendar integration should use a device calendar plugin to create an actual event.
* WhatsApp integration should use `url_launcher` to open a real WhatsApp intent.

### G) TrackingScreen
* Replace the static mock `MapPreviewCard` with the `google_maps_flutter` or `mapbox` package.
* Bind the provider's live latitude/longitude to the map pin.
* The timeline states (Booking Confirmed, On his way, In Progress, Completed) should update based on the backend's booking lifecycle status.
* The "Live Tracking" drawer item should fetch active bookings from the backend (and show a fallback message if none exist).

### H) FeedbackScreen
* The temporary "Mark Completed (Demo)" button should be removed.
* The app should automatically push/open the Feedback screen when the backend signals that the `booking.status == "completed"`.
* Submitting the feedback must perform a POST request attaching the `bookingId`, `providerId`, `rating`, `selectedTags`, and `comment`.

## Mock Data Note
To facilitate seamless backend integration, the frontend relies on centralized mock models (e.g., `TrackingModel`, `FeedbackBookingModel`). Mock data is intentionally kept at the Model/Screen level rather than deeply hardcoded inside individual widget layouts. When the APIs are ready, you only need to swap the `TrackingModel.mockData` assignment with real JSON deserialization.

## Known Limitations
* No real backend API connection yet.
* No authentication persistence yet.
* No real hardware microphone recording yet.
* No real Google Maps SDK integrated yet.
* Calendar / WhatsApp intents trigger mock SnackBars.
* Feedback submission only resets the navigation stack locally.

## Troubleshooting
* **`flutter command not found`**: Ensure the Flutter SDK `bin` folder is added to your system's PATH variables.
* **`no devices found`**: Ensure your Android phone is plugged in, unlocked, and USB Debugging is authorized.
* **Gradle / Build Issues or Old UI**: Run `flutter clean`, then `flutter pub get`, then `flutter run`.
* **Assets not loading**: Ensure the filename casing in `pubspec.yaml` and your Dart code exactly matches the actual file on disk.

## Contribution Notes
* **Frontend Scope:** Keep all Flutter work constrained to the `mobile/` directory.
* **Backend Scope:** Do not modify the `backend/` or `data/` directories without team approval.
* **Architecture:** Adhere to the feature-based folder structure inside `lib/features/`.
* **Reusability:** Keep UI widgets small, reusable, and driven by state/models.

***
*This mobile frontend was designed and implemented by the mobile frontend team for the Bulao hackathon demo.*
