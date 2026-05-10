# Push notifications: Android client integration

How a paid Android substrate client (e.g. the closed-source `NativeAppTemplate` Android app) integrates with this API to receive push notifications via Firebase Cloud Messaging (FCM).

This is the implementation guide for **PR #4** of [issue #58](https://github.com/nativeapptemplate/nativeapptemplateapi/issues/58). The free Android substrate intentionally does not get push registration code — push is a paid-edition feature, gated at the client layer (the API endpoint is open; the gate is "you have to write the client to use it").

---

## Scope summary

| Concern | Where it lives |
|---|---|
| FCM service account JSON provisioning | This Rails repo's encrypted credentials (`bin/rails credentials:edit`) |
| Notification payload composition | `ItemTagNotifier` in this repo |
| Notification delivery | Action Push Native, fired by `ItemTag`'s AASM `complete` event |
| Device token registration API | `POST /api/v1/shopkeeper/devices` (see [`docs/openapi.yaml`](openapi.yaml)) |
| Android-side token receipt + lifecycle | The paid Android client (this doc) |
| Permission UX (API 33+) | The paid Android client (this doc) |
| Notification channels | The paid Android client (this doc) |
| Foreground / background presentation | The paid Android client (this doc) |

---

## API contract recap

The Android client posts the FCM registration token to the substrate after each successful registration:

```
POST /api/v1/shopkeeper/devices
Content-Type: application/json
Authorization headers: <devise_token_auth headers>

{
  "device": {
    "token": "<FCM registration token>",
    "platform": "google",
    "bundle_id": "com.your.application.id"
  }
}
```

- **`platform: "google"`** — matches Action Push Native's FCM service convention. Do **not** send `"android"`.
- **`bundle_id`** — optional but recommended; helps disambiguate when one shopkeeper uses multiple agent-generated app variants. Use the Android `applicationId`.
- Idempotent: the server upserts on `(platform, token)`. First POST returns `201 Created`, subsequent re-registrations of the same `(platform, token)` return `200 OK` and refresh `last_active_at`.
- If the same token previously belonged to another shopkeeper (e.g. user signed out + new user signed in on the same device), the server rebinds it to the current shopkeeper.

On sign-out, the client should `DELETE /api/v1/shopkeeper/devices/:id` to unregister. The server returns `204 No Content`.

Full schemas: see `Device`, `DeviceAttributes`, `DeviceCreateRequest` in [`docs/openapi.yaml`](openapi.yaml) and the `/devices` paths near the end.

---

## Firebase project setup

In Firebase console:

