# lib/

## Architecture Overview

Flow is architected using **Clean Architecture** principles, ensuring a strict separation of concerns through logical layering:

-   `core/`: Application-wide utilities, configuration, network interceptors, and low-level services (Auth, Storage, Logger).
-   `domain/`: The "Heart" of the app. Contains pure business logic, Entities (Song, Playlist), and Repository Interfaces.
-   `data/`: Implementation detail layer. Handles data fetching, DTO mapping, and local persistence (Hive).
-   `presentation/`: UI layer containing Widgets, Screens, and State Management (BLoC/Cubit).

### Composite Data Strategy
The system utilizes a `CompositeMusicRepository` that acts as a unified facade for multiple sources. It seamlessly blends:
-   `YoutubeMusicAdapter`: Remote streaming via the InnerTube API.
-   `LocalFilesAdapter`: On-device media discovery and playback.
-   `SpotifyAdapter`: Metadata matching and playlist importing.

---

## YouTube Music Authentication Protocol

Flow implements a sophisticated bypass for Google's "guest-feed downgrade" to ensure users receive their personalized recommendations instead of generic top charts.

### 1. SAPISIDHASH Generation
Authenticated requests to `youtubei.googleapis.com` require a rotating `Authorization` header. We generate this using the `SAPISID` cookie and a UNIX timestamp:

```dart
final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
final sapisid = getCookie('SAPISID');
final origin = 'https://music.youtube.com';
final hash = sha1('$timestamp $sapisid $origin');
final authHeader = 'SAPISIDHASH ${timestamp}_$hash';
```

### 2. Strict Cookie Scoping
To avoid "Cookie Poisoning," the app extracts tokens exclusively from the `music.youtube.com` domain. This prevents generic Google account cookies (from `accounts.google.com`) from overwriting the specialized `SAPISID` required for InnerTube authentication.

### 3. Anti-Bot & User-Agent Spoofing
Google triggers a CSRF/Bot block if an Android User-Agent is detected alongside a `WEB_REMIX` client payload. Flow unconditionally spoofs a **Desktop Chrome User-Agent** (`Mozilla/5.0 (Windows NT 10.0...)`) to maintain compatibility with the web-based InnerTube endpoints.

### 4. Geolocation Alignment
To prevent session downgrades or `403 Forbidden` errors, the InnerTube `context` payload must match the physical IP region. We enforce:
-   `gl`: 'IN' (or matching region)
-   `utcOffsetMinutes`: 330 (matching the target timezone)

---

## Safe JSON Parsing Strategy

YouTube Music's InnerTube API returns deeply nested, highly dynamic JSON. Flow employs a "Defensive Parsing" strategy:

-   **Iterative Robustness**: We use explicit `for` loops with `continue` and `try/catch` blocks for per-item parsing. A single malformed node or unexpected renderer type will never crash an entire shelf or screen.
-   **Eager Mapping**: We avoid lazy casting (`.cast<T>()`) which can lead to silent `TypeError` crashes during iteration. Instead, we use `.map().toList()` to enforce type safety at the boundaries of the data layer.
-   **DTO Conversion**: Raw `Map<String, dynamic>` payloads are converted into strongly-typed `SongModel` or `PlaylistModel` entities within the Data layer before being exposed to the Domain or UI.

---

## P2P & Intelligence

-   **LanStreamBridge**: Enables peer-to-peer streaming across the local network without consuming external bandwidth.
-   **BleDiscoveryService**: Facilitates proximity-based music sharing and synchronized playback.
-   **AppIntelligence**: A graph-based recommendation node system that blends user taste profiles from multiple sources (YTM history + Local listening habits).
