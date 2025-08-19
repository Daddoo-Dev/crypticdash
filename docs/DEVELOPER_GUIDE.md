# 👨‍💻 CrypticDash Developer Guide

This guide is for developers who want to understand, contribute to, or extend CrypticDash.

## 🏗️ Architecture Overview

### Project Structure
```
lib/
├── main.dart                 # App entry point and initialization
├── models/                   # Data models and entities
├── screens/                  # UI screens and pages
├── services/                 # Business logic and external APIs
├── theme/                    # App theming and styling
└── widgets/                  # Reusable UI components
```

### State Management
- **Provider Pattern**: Used throughout the app for state management
- **Service Layer**: Business logic separated from UI
- **Model Classes**: Immutable data structures with copyWith methods

## 🔧 Core Services

### GitHubService
**Location**: `lib/services/github_service.dart`

**Purpose**: Handles all GitHub API interactions

**Key Methods**:
```dart
// Authentication
Future<bool> testConnection()
Future<List<GitHubRepository>> getUserRepositories()

// File Operations
Future<String?> getFileContent(String owner, String repo, String path)
Future<bool> createOrUpdateFile(String owner, String repo, String path, String content, String message, {String? sha})
Future<String?> getFileSha(String owner, String repo, String path)
```

**Usage Example**:
```dart
final githubService = Provider.of<GitHubService>(context, listen: false);
final repos = await githubService.getUserRepositories();
```

### ProjectService
**Location**: `lib/services/project_service.dart`

**Purpose**: Manages project data and operations

**Key Methods**:
```dart
Future<void> loadProjects()
List<Project> searchProjects(String query)
void notifyListeners()
```

**Usage Example**:
```dart
final projectService = Provider.of<ProjectService>(context, listen: false);
await projectService.loadProjects();
```

### ONNXAIService
**Location**: `lib/services/onnx_ai_service.dart`

**Purpose**: AI-powered project analysis and TODO generation

**Key Methods**:
```dart
Future<String> generateProjectAnalysis(Project project, String analysisType)
Future<String> generatePrioritizedNextSteps(Project project)
String _detectProjectType(List<String> files)
```

## 📱 UI Components

### ProjectTile
**Location**: `lib/widgets/project_tile.dart`

**Purpose**: Displays project information in dashboard grid

**Props**:
- `Project project`: Project data to display
- `VoidCallback onTap`: Tap handler
- `VoidCallback onRefresh`: Refresh handler

**Usage Example**:
```dart
ProjectTile(
  project: project,
  onTap: () => _openProjectDetails(project),
  onRefresh: () => _loadProjects(),
)
```

### AddProjectDialog
**Location**: `lib/widgets/add_project_dialog.dart`

**Purpose**: Dialog for adding new projects

**Features**:
- Repository selection from GitHub
- Automatic filtering of writable repos
- Integration with ProjectSelectionService

### SimpleAIWidget
**Location**: `lib/widgets/simple_ai_widget.dart`

**Purpose**: AI analysis interface for projects

**Features**:
- Multiple analysis types
- Progress indicators
- Error handling

## 🎨 Theming System

### AppThemes
**Location**: `lib/theme/app_themes.dart`

**Purpose**: Centralized theme definitions

**Key Components**:
```dart
// Text Styles
static const TextStyle headlineLarge = TextStyle(...)
static const TextStyle titleMedium = TextStyle(...)
static const TextStyle bodyMedium = TextStyle(...)

// Colors
static const Color primaryBlue = Color(0xFF2196F3)
static const Color successGreen = Color(0xFF4CAF50)
static const Color errorRed = Color(0xFFF44336)

// Button Styles
static final ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(...)
static final ButtonStyle secondaryButtonStyle = OutlinedButton.styleFrom(...)
```

### ThemeService
**Location**: `lib/services/theme_service.dart`

**Purpose**: Manages theme switching and persistence

**Key Methods**:
```dart
bool get isDarkMode
Future<void> toggleTheme()
Future<void> setTheme(bool isDark)
```

## 📊 Data Models

### Project
**Location**: `lib/models/project.dart`

**Properties**:
```dart
class Project {
  final String id
  final String name
  final String owner
  final String repoName
  final List<Todo> todos
  final DateTime lastUpdated
  final bool isConnected
  final double progress
}
```

**Key Methods**:
```dart
Project copyWith({...})
Map<String, dynamic> toJson()
factory Project.fromJson(Map<String, dynamic> json)
```

