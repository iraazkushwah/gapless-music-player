# BRAIN.md

## 1. Project Identity
- **Project Name:** G4Music (Gapless)
- **Purpose:** A lightweight, fast music player focused on large music collections, written in Vala and GTK4.
- **Main Users/Use Cases:** Users who want an elegant, gapless playback music player for local or remote (via Samba/GIO) music files.
- **Current Development Status:** Active/Stable (version 4.6.2).
- **Important Product Constraints:** Must handle thousands of music files quickly, use low memory, support MPRIS, ReplayGain, and gapless playback.

## 2. Technology Stack
- **Programming Languages:** Vala, C
- **Frameworks:** GTK4, libadwaita
- **Major Dependencies:** 
  - `gstreamer-1.0` and `gstreamer-tag-1.0` for audio playback and metadata parsing.
  - `posix`, `m` (standard C libraries).
- **Database/Storage:** None (uses file system and in-memory cache for metadata).
- **Build Tools:** Meson, Ninja

## 3. Repository Structure
- `README.md`: Project description and installation guide.
- `meson.build`: Root build configuration file.
- `data/`: App metadata, icons, and `app.gschema.xml` (GSettings configuration).
- `po/`: Localization and translation files.
- `src/`: Main application source code.
  - `main.vala`: Application entry point.
  - `application.vala`: Application lifecycle and global state management.
  - `gst/`: GStreamer integration for audio playback and tag parsing (`gst-player.vala`).
  - `gtk/`: UI templates (`.ui`) and stylesheets (`style.css`).
  - `ui/`: UI components and widgets implementation (`window.vala`, `play-panel.vala`).
  - `utils/`: Core utilities for music parsing, library management, and file I/O (`music-library.vala`, `music-loader.vala`).

## 4. Architecture and Component Relationships
- **Main Architectural Pattern:** GTK Model-View architecture with Vala objects managing state.
- **Application Entry Point:** `src/main.vala` -> initializes `G4.GstPlayer` -> starts `G4.Application`.
- **Module Boundaries:**
  - **`Application` (`src/application.vala`):** The central hub managing `GstPlayer`, `MusicLoader`, `Settings`, and MPRIS.
  - **Playback (`src/gst/gst-player.vala`):** Wraps GStreamer (`playbin` / `playbin3`), handles seeking, volume, replay gain, and audio peak calculation.
  - **Library (`src/utils/music-library.vala` & `music-loader.vala`):** Scans files, extracts metadata, and categorizes music into `Album`, `Artist`, and `Playlist`.
  - **UI (`src/ui/`):** Utilizes `Adw.ApplicationWindow` containing a `Leaflet` that splits into `StorePanel` (music library view) and `PlayPanel` (now playing view).

## 5. Core Features and Business Logic
- **Audio Playback:**
  - **Purpose:** Play music, support gapless, volume control.
  - **Files:** `src/gst/gst-player.vala`
  - **Flow:** `Application` sets `uri` on `GstPlayer`, which interacts with GStreamer bus messages for state changes, tags, and EOF.
- **Library Scanning:**
  - **Purpose:** Fast parsing of thousands of files.
  - **Files:** `src/utils/music-loader.vala`, `src/utils/music.vala`
  - **Flow:** Recursively loads files from the music folder, parses tags via GStreamer/filenames, caches metadata, and populates `MusicLibrary`.
- **UI State and Filtering:**
  - **Purpose:** Display and sort collections.
  - **Files:** `src/ui/store-panel.vala`, `src/ui/window.vala`
  - **Flow:** Uses `Gtk.FilterListModel` bound to the internal `ListStore` of music items for efficient UI rendering and search.

## 6. Data and State Management
- **Configuration:** Managed via `GSettings`. Schema defined in `data/app.gschema.xml`.
- **Cache/Persistence:** No traditional database. Caches music metadata in standard cache directories (`~/.cache/g4music`) to avoid re-parsing tags. Playlists are saved as `.m3u` files.

## 7. Development Commands
- **Build and Install:**
  ```bash
  meson setup build --buildtype=release
  meson install -C build
  ```

## 8. Coding Standards and Established Patterns
- **Language:** Vala with modern async/await patterns.
- **Naming Conventions:** CamelCase for classes, snake_case for methods/variables, prefix `_` for private fields.
- **Memory Management:** Vala's reference counting (GObject).
- **UI Design:** strictly follows GNOME Human Interface Guidelines (HIG) using `libadwaita` for adaptive design.

## 9. Critical Files and Change Impact
- `src/application.vala`: High impact. Modifying this affects global app behavior, routing of playback events, and window lifecycle.
- `src/gst/gst-player.vala`: Critical for playback. Changes here must be careful about GStreamer threads and bus message handling.
- `src/utils/music-library.vala`: Core data structures. Modifying `Music`, `Album`, `Artist`, or `Playlist` classes impacts the entire application data flow and sorting logic.

## 10. Rules for Future AI Coding Sessions
1. Read `BRAIN.md` first to understand the project at a high level.
2. Identify the specific feature, bug, or module relevant to the current request.
3. Inspect only the relevant source files and their immediate dependencies.
4. Do not repeatedly rescan the entire repository unless the task genuinely requires it.
5. Use existing architecture, naming conventions, libraries, and patterns (e.g., Vala async/await, GStreamer usage).
6. Trace dependencies before modifying shared components or core logic.
7. Avoid unnecessary rewrites, duplicate implementations, speculative abstractions, and unrelated cleanup.
8. Make the smallest complete change that satisfies the request.
9. Preserve existing behavior outside the requested scope.
10. Update `BRAIN.md` only when meaningful architectural or technical context changes.
11. Never treat `BRAIN.md` as a replacement for inspecting source code when implementation details matter.
12. If documentation conflicts with the source code, trust the verified current implementation and correct the documentation when appropriate.
13. If essential context is missing, inspect the relevant files rather than guessing.

## 11. Documentation Maintenance
- Update this document only when major architectural changes occur (e.g., adding a database, switching away from GStreamer, changing the build system).
- Keep descriptions concise and avoid code duplication.
