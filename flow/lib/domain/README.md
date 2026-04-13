# Flow App - Domain Layer (`lib/domain`)

The Domain layer is the heart of the application, containing all the core business logic and entities. It is pure Dart and has zero dependencies on Flutter or any external libraries.

## 📂 Sub-directories

- **[`entities/`](./entities):** Simple Dart classes that represent the core data structures used by the UI (e.g., `Song`, `Playlist`, `Artist`).
- **[`repositories/`](./repositories):** Abstract interface definitions for data operations. This layer *describes* what needs to happen without knowing *how* it's done.
- **[`usecases/`](./usecases):** One class per atomic business operation (e.g., `SearchSongsUseCase`, `GetHomeDataUseCase`). This is the only way for the UI to request logic.

## 🧪 Purity

- **No Imports:** This layer should never import anything from `package:flutter` or the `data/` layer.
- **Testability:** Being pure Dart, this layer is the easiest to unit test with 100% coverage.
