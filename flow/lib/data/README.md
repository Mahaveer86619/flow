# Flow App - Data Layer (`lib/data`)

The Data layer is responsible for fetching, caching, and serializing data from various sources.

## 📂 Sub-directories

- **[`sources/`](./sources):** Concrete implementations for data fetching.
  - `ApiSongDataSource`: Communicates with the Flow Source API.
  - `MockSongDataSource`: Provides static mock data for offline testing and development.
- **[`repositories/`](./repositories):** Concrete implementations of the interfaces defined in the `domain/` layer. These bridge the data sources and the domain logic.
- **[`models/`](./models):** Data transfer objects (DTOs) with `fromJson` and `toJson` methods for serialization.

## 🔄 Data Flow

1.  A **Repository** receives a request for data.
2.  It chooses the appropriate **Data Source** (API or local cache).
3.  The **Data Source** returns raw data or a **Model**.
4.  The **Repository** converts the **Model** into a **Domain Entity** for the use cases.
