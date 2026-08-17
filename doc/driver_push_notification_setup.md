# Yjeek Champ (driver) — push notification setup

Short: **in-app notification list already works.** Phone tray (FCM) **does not**. Same gap the customer app had before FCM + local notifications.

This file is the checklist: backend APIs (current + new), Firebase, Flutter wiring, and how to test.

Mirror the customer app (`yjeek_app`) FCM pattern. Do **not** call `POST /users/me/devices` from the driver JWT — that route is `CUSTOMER` only.

---

## 0. Current status

| Layer | Status |
|---|---|
| In-app inbox UI (`NotificationsScreen`) | Done |
| Inbox APIs (`GET/PATCH /drivers/notifications…`) | Done |
| Unread badge on home (`unreadNotificationsCount`) | Done |
| `DriverNotification` rows on job offer / suspend / admin notify | Done (inbox + FCM) |
| Driver FCM token storage | Done (`DriverProfile.devices`) |
| Backend FCM send when a driver row is created | Done (`persistDriverNotification`) |
| Flutter `firebase_messaging` / `flutter_local_notifications` | Done |
| `google-services.json` / `GoogleService-Info.plist` | Done (`bh.yjeek.driver`) |
| Android `POST_NOTIFICATIONS` + default FCM channel | Done |

Customer FCM on this backend already uses Firebase Admin (`initCustomerPush`). Driver can reuse the **same** Admin SDK / same Firebase project. Driver app must be a **second Android/iOS app** in that project (`bh.yjeek.driver`).

---

## 1. Firebase console (once)

Use the **same Firebase project** as the customer app (already sending FCM).

1. Firebase Console → Project → **Add app**
   - Android package name: `bh.yjeek.driver`
   - iOS bundle ID: `bh.yjeek.driver`
2. Download:
   - `google-services.json` → `yjeek_driver/android/app/`
   - `GoogleService-Info.plist` → `yjeek_driver/ios/Runner/`
3. Android: apply Google services Gradle plugin (same as `yjeek_app`).
4. iOS: enable **Push Notifications** + **Background Modes → Remote notifications**. Add `aps-environment` entitlements.
5. iOS delivery also needs an **APNs key** uploaded in Firebase → Project settings → Cloud Messaging.

No extra backend service-account is required if the driver app is in the same Firebase project. Admin SDK already loads via:

```
FIREBASE_PROJECT_ID=
FIREBASE_SERVICE_ACCOUNT_PATH=secrets/firebase-service-account.json
# or FIREBASE_SERVICE_ACCOUNT_JSON= / FIREBASE_CLIENT_EMAIL + FIREBASE_PRIVATE_KEY
```

Production AWS still needs those env vars + PM2 restart. Local laptop already has them for customer push.

---

## 2. Backend work

### 2.1 Store driver device tokens

Add `DriverProfile.devices Json?` (same shape as customer):

```json
[
  {
    "token": "<fcm-token>",
    "platform": "android",
    "provider": "FCM",
    "registeredAt": "2026-08-16T12:00:00.000Z"
  }
]
```

Keep last ~20 tokens. Drop tokens on FCM errors `messaging/registration-token-not-registered` and `messaging/invalid-registration-token`. Reuse `src/modules/notifications/fcm-tokens.ts`.

### 2.2 New driver device APIs

Auth: `Authorization: Bearer <driver JWT>` (`role = DRIVER`).

Do **not** reuse `/users/me/devices` (`authorize('CUSTOMER')`).

#### `POST /api/v1/drivers/devices`

Register / refresh FCM token after login and on `onTokenRefresh`.

```http
POST /api/v1/drivers/devices
Authorization: Bearer <driver_jwt>
Content-Type: application/json

{
  "token": "fcm-device-token…",
  "platform": "android",
  "provider": "FCM"
}
```

`platform`: `android` | `ios` | `web`  
`provider`: `FCM` (default) | `APNS` | `OTHER`

Example success:

```json
{
  "success": true,
  "data": {
    "registered": true,
    "providerStatus": "CONFIGURED",
    "message": "Device token stored — FCM push is enabled",
    "device": {
      "token": "fcm-device-token…",
      "platform": "android",
      "provider": "FCM",
      "registeredAt": "2026-08-16T12:00:00.000Z"
    },
    "count": 1
  }
}
```

