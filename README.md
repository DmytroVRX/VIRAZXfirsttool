# Virazx Quick Note

A minimal, dark-themed desktop note-taking app for Windows, built with Flutter.

## Features

- **Custom borderless window**: Clean UI without standard Windows frame
- **Auto-save**: Current note text is saved automatically as you type
- **Saved notes**: Save and manage multiple notes with custom names
- **Dark theme with pink accents**: Beautiful, eye-friendly design
- **Fast performance**: Optimized release build for Windows

## How to Use

1. **Type your note** in the main text area
2. **Save the note**: Click the downward arrow button, enter a name, and press Save
3. **Load a saved note**: Click on any note in the right sidebar
4. **Delete a note**: Click the trash icon next to the note name

## Build & Run

### Prerequisites

- Flutter SDK (latest stable version)
- Visual Studio 2022 with "Desktop development with C++" workload
- Windows 10 or 11

### Development

```bash
# Clone the repository
git clone https://github.com/DmytroVRX/VIRAZXfirsttool.git
cd virazx_quick_note

# Install dependencies
flutter pub get

# Run the app
flutter run -d windows
```

### Release Build

```bash
# Build for Windows
flutter build windows --release

# The executable will be in:
# build/windows/x64/runner/Release/
```

## Tech Stack

- **Flutter**: Cross-platform UI framework
- **bitsdojo_window**: Custom window frame
- **shared_preferences**: Local data storage
- **Material Design 3**: UI components

## License

MIT License
