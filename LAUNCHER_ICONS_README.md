# Launcher Icons for CrypticDash

This app supports both light and dark themes with different logos and launcher icons.

## Logo Assets

- **Light Theme**: `assets/images/crypticdash.png`
- **Dark Theme**: `assets/images/crypticdashdark.png`

## Generating Launcher Icons

### Light Theme Icons (Default)
```bash
flutter pub run flutter_launcher_icons:main
```

### Dark Theme Icons
```bash
flutter pub run flutter_launcher_icons:main -f pubspec_dark.yaml
```

## What Gets Generated

### Light Theme
- Android: `android/app/src/main/res/mipmap-*/launcher_icon.png`
- iOS: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- Web: `web/icons/Icon-*.png`
- Windows: `windows/runner/resources/app_icon.ico`
- macOS: `macos/Runner/Assets.xcassets/AppIcon.appiconset/`

### Dark Theme
- Android: `android/app/src/main/res/mipmap-*/launcher_icon_dark.png`
- iOS: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- Web: `web/icons/Icon-*.png`
- Windows: `windows/runner/resources/app_icon.ico`
- macOS: `macos/Runner/Assets.xcassets/AppIcon.appiconset/`

## Theme-Aware Features

The app automatically switches between logos based on the selected theme:

- **Light Theme**: Shows `crypticdash.png` logo
- **Dark Theme**: Shows `crypticdashdark.png` logo
- **System Theme**: Automatically chooses based on device theme

## App Names by Theme

- **Light Theme**: "CrypticDash"
- **Dark Theme**: "CrypticDash Dark"
- **System Theme**: Automatically chooses based on device theme

## Notes

- The launcher icons are static and don't change with theme
- Only the in-app logos and text change dynamically
- To change launcher icons, you need to regenerate them and reinstall the app
- Web and desktop platforms will use the appropriate icon based on the current theme