`providerStatus`: `CONFIGURED` if Admin SDK is live, else `TBD`.

#### `DELETE /api/v1/drivers/devices/:token`

Call on logout.

### 2.3 Send FCM whenever a driver inbox row is created

Customer already does this via `persistCustomerNotification`. Copy that:

- `src/modules/notifications/driver-notify.ts` → `persistDriverNotification` / `persistDriverNotifications`
- `src/modules/notifications/driver-push.service.ts` → load tokens from `driver.devices`, then `sendEachForMulticast`

Replace raw `prisma.driverNotification.create` / `createMany` at:

| File | Typical event |
|---|---|
| `src/modules/dispatch/dispatch.service.ts` | New job offer / route update |
| `src/jobs/scheduled-dispatch.job.ts` | Confirm scheduled pickup |
| `src/jobs/champ-suspension.job.ts` | Suspension lifted |
| `src/jobs/champ-termination.job.ts` | Account terminated |
| `src/modules/admin-panel/fleet/admin-fleet.service.ts` | Suspend / bulk champ notify |
| `src/modules/admin-panel/orders/admin-orders.service.ts` | Live-dashboard champ notify |

**FCM payload (Android):** send **data-only** (no top-level `notification`). The Flutter app draws the tray with `flutter_local_notifications`. A top-level FCM `notification` is silent while the app is open, and a missing Android icon can drop the tray on cheap phones.

```json
{
  "data": {
    "title": "New delivery request",
    "body": "Pickup at The Green Kitchen · Adliya",
    "type": "ORDER_OFFER",
    "screen": "job",
    "jobId": "…",
    "orderId": "…",
    "notificationId": "…"
  },
  "android": { "priority": "high" }
}
```

iOS: also set APNs `aps.alert` + sound.

Recommended channels in the app:

- `yjeek_driver_jobs` — job offers (sound, high)
- `yjeek_driver_default` — account / performance / marketing

Log: `[fcm] sent driver=<id> ok=1 fail=0` and `[fcm] skip no-tokens driver=<id>`.

### 2.4 Optional but useful

`GET /api/v1/drivers/notifications/unread-count` → `{ "count": 2 }`  
Home already returns `unreadNotificationsCount`; a dedicated endpoint makes the badge cheaper to refresh.

---

## 3. Existing inbox APIs (already live)

Base: `{APP}/api/v1`  
Auth: driver JWT on every call.

Driver app constants (`lib/core/constants/api_endpoints.dart`):

| App constant | HTTP |
|---|---|
| `ApiEndpoints.notifications` | `GET /drivers/notifications` |
| `ApiEndpoints.notificationsReadAll` | `PATCH /drivers/notifications/read-all` |
| `ApiEndpoints.notificationRead(id)` | `PATCH /drivers/notifications/:id/read` |
| `ApiEndpoints.home` | `GET /drivers/home` → `unreadNotificationsCount` |

### `GET /api/v1/drivers/notifications?limit=50`

```json
{
  "success": true,
  "data": {
    "today": [
      {
        "id": "clx…",
        "driverId": "clx…",
        "type": "ORDER_OFFER",
        "title": "New delivery request",
        "body": "Pickup at The Green Kitchen · Adliya",
        "metadata": {
          "orderId": "…",
          "jobId": "…",
          "driverEarnings": 1.2
        },
        "isRead": false,
        "expiresAt": "2026-08-16T13:20:00.000Z",
        "createdAt": "2026-08-16T13:15:00.000Z"
      }
    ],
    "earlier": [],
    "unreadCount": 1
  }
}
```

`unreadCount` in this payload is **only among the `limit` rows**, not a full DB count. Prefer `GET /drivers/home` → `unreadNotificationsCount` for the badge until a dedicated count API exists.

### `PATCH /api/v1/drivers/notifications/:id/read`

Marks one row read. Returns the updated notification.

### `PATCH /api/v1/drivers/notifications/read-all`

```json
{ "success": true, "data": { "message": "All notifications marked as read" } }
```

### `GET /api/v1/drivers/home`

Includes `unreadNotificationsCount` (real DB count of unread rows).

