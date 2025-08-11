import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/github_service.dart';
import 'services/project_service.dart';
import 'theme/app_themes.dart';
import 'screens/auth_screen.dart';

void main() {
  runApp(const DevDashApp());
}

class DevDashApp extends StatelessWidget {
  const DevDashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => GitHubService(),
        ),
        ChangeNotifierProxyProvider<GitHubService, ProjectService>(
          create: (context) => ProjectService(
            Provider.of<GitHubService>(context, listen: false),
          ),
          update: (context, githubService, previous) => 
            previous ?? ProjectService(githubService),
        ),
      ],
      child: MaterialApp(
        title: 'Dev Dash',
        debugShowCheckedModeBanner: false,
        theme: AppThemes.lightTheme,
        darkTheme: AppThemes.darkTheme,
        themeMode: ThemeMode.system,
        home: const AuthScreen(),
      ),
    );
  }
}
