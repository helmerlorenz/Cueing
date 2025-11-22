Firebase migration and onboarding guide
=====================================

This file explains step-by-step how to replace the local, in-memory queue and local auth with Firebase (Firestore + firebase_auth) so the app supports real-time, multi-device queues and an admin app.

High-level steps
----------------
1. Create a Firebase project in the Firebase Console and add Android/iOS apps.
2. Add `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) to the respective platform folders.
3. Add dependencies to `pubspec.yaml` and run `flutter pub get`.
4. Initialize Firebase in `lib/main.dart` (and `lib/admin_main.dart`).
5. Implement `FirestoreQueueService` (replace `QueueService`) and wire it where used.
6. Replace local `AuthService` usage with `firebase_auth` where appropriate (or wrap in an adapter for easier testing).
7. Add Firestore security rules and optional Cloud Functions for admin actions / billing.
8. Test locally using the Firebase Emulator Suite (recommended) before deploying.

Packages to add
---------------
Add these to your `pubspec.yaml` dependencies (versions may vary):

- firebase_core
- cloud_firestore
- firebase_auth
- flutterfire_ui (optional - provides UI helpers)

Initialization (main.dart)
--------------------------
In `lib/main.dart` you must initialize Firebase before using any firebase services. Example:

```
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const BookingApp());
}
```

Also initialize Firebase in `lib/admin_main.dart` (or create a shared initialization helper).

Firestore schema (recommended)
-----------------------------
- Collection `courts` (documents keyed by courtId)
  - name: string
  - createdAt: timestamp

- Subcollection `queue` under each `courts/{courtId}/queue/{entryId}`
  - userId: string
  - username: string
  - joinedAt: timestamp
  - durationMinutes: number
  - status: string ('queued', 'active', 'completed', 'cancelled')

- Collection `admin_games` (or `records`)
  - courtId
  - userId
  - startAt
  - endAt
  - durationMinutes
  - amount

Queue operations (Firestore)
---------------------------
Implement an interface or adapter with these methods (existing `QueueService` is a good reference):

- `Stream<List<QueueEntry>> streamQueue(String courtId)` — listen for real-time queue updates
- `Future<String> joinQueue(String courtId, User user, int durationMinutes)` — create queue doc
- `Future<void> leaveQueue(String courtId, String entryId)` — remove or mark cancelled
- `Future<void> startNext(String courtId)` — atomically set the first queued entry to active
- `Future<int> getPosition(String courtId, String entryId)` — compute position

Important concurrency notes
---------------------------
- Use transactions or server-side Cloud Functions to ensure atomic operations when moving users from queued -> active.
- Consider a `queueOrder` field (server-created) or rely on `joinedAt` timestamps with transactions.

Security rules (starter)
------------------------
Use Firestore security rules to restrict writes:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /courts/{courtId}/queue/{entryId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && request.resource.data.userId == request.auth.uid;
      allow update, delete: if request.auth != null && isAdmin(request.auth.uid);
    }

    match /admin_games/{gameId} {
      allow read: if request.auth != null;
      allow create: if isAdmin(request.auth.uid);
    }
  }

  function isAdmin(uid) {
    // implement admin check (e.g., via custom claims or a separate collection)
    return false;
  }
}
```

Cloud Functions (optional)
--------------------------
- Implement functions to move the next user to `active`, compute billing, and write to `admin_games`.
- Use callable functions if you want the client to trigger admin workflows with proper auth.

Testing locally
----------------
- Install Firebase CLI and start the Emulator Suite (`firebase emulators:start`) and connect the Flutter app to emulator endpoints.
- Use the emulator for Firestore and Auth to test without touching production data.

Migration steps for code
------------------------
1. Add `firebase_core` + `cloud_firestore` + `firebase_auth` to `pubspec.yaml`.
2. Initialize Firebase in `main.dart` and `admin_main.dart`.
3. Create `lib/services/firestore_queue_service.dart` implementing the same methods used by the app.
4. Replace `QueueService()` usage with an injected instance of `FirestoreQueueService` (or wrap in a factory that returns the desired implementation).
5. Replace local `AuthService` usage or wrap it so you can switch implementations for local testing.
6. Add Firestore security rules and deploy/test Cloud Functions.

Notes for the next developer using Copilot
---------------------------------------
- Keep the existing `QueueService` API surface to minimize changes in the UI.
- Create an adapter `IQueueService` interface and implement both `LocalQueueService` and `FirestoreQueueService`. The app code can depend on the interface and receive the implementation via a simple factory or dependency injection.
- Add clear TODO comments in the service files indicating where to replace local logic with Firestore operations; include small snippets of Firestore queries to help Copilot generate code.

If you want, I can scaffold `firestore_queue_service.dart` now (no Firebase project needed) and update the app to use a selectable implementation flag. Reply: "Scaffold Firestore adapter" and I will add the adapter and wiring next.