1. Create a Firebase project for the substrate's canonical bundle ID (`com.nativeapptemplate.*`). Agent-renamed apps create their own Firebase projects.
2. Add an Android app to the project; download `google-services.json`.
3. Place `google-services.json` at `app/google-services.json` (gitignored — it contains the project's API key, which is not strictly secret but should rotate per fork).
4. Generate a **service account key** (Project settings → Service accounts → Generate new private key). The JSON file goes into the API's encrypted credentials at `Rails.application.credentials.action_push_native.fcm.encryption_key` (see `config/push.yml`); the `project_id` lives there too.

Project-level `build.gradle.kts`:

```kotlin
plugins {
    id("com.google.gms.google-services") version "4.4.2" apply false
}
```

App-level `build.gradle.kts`:

```kotlin
plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:33.4.0"))
    implementation("com.google.firebase:firebase-messaging-ktx")
}
```

The Rails server side is already wired up (PRs #59, #60, #61). The Android client is the missing piece.

---

## Manifest: permission, service, channel

`AndroidManifest.xml`:

```xml
<!-- API 33+ requires runtime permission for notifications -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

<application ...>
    <!-- FCM token + payload receiver -->
    <service
        android:name=".push.AppFirebaseMessagingService"
        android:exported="false">
        <intent-filter>
            <action android:name="com.google.firebase.MESSAGING_EVENT" />
        </intent-filter>
    </service>

    <!-- Optional: default notification channel + small icon -->
    <meta-data
        android:name="com.google.firebase.messaging.default_notification_channel_id"
        android:value="@string/default_notification_channel_id" />
    <meta-data
        android:name="com.google.firebase.messaging.default_notification_icon"
        android:resource="@drawable/ic_notification" />
</application>
```

---

## Permission UX (API 33+)

On Android 13+, `POST_NOTIFICATIONS` is a runtime permission. Request at a moment that makes sense — after sign-in and feature exposure, not at first launch.

```kotlin
class PushPermissionRequester(private val activity: ComponentActivity) {
    private val launcher = activity.registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { granted ->
        if (granted) registerForPush() else /* surface "open settings" affordance */
    }

    fun ensurePermission() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            registerForPush()
            return
        }
        when (PackageManager.PERMISSION_GRANTED) {
            ContextCompat.checkSelfPermission(activity, Manifest.permission.POST_NOTIFICATIONS) ->
                registerForPush()
            else ->
                launcher.launch(Manifest.permission.POST_NOTIFICATIONS)
        }
    }
}
```

If permission is denied, the FCM token still arrives via the service callback, but the system suppresses any UI. Decide whether to skip POSTing the token in that case (saves the round-trip) or POST it anyway (so the next permission grant Just Works without re-registration).

---

## Notification channels

Required on API 26+. Create channels at app startup (idempotent):

```kotlin
class NotificationChannels(private val context: Context) {
    fun ensure() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = context.getSystemService(NotificationManager::class.java)
        val channel = NotificationChannel(
            DEFAULT_CHANNEL_ID,
            context.getString(R.string.default_channel_name),
            NotificationManager.IMPORTANCE_DEFAULT
        ).apply {
            description = context.getString(R.string.default_channel_description)
        }
        nm.createNotificationChannel(channel)
    }

    companion object {
        const val DEFAULT_CHANNEL_ID = "item_tag_completed"
    }
}
```

Reference `DEFAULT_CHANNEL_ID` from the manifest's `default_notification_channel_id` `meta-data` so FCM's "notification" payloads land in this channel without per-message channel config.

---

## Token lifecycle

### 1. Token received (`FirebaseMessagingService`)

```kotlin
class AppFirebaseMessagingService : FirebaseMessagingService() {
    override fun onNewToken(token: String) {
        // Fires on first launch and whenever FCM rotates the token.
        // Posting is best-effort; if not signed in, queue and retry on sign-in.
        PushTokenSync.register(token)
    }

    override fun onMessageReceived(message: RemoteMessage) {
        // Foreground delivery handler — see "Foreground & background" below.
        NotificationPresenter.show(this, message)
    }
}
```

`PushTokenSync.register(token)` posts to `/api/v1/shopkeeper/devices` with `platform: "google"`. Cache the returned `device.id` in EncryptedSharedPreferences — you'll need it for the sign-out DELETE.

### 2. Token refresh

FCM may rotate the token at any time; `onNewToken` fires automatically. No need to poll. Optionally, on app startup *while signed in*, fetch the current token via `FirebaseMessaging.getInstance().token` and POST again — defends against the rare case where `onNewToken` was missed (e.g. user reinstalled the app).

### 3. Sign-in (existing token, new shopkeeper)

When a different user signs in on the same device, fetch the cached token and re-POST. The server rebinds the token to the new `current_shopkeeper` (single round-trip, atomic).

### 4. Sign-out

```kotlin
suspend fun signOut() {
    val deviceId = encryptedPrefs.getString(KEY_DEVICE_ID, null)
    if (deviceId != null) {
        runCatching { api.deleteDevice(deviceId) }
    }
    encryptedPrefs.edit { remove(KEY_DEVICE_ID) }
    // ...rest of sign-out flow
}
```

If the DELETE fails (network), don't block sign-out. The server's `last_active_at` staleness scope (90 days) eventually prunes orphaned tokens.

Optionally also call `FirebaseMessaging.getInstance().deleteToken()` to fully invalidate the FCM token. Skip this if you want re-sign-in on the same device to be silent (no permission re-prompt, immediate token reuse).

---

## Foreground & background presentation

The notifier (`ItemTagNotifier` in this repo) sends `title`, `body`, and `data: { url: <api path> }` via Action Push Native, which constructs the FCM payload as:

- **Notification payload** (system shows automatically when app is backgrounded): `title`, `body`
- **Data payload**: `url` (and any other `data:` keys)

When the app is in the **foreground**, `onMessageReceived` is called with the `RemoteMessage` and the system does **not** show a notification automatically — the client must build it:

```kotlin
object NotificationPresenter {
    fun show(context: Context, message: RemoteMessage) {
        val title = message.notification?.title ?: message.data["title"] ?: return
        val body = message.notification?.body ?: message.data["body"] ?: ""
        val url = message.data["url"]

        val intent = url?.let { DeepLinkRouter.intentFor(context, it) }
            ?: Intent(context, MainActivity::class.java)
        val pending = PendingIntent.getActivity(
            context, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(context, NotificationChannels.DEFAULT_CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(body)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentIntent(pending)
            .setAutoCancel(true)
            .build()

        NotificationManagerCompat.from(context).notify(message.messageId.hashCode(), notification)
    }
}
```

When the app is in the **background or killed**, the system shows the notification automatically using the FCM `notification` payload; tapping it launches the activity declared in `getLaunchIntentForPackage` with the `data` keys as extras. Pull `url` from the launching `Intent` in `MainActivity#onCreate` / `onNewIntent` and route.

The `data.url` is an API path (e.g. `/api/v1/shopkeeper/shops/:shop_id/item_tags/:id`) — the client maps it to its own navigation stack.

---

## Testing locally

- **Triggering a push**: in the Rails console on a dev box with credentials provisioned, transition `ItemTag` from `idled` to `completed`:
  ```ruby
  it = ItemTag.find(...)
  it.completed_by = some_other_shopkeeper  # not the recipient
  it.complete!
  ```
  The recipient set is `it.shop.account.shopkeepers` minus `completed_by`. See `app/models/item_tag.rb#notify_completed`.
- **Without provider credentials**: `ApplicationPushNotification.enabled` defaults to `!Rails.env.test?`. In dev/prod without credentials, delivery enqueues but fails at the FCM HTTP call. Watch the job logs.
- **Without a real device**: emulators with Google Play Services receive FCM pushes fine. AVD images **without** Google Play (the AOSP images) cannot.

---

## Out of scope for this guide

- **Notification grouping / summaries**: tune via `setGroup` if needed; not required for v1.
- **Custom notification actions**: defer.
- **In-app messaging** / Firebase Remote Config / Analytics: separate Firebase products; not part of push.
- **Topic subscriptions** (`subscribeToTopic`): not used — push is per-recipient via the substrate's `Noticed::Notification` records, not topic-based.
