# Core Layer

The **Core** layer contains foundational utilities, shared configurations, and cross-cutting concerns that are used by all other layers.

## Key Components

- **`auth/`**: Local session management and authentication event bus.
- **`config/`**: Application-wide constants and platform-specific settings.
- **`error/`**: Centralized `AppException` hierarchy for typed error handling across the app.
- **`logger/`**: Structured logging utility (`AppLogger`) with level filtering and formatted output.
- **`network/`**:
  - `DioClient`: Shared network client configuration.
  - `YoutubeInterceptor`: Handles SAPISID hashing and YouTube-specific headers for metadata requests.
  - `DownloadService`: Manages background downloads and local file persistence.
- **`storage/`**:
  - `LocalStorage`: Hive-based persistent storage for settings, history, and metadata.
  - `SecureStorageService`: Encrypted storage for sensitive data like cookies and tokens.
- **`responsive/`**: Utilities for handling adaptive UI layouts across Mobile, Tablet, and Desktop.
- **`ui/`**: Common UI helpers like `AppSnackBar` and global themes.

## Standalone Principles
This layer is strictly designed for **Standalone Operation**. It contains no code that assumes a centralized backend exists. All persistence and logic is local or interacts directly with 3rd party providers (e.g., YouTube Music).
