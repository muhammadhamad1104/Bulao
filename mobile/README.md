# Bulao Mobile App
> “bolo, aur kaam ho jaye”

## Project Description
Bulao is a Flutter-based mobile frontend for a voice-first service booking application designed specifically for Pakistan’s informal economy. The application emphasizes ease of use, leveraging speech-to-text to orchestrate complex booking flows with simple voice commands.

## Current Status
- **Frontend UI complete**: All core screens have been built following a premium design system (cream, navy, gold).
- **Firebase Auth integrated**: Firebase Authentication (Email/Password) is successfully wired up.
- **Mock Data**: Currently, booking flows, providers, tracking, and feedback screens use mock/demo data for UI demonstration.
- **Backend pending**: The FastAPI backend is set up but not yet integrated with the Flutter frontend. 

## Tech Stack
- **Flutter** & **Dart**
- **Firebase Core** & **Firebase Auth**
- **Google Fonts** (`google_fonts`)
- **Cupertino Icons** (`cupertino_icons`)
- **Flutter Native Splash** (`flutter_native_splash`)
- *(Planned)* Existing Python FastAPI backend for AI orchestration.

## Firebase Setup Status
The app is fully configured for Firebase:
- **Firebase Project ID**: `bulao-hackathon`
- **Android Package**: `com.example.mobile`
- **Authentication**: Email/Password provider is enabled.
- Configuration files (`firebase_options.dart` and `google-services.json`) are already included in the repository.

**Important for Teammates**: 
If you clone this repository, you **can run the app immediately** without creating a new Firebase project. Firebase Auth will work out-of-the-box. You only need access to the Firebase Console if you wish to manage users, security rules, or project settings.

### Safe/Required Files (Committed)
These files are already in the repository and are required for Firebase to work:
- `lib/firebase_options.dart`
- `android/app/google-services.json`

### DO NOT COMMIT
Please ensure the following are never committed to version control:
- `.firebase/` directory
- `serviceAccountKey.json`
- `.env` files
- Backend secrets or Firebase Admin private keys.

## Setup Requirements
To run this project, ensure you have:
- Flutter SDK installed (Dart comes with Flutter)
- Android Studio / Android SDK
- Git
- A real Android device (with USB debugging enabled) or an Android Emulator

## Clone and Run
Run the following commands to clone the repository and start the app:

```bash
git clone https://github.com/muhammadhamad1104/Bulao.git
cd Bulao
git checkout taha-fayyaz
cd mobile
flutter pub get
flutter devices
flutter run
```

If you encounter issues, try a clean rebuild:
```bash
flutter clean
flutter pub get
flutter run
```

## Firebase Auth Testing
You can test the real Firebase Auth flow immediately:
1. Open the app. It will route you to the **Login Screen**.
2. Tap "Sign Up Now!". Enter a name, email, and password (>6 characters).
3. The app will create a Firebase user, log you out, and return you to the Login Screen.
4. Log in with your new credentials. You will be routed to the **Home Screen**.
5. Test "Forgot Password" to receive a real password reset link via email.
6. Open the sidebar drawer and tap **Logout** to return to the Login Screen.
*(New users can be verified in the Authentication -> Users tab of the Firebase Console).*

## Completed Screens & Features
- **Splash Screen**: Custom native and Flutter splash loading.
- **AuthGate**: Automatically routes users based on active Firebase Auth state.
- **Login Screen**: Authenticates existing users with Firebase.
- **Sign Up Screen**: Creates new Firebase users and updates their display name.
- **Forgot Password Screen**: Sends a Firebase password reset email.
- **Home Screen**: Features a central mic button and greets the user using their Firebase display name.
- **Home Drawer**: Sidebar for navigation (Live Tracking) and Logout.
- **Processing Loading Screen**: Audio waveform animation while waiting for backend orchestration.
- **Processing Agents Screen**: Visual representation of AI agents parsing the request.
- **Provider Screen**: Displays a ranked list of available service providers (mock data).
- **Booking Confirmed Screen**: Beautiful confirmation receipt.
- **Tracking Screen**: Mock interactive map interface for live tracking.
- **Feedback Screen**: Star rating and review submission UI.

