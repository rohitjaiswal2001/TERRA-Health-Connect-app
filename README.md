# Personally — Apple Health Bridge

A focused Flutter app whose **only job** is to be the Apple Health → [Terra](https://tryterra.co) bridge for the [Personally](https://personally-website.vercel.app) website.

The member never "uses" this app in a day-to-day sense. The website launches it with a one-time auth token, the app reads Apple Health and pushes it to Terra, then hands the member straight back to the website. On brand, one job, done well.

> **iOS-first.** This build targets iOS + Apple HealthKit. The architecture is platform-agnostic, so Android (Health Connect) can be layered on later by adding a connection type — see [Extending](#extending-to-android).

---

## The flow

```
┌─────────────┐   1. tap "Connect Apple Health"        ┌──────────────────┐
│  Personally │ ─────────────────────────────────────► │  Backend         │
│  website    │   2. POST /v2/auth/generateAuthToken   │  (issues token)  │
└─────────────┘ ◄───────────────────────────────────── └──────────────────┘
       │  3. open deep link
       │     personallyhealth://connect?token=…&reference_id=…&redirect=…
       ▼
┌──────────────────────────────────────────────────────────────────────┐
│  THIS APP                                                              │
│                                                                        │
│  • App installed?  ── no ──►  open App Store (handled by the website)  │
│  • App installed?  ── yes ─►  4. initConnection(appleHealth, token)    │
│                               5. Apple's HealthKit consent sheet       │
│                               6. read + push data to Terra webhook     │
│                               7. redirect back to the website          │
└──────────────────────────────────────────────────────────────────────┘
       │  7. openUrl(redirect)
       ▼
┌─────────────┐
│  Personally │  "You're connected"
│  website    │
└─────────────┘
```

The "open the app, or the App Store if not installed" fork is done **on the website** (a universal link or a short JS timer that falls back to the store URL). The app only needs to handle being opened with a valid link — see [Website integration](#website-integration).

---

## Architecture

State management is **[provider](https://pub.dev/packages/provider)** (`ChangeNotifier`). One provider owns the whole flow; screens are dumb and render off a single `ConnectionPhase` enum.

```
lib/
├── main.dart                         # entry point
├── app.dart                          # MaterialApp + ChangeNotifierProvider
│
├── core/
│   ├── config/app_config.dart        # dev id, scheme, urls (via --dart-define)
│   ├── constants/terra_scopes.dart   # the minimum Apple Health scopes we ask for
│   └── theme/
│       ├── app_colors.dart           # brand palette (black / lime / cream / …)
│       ├── app_typography.dart       # Archivo Black / Archivo / Instrument Sans
│       └── app_theme.dart            # ThemeData
│
├── models/
│   ├── connect_request.dart          # parses the website's deep link
│   └── connection_phase.dart         # the finite states of the flow
│
├── services/                         # all the "how", hidden from the UI
│   ├── terra_service.dart            # wraps terra_flutter_bridge
│   ├── deep_link_service.dart        # app_links listener
│   └── redirect_service.dart         # url_launcher (website / App Store)
│
├── providers/
│   └── connection_provider.dart      # orchestrates the flow, exposes phase
│
├── screens/                          # one screen per phase
│   ├── home_router.dart              # phase → screen
│   ├── welcome_screen.dart           # 01 · why connect (lime CTA)
│   ├── connecting_screen.dart        # initializing / syncing spinner
│   ├── connected_screen.dart         # 03 · the one earned lime moment
│   ├── manage_screen.dart            # 04 · what we read + disconnect
│   ├── declined_screen.dart          # A · skipped, never nag
│   ├── not_member_screen.dart        # B · route back to the funnel
│   └── error_screen.dart             # recoverable failure + retry
│
└── widgets/                          # brand building blocks
    ├── pl_logo.dart                  # tintable wordmark (SVG)
    ├── pl_button.dart                # pill CTA (lime / solid / ghost)
    ├── pl_scaffold.dart              # dark / cream / white grounds
    ├── app_eyebrow.dart              # "• LABEL" eyebrow
    ├── bloom.dart                    # the single lime glow
    └── data_scope_list.dart          # ticked category list
```

### Why this shape
- **Services** know about Terra / deep links / the OS. **Screens** know none of it — they call `provider.connect()` / `.skip()` / `.finish()`. This keeps the UI trivial to restyle and the integration trivial to test/mock.
- **`ConnectionPhase`** is the single source of truth. `HomeRouter` is the only "navigation" — the flow is linear, so there's no route stack.
- **Config via `--dart-define`** so no secrets live in the repo.

---

## Design system

Lifted from the website so the app and the site read as **one brand**.

| Token  | Value      | Use |
|--------|------------|-----|
| black  | `#050505`  | primary dark ground |
| lime   | `#D7FF3F`  | **scarce** — one signal per screen, black-on-lime, dark grounds only |
| cream  | `#F4F0E7`  | soft ground / text on dark |
| white  | `#FFFDF7`  | light ground (manage screen) |
| stone  | `#6F685E`  | secondary text |
| ink    | `#141310`  | text on light |

**Type:** `Archivo Black` (display) · `Archivo` 700/900 (headings, buttons, labels) · `Instrument Sans` (body). Pulled at runtime via `google_fonts` — nothing to bundle.

**The lime rule:** lime marks the primary action and the single "connected" moment, nothing else. Never on a light ground.

---

## Setup

### 1. Prerequisites
- Flutter 3.12+ / Dart 3.12+
- Xcode 15+, an iOS device or simulator (HealthKit data only exists on real devices / Health-populated simulators)
- A [Terra](https://dashboard.tryterra.co) account: **Dev ID** + **API key**, with Apple Health enabled and a webhook/destination configured

### 2. Install
```bash
flutter pub get
cd ios && pod install && cd ..   # if your Flutter uses CocoaPods for plugins
```

### 3. Xcode capabilities (once)
Open `ios/Runner.xcworkspace` and add to the **Runner** target → *Signing & Capabilities*:
- **HealthKit** (tick *Background Delivery*)
- **Background Modes** → *Background fetch* + *Background processing*

`Info.plist` already declares the matching keys:
- `NSHealthShareUsageDescription`, `NSHealthUpdateUsageDescription`, `NSHealthClinicalHealthRecordsShareUsageDescription`
- `BGTaskSchedulerPermittedIdentifiers` → `co.tryterra.data.post.request`
- `UIBackgroundModes` → `fetch`, `processing`
- `CFBundleURLTypes` → the `personallyhealth` deep-link scheme

`AppDelegate.swift` already calls `Terra.setUpBackgroundDelivery()`.

> Minimum iOS deployment target must be **13.0+** (TerraiOS requirement). Set it in Xcode or your `ios/Podfile` if a build complains.

### 4. Run
Pass your Terra config as defines:
```bash
flutter run \
  --dart-define=TERRA_DEV_ID=your-terra-dev-id \
  --dart-define=APP_STORE_URL=https://apps.apple.com/app/idXXXXXXXXX
```

To make **"Connect Apple Health" work standalone** (no website link — the app mints its own token), pass your Terra API key. This is the easiest way to test the real HealthKit consent + sync on a device:
```bash
flutter run \
  --dart-define=TERRA_DEV_ID=your-terra-dev-id \
  --dart-define=TERRA_API_KEY=your-terra-api-key
```
> ⚠️ `TERRA_API_KEY` is **dev/testing only** — never ship it in a store build. In production the token is minted by your backend and delivered via the deep link.

Alternatively, inject a single token you generated by hand:
```bash
flutter run \
  --dart-define=TERRA_DEV_ID=your-terra-dev-id \
  --dart-define=DEMO_TOKEN=paste-a-fresh-generateAuthToken-token
```

---

## Configuration reference (`--dart-define`)

| Key | Default | Purpose |
|-----|---------|---------|
| `TERRA_DEV_ID` | *(empty)* | Terra Developer ID. **Required.** |
| `TERRA_API_KEY` | *(empty)* | ⚠️ **Dev only.** Lets the button self-generate a token so it connects without a website link. Never ship in a store build. |
| `TERRA_REFERENCE_ID` | `personally-app` | Fallback member id when the link omits `reference_id`. |
| `APP_STORE_URL` | placeholder | App Store listing for the fallback/redirects. |
| `DEMO_TOKEN` | *(empty)* | Local-only: a hand-generated auth token to test without a deep link. |

**How the "Connect" button gets its token**, in priority order:
1. The `token` from the website's deep link (production).
2. `DEMO_TOKEN`, if set.
3. Self-generated in-app via `TERRA_API_KEY` (dev only).
4. None available → the button routes the member to the website to start.

The `personallyhealth` scheme and `websiteUrl` are in [`app_config.dart`](lib/core/config/app_config.dart).

---

## The Terra integration

All of it lives in [`terra_service.dart`](lib/services/terra_service.dart) (SDK: [`terra_flutter_bridge`](https://pub.dev/packages/terra_flutter_bridge)).

| Step | Call |
|------|------|
| Init SDK (once per launch) | `TerraFlutter.initTerra(devId, referenceId)` |
| Open Apple Health | `TerraFlutter.initConnection(Connection.appleHealth, token, false, scopes)` |
| Already connected? | `TerraFlutter.getUserId(Connection.appleHealth)` |
| Granted scopes | `TerraFlutter.getGivenPermissions()` |
| Push data → webhook | `getDaily / getActivity / getSleep / getBody / getMenstruation(…, toWebhook: true)` |

**Scopes** (in [`terra_scopes.dart`](lib/core/constants/terra_scopes.dart)) are the deliberate minimum — Apple rejects apps that over-ask:
activity & energy · sleep · heart · body measurements · cycle tracking.

**The auth token** is single-use and generated by your backend, never in the app:
```bash
curl --request POST \
  --url https://api.tryterra.co/v2/auth/generateAuthToken \
  --header 'dev-id: <YOUR-DEV-ID>' \
  --header 'x-api-key: <YOUR-API-KEY>'
```
Include the member's `reference_id` so Terra maps the data to the right user.

Data lands at your Terra **webhook/destination**, configured in the Terra dashboard — not returned to the app.

---

## Website integration

### 1. Generate a token (backend)
Call `generateAuthToken` with the member's `reference_id`.

### 2. Launch the app
Open the deep link with the token, the member's reference id, and where to return:
```
personallyhealth://connect
  ?token=<AUTH_TOKEN>
  &reference_id=<MEMBER_REF_ID>
  &redirect=<URL-ENCODED RETURN URL>
```

### 3. Fallback when the app isn't installed
Do the "try app, else App Store" fork on the web page. Simplest pattern:
```html
<a id="connect">Connect Apple Health</a>
<script>
  document.getElementById('connect').addEventListener('click', () => {
    const deepLink = 'personallyhealth://connect?token=…&reference_id=…&redirect=…';
    const appStore = 'https://apps.apple.com/app/idXXXXXXXXX';
    const t = setTimeout(() => (window.location = appStore), 1200);
    window.addEventListener('pagehide', () => clearTimeout(t)); // app opened
    window.location = deepLink;
  });
</script>
```
For a more robust hand-off, register an **Apple Universal Link** (`https://…/connect?…`) with an `apple-app-site-association` file — the app already accepts `https://…/connect?token=…` links too.

### 4. Return
The app opens the `redirect` URL when done. If none is supplied it falls back to `websiteUrl`.

---

## Testing

```bash
flutter analyze
flutter test          # deep-link parsing smoke tests
```

Manually fire a deep link at a running app/simulator:
```bash
xcrun simctl openurl booted \
  "personallyhealth://connect?token=TEST&reference_id=member-1&redirect=https%3A%2F%2Fpersonally-website.vercel.app"
```
(HealthKit itself needs a real device or a simulator with Health data to return anything.)

---

## Extending to Android

The bridge only knows Apple Health, but the SDK and this architecture support more. To add Health Connect:
1. Construct `TerraService(connection: Connection.healthConnect)`.
2. Pass `schedulerOn: true` to `initConnection` (Android uses the scheduler; iOS uses background delivery).
3. Add the Health Connect Android manifest entries per the Terra docs.

Everything above the service (`provider`, screens, widgets) stays untouched.

---

## References
- Terra Flutter SDK — https://docs.tryterra.co/unified-api/mobile-only-sources/flutter
- Terra dashboard — https://dashboard.tryterra.co
- Terra — https://tryterra.co
- Design source — `Mobile-App-Screens-AppleHealth-Bridge.html` and the website https://personally-website.vercel.app
