# lib/presentation/

## State Management Strategy

Flow uses a **BLoC (Business Logic Component)** and **Cubit** architecture to handle complex UI states while maintaining high performance.

### PlayerBloc: The State Machine
The `PlayerBloc` is the central engine of the application. It manages a complex state machine for:
-   **Playback Lifecycle**: Handling play, pause, seek, and completion transitions.
-   **Queue Management**: Shuffling, repeating, and dynamic reordering of tracks.
-   **JIT Resolution**: Triggering `flow-jit` stream resolution for upcoming tracks to ensure zero-latency transitions.

### Parallel Cubits
We utilize specialized Cubits for isolated, non-blocking UI updates. For example, the `SongDetailsCubit` fetches metadata, lyrics, and high-res art in parallel to the main playback logic, ensuring the UI remains responsive even during heavy network activity.

---

## Responsive Layouts

The application implements a multi-device shell strategy to provide a native feel across platforms:

-   **DesktopShell**: A 3-pane layout for large screens (≥ 1100px).
    -   **Navigation Rail**: Persistent slim sidebar for primary navigation.
    -   **Main Content**: Central scrollable area for browsing.
    -   **Player Panel**: A persistent right-hand pane that slides in during playback, providing constant access to controls and queue.
-   **MainScreen (Mobile)**: A traditional mobile layout optimized for thumb-reachability.
    -   **Bottom Navigation**: Standard Material 3 navigation bar.
    -   **MiniPlayer**: A floating, dismissible bar for quick playback control.

---

## Dynamic Shelf Rendering

The Home Screen renders content dynamically using a hybrid approach to accommodate YTM's unpredictable shelf ordering:

1.  **Explicit Section Keys**: Recognized shelves (e.g., `quickPicks`, `listeningAgain`) are routed to specialized widgets with unique layouts (e.g., a 2x4 grid for Quick Picks).
2.  **Content-Type Sniffing**: For unrecognized shelves, Flow analyzes the contents. If the majority of items are tagged as `type: video`, the shelf is automatically rendered using the `MusicVideoShelf` horizontal wide-card layout.

---

## Performance Optimizations

Flow is designed for 60fps fluidity on both high-end and budget devices:

-   **RepaintBoundaries**: strategically placed around "heavy" widgets like blurred album art, text carousels, and continuous shelves to isolate pixel updates and reduce CPU/GPU load.
-   **Memory Management**: `CachedNetworkImage` is used with `memCacheWidth` and `memCacheHeight` constraints to prevent large 4K thumbnails from exhausting device RAM.
-   **SquigglyProgressBar**: A custom-engineered seek bar utilizing `CustomPainter` to animate a fluid wave effect at 60fps without the overhead of the standard Flutter animation controller on every frame.