---

## 4. Notification types (backend enum)

`DriverNotificationType`:

| Type | When it is created |
|---|---|
| `ORDER_OFFER` | Dispatch offers a job / updates a stacked route |
| `ORDER_CONFIRMATION` | Scheduled pickup confirmation reminder |
| `ACCOUNT_SUSPENDED` | Admin suspends champ (`notifyChamp`) |
| `APP_UPDATE` | Used today for “suspension lifted” (and similar) |
| `PERFORMANCE_ALERT` | Reserved / admin campaigns |
| `DOCUMENT_EXPIRING` | Reserved / admin campaigns |
| `INCIDENT_RESOLVED` | Reserved / admin |
| `SHIFT_REMINDER` | Reserved / admin |

Tap routing in the driver app:

| `type` | Open |
|---|---|
| `ORDER_OFFER` / `ORDER_CONFIRMATION` | Active job / offer (`metadata.jobId` or `orderId`) |
| `ACCOUNT_SUSPENDED` | Account / status |
| others | Notifications screen |

---

## 5. Flutter driver app work

`PushNotificationService` in `lib/services/push_notification_service.dart` is a no-op. Replace it using the customer app as the template:

`yjeek_app/lib/features/notifications/service/push_notification_service.dart`

### Packages

```yaml
firebase_core: …
firebase_messaging: …
flutter_local_notifications: …
```

### Startup

1. `Firebase.initializeApp`
2. `FirebaseMessaging.onBackgroundMessage(…)` **before** `runApp`
3. Request notification permission
4. Android 13+: `POST_NOTIFICATIONS` in `AndroidManifest.xml` + plugin request (Android 12 phones like many test devices skip this permission)
5. `getToken()` → `POST /drivers/devices`
6. `onTokenRefresh` → same POST
7. Logout → `DELETE /drivers/devices/:token`
8. Foreground: `FirebaseMessaging.onMessage` → `flutter_local_notifications.show` (tray). OS will **not** show FCM while Champ is open.
9. Background / killed: same local-notification helper in the background handler (data-only FCM)

### Android extras

```
POST_NOTIFICATIONS
com.google.firebase.messaging.default_notification_channel_id = yjeek_driver_default
default_notification_icon = white drawable (not the colour launcher)
```

Create channel `yjeek_driver_default` (and `yjeek_driver_jobs`) in `MainActivity` / local-notifications plugin, importance HIGH.

### Do not skip

- Full rebuild after adding native plugins (`flutter run`). Hot reload is not enough.
- Local API for laptop testing: USB `adb reverse tcp:3000 tcp:3000` + `http://127.0.0.1:3000/api/v1`, **or** LAN `http://103.208.183.248:3000/api/v1`. Production `https://api.yjeektech.com` will not send FCM until Firebase env is on AWS.
- In-app TODAY list ≠ phone tray. Swipe down the status bar to verify push.

---

## 6. Suggested implementation order

1. Prisma `DriverProfile.devices` + migrate.
2. `POST/DELETE /drivers/devices`.
3. `persistDriverNotification` + FCM send; wrap all `driverNotification.create*`.
4. FlutterFire files + Gradle/iOS.
5. Real `PushNotificationService` (token + tray).
6. Tap-through from FCM `data` to job / notifications.
7. Test on a real phone (emulator FCM is unreliable).

---

## 7. How to test

1. Restart backend → log `[fcm] enabled project=…`
2. Driver app full install, login, allow notifications.
3. Confirm `POST /drivers/devices` in app logs / backend.
4. Trigger a job offer (place a customer order that dispatches to this champ) **or** admin “notify champ”.
5. Expect:
   - row in Champ **Notifications** (TODAY)
   - Android tray / heads-up (even if the app is open)
   - home badge `unreadNotificationsCount`
6. If inbox updates but tray does not: FCM never sent, token missing, or still on the stub `PushNotificationService`.

---

## 8. Production

Copy the same Firebase service-account env onto AWS (do not commit `.env` or `secrets/firebase-service-account.json`). Restart the API process. Driver APK/IPA must use the production Firebase apps (`bh.yjeek.driver`) and `https://api.yjeektech.com/api/v1`.
