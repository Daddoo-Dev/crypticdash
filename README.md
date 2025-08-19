# CrypticDash

A dynamic dashboard for managing multiple GitHub projects with integrated todo lists and progress tracking.

## Features

- **GitHub Integration**: Connect and manage multiple repositories
- **Project Selection**: Choose which repositories to monitor
- **Todo Management**: Track tasks and progress across projects
- **Theme Support**: Light and dark theme switching
- **Cross-Platform**: Works on Android, iOS, macOS, Windows, and Web

## Getting Started

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK (3.0.0 or higher)
- GitHub Personal Access Token

### 📚 Documentation

- **[User Guide](docs/USER_GUIDE.md)** - Complete guide to using CrypticDash
- **[FAQ](docs/FAQ.md)** - Quick answers to common questions
- **[Troubleshooting](docs/TROUBLESHOOTING.md)** - Solve problems and issues
- **[Developer Guide](docs/DEVELOPER_GUIDE.md)** - Technical documentation
- **[Documentation Index](docs/README.md)** - All documentation in one place

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/crypticdash.git
   cd crypticdash
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Create a `.env` file in the root directory with your GitHub token:
   ```
   GITHUB_TOKEN=your_github_personal_access_token_here
   ```

4. Run the app:
   ```bash
   flutter run
   ```

## Usage

1. **Authentication**: Sign in with GitHub using OAuth or Personal Access Token
2. **Project Selection**: Choose which repositories to monitor
3. **Dashboard**: View project progress, todos, and statistics
4. **Theme Toggle**: Switch between light and dark themes

## Building

### Android
```bash
flutter build apk
```

### iOS
```bash
flutter build ios
```

### macOS
```bash
flutter build macos
```

### Windows
```bash
flutter build windows
```

### Web
```bash
flutter build web
```

## Launcher Icons

The app includes both light and dark theme launcher icons:

### Light Theme Icons
```bash
dart run flutter_launcher_icons:main
```

### Dark Theme Icons
```bash
dart run flutter_launcher_icons:main -f pubspec_dark.yaml
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Flutter team for the amazing framework
- GitHub for the API
- All contributors and supporters
