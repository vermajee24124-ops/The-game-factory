# Turbo Rush Release Configuration

## Canonical Android identity

- App name: Turbo Rush
- Android package name: `com.vermajeeverma.turborush`
- Support email: `vermagamestudios@gmail.com`
- Godot: 4.7.2
- Android architecture: arm64-v8a
- Export preset: Android Debug APK
- Gradle export: enabled

## Unity Ads configuration

The supplied Unity dashboard screenshot shows six active Ad Units:

- Banner_Android
- Banner_iOS
- Rewarded_Android
- Rewarded_iOS
- Interstitial_Android
- Interstitial_iOS

The project already has the Android Game IDs:

- Android Game ID: `6195679`
- iOS Game ID: `6195678`

For the Android build, the Banner_Android ID is used for two banner instances: one at the top and one at the bottom during the startup/loading window only. Unity's Android SDK supports multiple banner instances from a banner placement.

The screenshot supplied for this release truncates the actual Ad Unit ID strings. They must be copied exactly from Unity Dashboard before a live Unity Ads bridge can be enabled. No IDs are guessed.

## Aptoide Billing configuration

Aptoide Connect supplied the current package context:

`com.vermajeeverma.turborush`

Public key supplied for the Android Billing SDK is stored in the project's release configuration:

`projects/GME-2026-0003/godot/autoload/ReleaseConfig.gd`

Stable product IDs used by the current Turbo Rush economy layer:

- `diamond_small`
- `diamond_medium`
- `diamond_large`
- `diamond_epic`
- `remove_ads`

These IDs must exist in Aptoide Connect before live purchases can be queried. The billing integration must use prices returned by Aptoide Connect rather than hard-coded prices in the store UI.

## Startup advertisement behavior

1. Turbo Rush logo/startup screen appears.
2. Loading sequence begins.
3. When internet connectivity, consent, Unity Ads initialization and valid Banner_Android configuration are all available, two banner instances are shown.
4. One banner is anchored at the top and one at the bottom.
5. The banners are hidden before the lobby is displayed.
6. No startup wait is tied to ad loading.
7. Rewarded ads remain opt-in and are used only for explicit reward actions.

## Notifications

The intended product behavior is user-controlled local reminders while the game is not in the foreground and optional online event/update notifications. Notification permission and privacy requirements must be respected. Android 13+ requires the `POST_NOTIFICATIONS` runtime permission for non-exempt notifications.

The project should not use exact-alarm permissions merely to create frequent promotional reminders. Any background scheduling must use an Android-compliant mechanism and a sensible, user-controlled cadence.

## Aptoide distribution

The supplied Aptoide Connect console snapshot exposes:

- 249 countries available for distribution
- 13 distribution channels
- Country selection can be made from the submission form.
- Channel selection makes the app eligible for a partner store, but the partner independently decides whether to offer it.
- Aptoide review is still required before launch.
- Android developer verification and package-name registration are required for alternative-store distribution under the current Aptoide/Android process.

The intended release configuration is to select all countries offered by the console and all available distribution channels, subject to the console's validation, partner availability and applicable law/policy.

## Release blockers still requiring external console data

The following cannot be safely invented from the supplied screenshots/files:

1. Exact Android Unity Ad Unit ID strings.
2. Exact Aptoide product registration status and prices.
3. Aptoide real-time notification/webhook configuration, if used.
4. Final production signing keystore and passwords.

The current GitHub source is therefore configured to accept the real values without changing the package name or economy identifiers.