## Folder Structure
```text
mobile/
├── android/            # Android native project files
├── assets/
│   └── images/         # App logos, icons, and illustrations
├── lib/
│   ├── core/           # Core utilities and shared widgets (e.g. bulao_toast.dart, firebase_error_helper.dart)
│   ├── features/
│   │   ├── auth/       # Login, Signup, Forgot Password, AuthGate
│   │   ├── booking/    # Processing, Provider Selection, Confirmed Booking
│   │   ├── feedback/   # Rating and Review screens
│   │   ├── home/       # Home screen and Drawer
│   │   ├── splash/     # Custom Splash screen
│   │   └── tracking/   # Live Map Tracking screen
│   ├── firebase_options.dart # Firebase initialization config
│   └── main.dart       # App entry point
├── test/               # Unit and widget tests
├── pubspec.yaml        # Flutter dependencies
└── README.md           # This documentation
```

## Important Assets
The `mobile/assets/images/` directory contains critical design assets:
- `splashLogo.png`, `splash_main.png`
- `login_logo.png`, `signup_logo.png`, `auth_vector.png`
- `home_wave.png`, `mic_home.png`
- `provider_logo.png`
- `confirm_book_logo.png`
- `tracking_logo.png`
- `feedback_logo.png`

## Backend Integration Pending
The FastAPI backend (`backend/app/routers/`) is structured to handle core flows. The following integrations are pending:

1. **`POST /orchestrate`**: Will replace the current Processing and Provider Selection mock flows. It will take STT text and return available providers.
2. **`POST /book`**: Will replace the Confirm Booking mock action to create a real booking in Firestore.
3. **`GET /lifecycle`**: Will replace the mock Tracking timeline with real-time status updates.
4. **`POST /rating`**: Will replace the Feedback screen mock submission.

### Frontend-to-Backend Work to be Done
- Implement an HTTP/API client service in Flutter (using `http` or `dio`).
- Configure a base URL and environment variables.
- Pass the Firebase user UID (and potentially an ID token in the `Authorization` header) to the backend.
- Map FastAPI response JSON to Dart models.
- Swap out hardcoded mock UI lists with real asynchronous backend data.

### Screen-by-Screen Integration Details
- **Auth**: Fully connected to Firebase. User profiles may later sync to Firestore via the backend.
- **Home**: Real Speech-to-Text (STT) integration needed. Currently, tapping the mic starts a demo flow.
- **Processing Loading**: Needs to display real STT progress or audio waveform rendering.
- **Processing Agents**: Needs to dynamically display the transcript and detected intent/keywords from the backend.
- **Provider Screen**: Needs to render the real list of ranked providers and pricing returned by `/orchestrate`.
- **Booking Confirmed**: Needs to show real receipt data from the `/book` response. Calendar and WhatsApp actions are currently placeholders.
- **Tracking Screen**: Needs real Google Maps or Mapbox integration and live Firestore listeners for lifecycle changes.
- **Feedback Screen**: Needs to be triggered dynamically when a booking lifecycle status turns to "completed".

## Known Limitations
- The backend is not yet connected to the Flutter app.
- Real voice recording and transcription (STT) are not active.
- Real maps and location services are not yet integrated.
- WhatsApp and Calendar actions are UI placeholders.
- The Tracking and Feedback screens currently operate on a static mock flow.

## Git Branch Workflow
This frontend work is actively being maintained on the `taha-fayyaz` branch.

To push changes to this branch:
```bash
git status
git checkout taha-fayyaz
git add mobile/
git commit -m "Update mobile README after Firebase auth integration"
git push origin taha-fayyaz
```

## Contribution Notes
- **Frontend Changes**: All Flutter work should remain inside the `mobile/` directory.
- **Backend/Data Changes**: Do not modify `backend/` or `data/` directories unless explicitly assigned.
- **Code Quality**: Keep widgets modular and reusable. Retain centralized mock data until real endpoints are wired. Keep Dart models backend-ready to match FastAPI schemas.
