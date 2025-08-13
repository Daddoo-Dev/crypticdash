# CrypticDash Project Outline

## Project Overview

CrypticDash is a comprehensive dashboard application designed to help developers manage multiple GitHub projects efficiently. It provides a centralized interface for tracking project progress, managing todos, and monitoring repository activities.

## Core Features

### 1. Authentication & GitHub Integration
- **OAuth Authentication**: Secure GitHub login
- **Personal Access Token**: Alternative authentication method
- **Repository Access**: Fetch and manage user repositories
- **Token Persistence**: Remember authentication between sessions

### 2. Project Management
- **Repository Selection**: Choose which projects to monitor
- **Project Dashboard**: Overview of all selected projects
- **Progress Tracking**: Visual representation of project completion
- **Connection Status**: Monitor repository connectivity

### 3. Todo Management
- **Markdown Integration**: Parse and display TODO.md files
- **Task Status**: Track completion of individual tasks
- **Progress Calculation**: Automatic progress percentage
- **Local Storage**: Cache project data for offline access

### 4. User Experience
- **Theme Switching**: Light and dark theme support
- **Responsive Design**: Works across all device sizes
- **Search & Filter**: Find projects and tasks quickly
- **Cross-Platform**: Android, iOS, macOS, Windows, and Web

## Technical Architecture

### Frontend (Flutter)
- **State Management**: Provider pattern for app state
- **UI Components**: Custom widgets for project tiles and forms
- **Theme System**: Material Design 3 compliant theming
- **Navigation**: Screen-based navigation with proper routing

### Backend Services
- **GitHub API Service**: Repository and file management
- **Project Service**: Project data processing and storage
- **Theme Service**: Theme switching and persistence
- **Project Selection Service**: Repository filtering and selection

### Data Models
- **GitHubRepository**: Repository metadata and information
- **Project**: Project data with todos and progress
- **Todo**: Individual task items with completion status

## File Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
├── screens/                  # UI screens
├── services/                 # Business logic services
├── theme/                    # App theming
└── widgets/                  # Reusable UI components
```

## Development Status

### ✅ Completed
- Basic Flutter project structure
- GitHub authentication (OAuth + PAT)
- Project selection and management
- Theme switching (light/dark)
- Token persistence
- Cross-platform support

### 🚧 In Progress
- Todo parsing and management
- Project progress tracking
- UI/UX improvements

### 📋 Planned
- Advanced filtering and search
- Project analytics and insights
- Team collaboration features
- Notifications and alerts
- Export and reporting

## Getting Started

1. **Clone Repository**: `git clone https://github.com/yourusername/crypticdash.git`
2. **Install Dependencies**: `flutter pub get`
3. **Configure Environment**: Create `.env` file with GitHub token
4. **Run Application**: `flutter run`

## Contributing

We welcome contributions! Please see our contributing guidelines for more information on how to get involved in the project.

## License

This project is licensed under the MIT License.
