# Flow App - Source Code (`lib`)

This directory contains the core logic and UI of the Flow Flutter application. It follows a modular architecture to ensure maintainability and testability.

## 📂 Directory Structure

- **[`core/`](./core):** Infrastructure and cross-cutting concerns (Auth, Network, Config, Storage).
- **[`domain/`](./domain):** Pure business logic, entities, and repository interfaces.
- **[`data/`](./data):** Data source implementations (API/Mock) and repository concrete classes.
- **[`presentation/`](./presentation):** UI components, screens, and state management (BLoCs/Cubits).

## 🏛️ Architecture Pattern

Flow uses a **Clean Architecture** approach combined with **BLoC** for state management:

1.  **UI (Presentation Layer)** calls a **BLoC**.
2.  **BLoC** executes a **UseCase (Domain Layer)**.
3.  **UseCase** requests data from a **Repository (Domain Layer Interface)**.
4.  **Repository Implementation (Data Layer)** fetches from an **API or Local Storage (Data Source)**.
5.  Data flows back up as **Entities** to the UI.
