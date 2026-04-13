# Flow App - Presentation Layer (`lib/presentation`)

The Presentation layer is responsible for everything the user sees and interacts with.

## 📂 Sub-directories

- **[`screens/`](./screens):** Full-page UI components (e.g., `HomeScreen`, `PlayerScreen`, `LoginScreen`).
- **[`widgets/`](./widgets):** Reusable UI components (e.g., `SongTile`, `SquigglyProgressBar`, `SidebarLayout`).
- **[`blocs/`](./blocs) & [`cubits/`](./cubits):** State management logic.
  - `PlayerBloc`: Manages the complex state of audio playback and the `just_audio` engine.
  - `HomeCubit`: Manages the personalized home feed state.
  - `SearchCubit`: Manages the real-time search experience.

## 🎨 UI Guidelines

- **Material 3:** Adheres strictly to Material 3 design principles.
- **Dynamic Color:** Many widgets react to the current song's album art using `palette_generator`.
- **Responsive:** Layouts adapt dynamically using `ResponsiveLayout` and custom breakpoints.
