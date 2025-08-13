import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/github_service.dart';
import '../services/project_selection_service.dart';
import '../screens/project_selection_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/auth_screen.dart';

class AppFlowService {
  static Future<Widget> getInitialScreen(BuildContext context) async {
    try {
      final githubService = Provider.of<GitHubService>(context, listen: false);
      final projectSelectionService = Provider.of<ProjectSelectionService>(context, listen: false);
      
      // Check if user has a valid GitHub token
      final hasValidToken = await githubService.hasValidToken();
      
      if (!hasValidToken) {
        // No valid token, show auth screen
        return const AuthScreen();
      }
      
      // Check if user has completed setup and has projects selected
      if (projectSelectionService.shouldShowSetupScreen()) {
        // User needs to complete setup or has no projects selected
        return const ProjectSelectionScreen(isSetupMode: true);
      } else {
        // User has completed setup and has projects, go to dashboard
        return const DashboardScreen();
      }
    } catch (e) {
      // If there's an error, default to auth screen
      return const AuthScreen();
    }
  }
  
  static Future<Widget> getNextScreenAfterAuth(BuildContext context) async {
    try {
      final projectSelectionService = Provider.of<ProjectSelectionService>(context, listen: false);
      
      // Check if user has completed setup and has projects selected
      if (projectSelectionService.shouldShowSetupScreen()) {
        // User needs to complete setup or has no projects selected
        return const ProjectSelectionScreen(isSetupMode: true);
      } else {
        // User has completed setup and has projects, go to dashboard
        return const DashboardScreen();
      }
    } catch (e) {
      // If there's an error, default to project selection
      return const ProjectSelectionScreen(isSetupMode: true);
    }
  }
}
