# Flow App - Core Infrastructure (`lib/core`)

This directory contains the essential foundation of the app, providing low-level services and cross-cutting concerns.

## 📂 Sub-directories

- **[`auth/`](./auth):** JWT-based authentication state (Cubit) and events.
- **[`config/`](./config):** Global app configuration, including server base URL and fallback options.
- **[`error/`](./error):** Standardized app-wide exception and error handling.
- **[`logger/`](./logger):** Simple, consistent logging for debugging and monitoring.
- **[`network/`](./network):** Connectivity monitoring, and a high-performance download service.
- **[`platform/`](./platform):** Native platform integrations (e.g., Windows Media Keys, Permissions).
- **[`responsive/`](./responsive):** Breakpoints and layout utilities for cross-device support.
- **[`storage/`](./storage):** Hive-based local storage keys and services.

## 🛡️ Key Principles

- **Singleton Pattern:** Services here are often singletons for global app access.
- **Dependency Inversion:** Interfaces in `domain/` are implemented here when they interact with third-party libraries.
- **Error Propagation:** All low-level errors are wrapped in `AppException` before reaching the UI.
