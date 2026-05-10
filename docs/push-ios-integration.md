# Push notifications: iOS client integration

How a paid iOS substrate client (e.g. the closed-source `NativeAppTemplate` iOS app) integrates with this API to receive push notifications via APNs.

This is the implementation guide for **PR #3** of [issue #58](https://github.com/nativeapptemplate/nativeapptemplateapi/issues/58). The free iOS substrate intentionally does not get push registration code — push is a paid-edition feature, gated at the client layer (the API endpoint is open; the gate is "you have to write the client to use it").

---

## Scope summary

| Concern | Where it lives |
|---|---|
| APNs auth key (`.p8`) provisioning | This Rails repo's encrypted credentials (`bin/rails credentials:edit`) |
| Notification payload composition | `ItemTagNotifier` in this repo |
| Notification delivery | Action Push Native, fired by `ItemTag`'s AASM `complete` event |
| Device token registration API | `POST /api/v1/shopkeeper/devices` (see [`docs/openapi.yaml`](openapi.yaml)) |
| iOS-side token receipt + lifecycle | The paid iOS client (this doc) |
| Permission UX | The paid iOS client (this doc) |
| Foreground / background presentation | The paid iOS client (this doc) |

---

## API contract recap

The iOS client posts the APNs device token to the substrate after each successful registration:

```
POST /api/v1/shopkeeper/devices
Content-Type: application/json
Authorization headers: <devise_token_auth headers>

{
  "device": {
    "token": "<APNs device token, hex-encoded>",
    "platform": "apple",
    "bundle_id": "com.your.bundle.id"
  }
}
```

- **`platform: "apple"`** — matches Action Push Native's APNs service convention. Do **not** send `"ios"`.
- **`bundle_id`** — optional but recommended; helps disambiguate when one shopkeeper uses multiple agent-generated app variants.
- Idempotent: the server upserts on `(platform, token)`. First POST returns `201 Created`, subsequent re-registrations of the same `(platform, token)` return `200 OK` and refresh `last_active_at`.
- If the same token previously belonged to another shopkeeper (e.g. user signed out + new user signed in on the same device), the server rebinds it to the current shopkeeper.

On sign-out, the client should `DELETE /api/v1/shopkeeper/devices/:id` to unregister. The server returns `204 No Content`.

Full schemas: see `Device`, `DeviceAttributes`, `DeviceCreateRequest` in [`docs/openapi.yaml`](openapi.yaml) and the `/devices` paths near the end.

---

## Capabilities & project setup

In Xcode:

1. Target → **Signing & Capabilities** → add **Push Notifications**.
2. Target → **Signing & Capabilities** → add **Background Modes** → check **Remote notifications** if silent pushes are needed.
3. In the Apple Developer portal, the bundle ID's App ID must have **Push Notifications** entitlement enabled.
4. Provision an **APNs Authentication Key (.p8)** in App Store Connect → Keys. The substrate uses key-based auth (not certificate-based). Hand the `.p8`, key ID, and team ID to whoever maintains the API's encrypted credentials — they go in `Rails.application.credentials.action_push_native.apns.*` (see `config/push.yml`).

The Rails server side is already wired up (PRs #59, #60, #61). The iOS client is the missing piece.

---

## Permission UX

Request notification permission at a moment that makes sense for the user — typically after they've signed in and seen the feature's value, not at app first-launch.

```swift
import UserNotifications

func requestPushAuthorization() async {
    let center = UNUserNotificationCenter.current()
    do {
        let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
        guard granted else { return }
        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }
    } catch {
        // log / surface to user as appropriate
    }
}
```

If the user previously denied, `requestAuthorization` returns `false` immediately and the system does not re-prompt. Surface a "open Settings" affordance in that case.

---

## Token lifecycle

The four moments the iOS client cares about:

### 1. Token received (`AppDelegate`)

```swift
func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
) {
    let token = deviceToken.map { String(format: "%02x", $0) }.joined()
    Task { await PushTokenSync.shared.register(token: token) }
}

func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
) {
    // Common in Simulator / when network is offline. Log; surface only in dev.
}
```

`PushTokenSync.register(token:)` posts to `/api/v1/shopkeeper/devices` with `platform: "apple"`. Cache the returned `device.id` in keychain — you'll need it for the sign-out DELETE.

### 2. Token refreshed (silent)

iOS may rotate the APNs token. Call `UIApplication.shared.registerForRemoteNotifications()` on every cold start *while signed in*; iOS will re-deliver the current token via `didRegisterForRemoteNotificationsWithDeviceToken`. The server's idempotent upsert handles re-POSTs cleanly.

### 3. Sign-in (existing token, new shopkeeper)

If a user signs out and a different user signs in on the same device, re-POST the cached token. The server rebinds the token to the new `current_shopkeeper`. Don't try to manage this by deleting + re-registering — the rebind path is simpler and atomic.

### 4. Sign-out

```swift
func signOut() async {
    if let deviceId = KeychainStore.devicePushId {
        try? await api.delete("/api/v1/shopkeeper/devices/\(deviceId)")
    }
    KeychainStore.devicePushId = nil
    // ...rest of sign-out flow
}
```

If the DELETE fails (e.g. network), don't block sign-out. The server's `last_active_at` staleness scope (90 days) eventually prunes orphaned tokens.

---

## Foreground & background presentation

The notifier (`ItemTagNotifier` in this repo) sends `title`, `body`, and `data: { url: <api path> }`.

```swift
extension AppDelegate: UNUserNotificationCenterDelegate {
    // Foreground: ask iOS to show the banner anyway
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        return [.banner, .sound, .badge]
    }

    // Tap: pull data.url and route to the right screen
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        if let url = userInfo["url"] as? String {
            DeepLinkRouter.shared.handle(url)
        }
    }
}
```

The `data.url` is an API path (e.g. `/api/v1/shopkeeper/shops/:shop_id/item_tags/:id`) — the client maps it to its own navigation stack.

---

## Testing locally

- **In the simulator**: APNs registration calls `didFailToRegisterForRemoteNotificationsWithError` — by design. Use a real device for end-to-end testing, or stub `register(token:)` in dev builds with a fixed fake token to exercise the API call.
- **Triggering a push**: in the Rails console on a dev box with credentials provisioned, transition `ItemTag` from `idled` to `completed`:
  ```ruby
  it = ItemTag.find(...)
  it.completed_by = some_other_shopkeeper  # not the recipient
  it.complete!
  ```
  The recipient set is `it.shop.account.shopkeepers` minus `completed_by`. See `app/models/item_tag.rb#notify_completed`.
- **Without provider credentials**: `ApplicationPushNotification.enabled` defaults to `!Rails.env.test?`. In dev/prod without credentials, delivery enqueues but fails at the APNs HTTP call. Watch the job logs.

---

## Out of scope for this guide

- **Notification grouping / threading**: tune via `thread_id` on the notifier if needed; not required for v1.
- **Notification actions** (custom buttons): defer to a follow-up.
- **Critical alerts** / **time-sensitive**: requires a separate Apple entitlement; defer.
- **Notification Service Extension** (image attachments, modify-on-receive): not needed for the substrate's text-only payloads.
