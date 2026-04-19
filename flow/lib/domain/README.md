# Domain Layer

The **Domain** layer is the core of the application. it contains business logic, entities, and repository interfaces. This layer is strictly independent of Flutter, UI, and external data sources.

## Components

- **`entities/`**: Pure data objects (POJOs) that represent the core business concepts.
  - `Song`: Metadata and state for a single track.
  - `HomeData`: Structure of the home feed (shelves).
  - `HistoryData`: Segmented playback history.
- **`repositories/`**: Abstract interfaces that define *what* data can be fetched, without specifying *how*. 
  - Implementation of these interfaces lives in the **Data** layer.
- **`usecases/`**: Encapsulate specific business actions (e.g., `SearchSongsUseCase`, `GetHomeDataUseCase`). 
  - Each usecase follows the "Single Responsibility Principle".

## Principles
- **No Side Effects:** Domain logic should be predictable and testable.
- **Dependency Inversion:** This layer defines the interfaces that outer layers (Data, Presentation) must conform to.
- **Entity Immutability:** All entities use `final` fields and provide `copyWith` methods for state transitions.