### Todo
**Location**: `lib/models/todo.dart`

**Properties**:
```dart
class Todo {
  final String id
  final String title
  final String? notes
  final String? section
  final bool isCompleted
  final DateTime createdAt
}
```

## 🔌 Service Integration

### Provider Setup
**Location**: `lib/main.dart`

**Configuration**:
```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => ThemeService()),
    ChangeNotifierProvider(create: (_) => ProjectService()),
    ChangeNotifierProvider(create: (_) => ProjectSelectionService()),
    Provider(create: (_) => GitHubService()),
    Provider(create: (_) => MarkdownService()),
    Provider(create: (_) => ONNXAIService()),
  ],
  child: MyApp(),
)
```

### Service Dependencies
- **GitHubService**: No dependencies
- **ProjectService**: Depends on GitHubService
- **ProjectSelectionService**: Depends on GitHubService
- **ThemeService**: No dependencies
- **ONNXAIService**: No dependencies

## 🚀 Adding New Features

### 1. Create the Feature
- Add new service methods if needed
- Create UI components in appropriate directories
- Follow existing naming conventions

### 2. Update State Management
- Add new providers if needed
- Update existing services if required
- Ensure proper error handling

### 3. Add to UI
- Integrate with existing screens
- Follow Material Design 3 guidelines
- Use AppThemes for consistent styling

### 4. Testing
- Add unit tests for new services
- Add widget tests for new components
- Test on multiple platforms

## 🧪 Testing

### Running Tests
```bash
# Unit tests
flutter test

# Specific test file
flutter test test/unit_test.dart

# With coverage
flutter test --coverage
```

### Test Structure
```
test/
├── unit_test.dart           # Unit tests
└── widget_test.dart         # Widget tests
```

## 📱 Platform Support

### Supported Platforms
- **Android**: API 21+ (Android 5.0+)
- **iOS**: iOS 11.0+
- **Web**: Modern browsers
- **Windows**: Windows 10+
- **macOS**: macOS 10.14+
- **Linux**: Ubuntu 18.04+

### Platform-Specific Code
- **Conditional Imports**: Use `dart:io` for platform detection
- **Platform Channels**: For native functionality
- **Responsive Design**: Adapts to different screen sizes

## 🔒 Security Considerations

### API Key Storage
- **Local Storage**: Keys stored locally on device
- **Encryption**: Sensitive data encrypted before storage
- **No Cloud Sync**: Keys never leave the device

### GitHub Permissions
- **Minimal Scope**: Only requested permissions are used
- **User Consent**: Clear permission requests
- **Token Validation**: Verify token permissions on startup

## 📈 Performance

### Optimization Strategies
- **Lazy Loading**: Load data only when needed
- **Caching**: Cache project data locally
- **Debouncing**: Limit API calls during search
- **Background Sync**: Update data in background

### Memory Management
- **Dispose Controllers**: Properly dispose TextEditingController
- **Image Caching**: Efficient image loading
- **List Optimization**: Use ListView.builder for large lists

## 🐛 Debugging

### Common Issues

#### Build Errors
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

#### Runtime Errors
- Check console logs
- Use Flutter Inspector
- Verify service dependencies

#### Platform-Specific Issues
- Test on target platform
- Check platform permissions
- Verify platform dependencies

### Debug Tools
- **Flutter Inspector**: Widget tree inspection
- **Performance Overlay**: Frame rate monitoring
- **Debug Console**: Log output and errors

## 📚 Contributing

### Code Style
- **Dart Format**: Use `dart format` for consistent formatting
- **Linting**: Follow `analysis_options.yaml` rules
- **Comments**: Document complex logic
- **Naming**: Use descriptive names

### Pull Request Process
1. **Fork** the repository
2. **Create** feature branch
3. **Implement** changes
4. **Test** thoroughly
5. **Submit** pull request

### Commit Messages
- Use present tense
- Be descriptive
- Reference issues when applicable

## 🔮 Future Enhancements

### Planned Features
- **Team Collaboration**: Multi-user support
- **Advanced Analytics**: Detailed project metrics
- **Integration APIs**: Connect with other tools
- **Mobile Notifications**: Push notifications

### Architecture Improvements
- **State Management**: Consider Riverpod or Bloc
- **Testing**: Increase test coverage
- **Documentation**: Auto-generated API docs
- **CI/CD**: Automated testing and deployment

---

**Questions?** Check the GitHub repository issues or create a new one for support.
