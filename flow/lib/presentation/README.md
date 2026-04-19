# Presentation Layer

The **Presentation** layer handles the UI, user interaction, and state management.

## Architecture (BLoC/Cubit Pattern)

We use the BLoC pattern to strictly separate UI from business logic:

- **`blocs/`**: Complex state machines with event-driven logic.
  - `PlayerBloc`: The brain of the application. Orchestrates audio playback, queue management, and stream resolution.
- **`cubits/`**: Simplified state management for data fetching and simple states.
  - `HomeCubit`: Manages the feed data.
  - `SongDetailsCubit`: Fetches artist/song info in parallel with playback.
  - `SettingsCubit`: Manages theme and local preferences.
- **`screens/`**: Full-page widgets (e.g., `HomeScreen`, `PlayerScreen`). 
  - Each screen corresponds to a major feature area.
- **`widgets/`**: Reusable UI components (e.g., `SongTile`, `SquigglyProgressBar`, `Skeleton`).

## Performance Design (Lazy State)
To keep the UI highly responsive, especially on the **Player Screen**:
- **JIT Resolution:** `PlayerBloc` uses Just-In-Time resolution for audio URLs.
- **Background Prefetching:** Heavy network tasks (Stream resolution, Palette extraction) are handled in the background without blocking the UI thread.
- **Parallel Cubits:** Metadata fetching (Song/Artist details) is decoupled from the main playback bloc to prevent "waterfall" delays.

## UI Styling
- **Material 3:** Follows Material 3 design guidelines.
- **Custom Design Tokens:** Uses a centralized `AppConstants` for spacing and radii.
- **Dynamic Theming:** Extracts colors from album art to dynamically theme the player and home feed.
