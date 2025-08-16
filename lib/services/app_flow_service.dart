import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/github_service.dart';
import '../services/project_selection_service.dart';
import '../screens/project_selection_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/auth_screen.dart';

class AppFlowService {
  static Future<Widget> getInitialScreen(BuildContext context) async {
    print('AppFlowService: Starting getInitialScreen...');
    try {
      final githubService = Provider.of<GitHubService>(context, listen: false);
      print('AppFlowService: Got GitHubService instance');
      
      final projectSelectionService = Provider.of<ProjectSelectionService>(context, listen: false);
      print('AppFlowService: Got ProjectSelectionService instance');
      
      // Check if user has a valid GitHub token
      print('AppFlowService: Checking if user has valid GitHub token...');
      final hasValidToken = await githubService.hasValidToken();
      print('AppFlowService: hasValidToken result: $hasValidToken');
      
      if (!hasValidToken) {
        print('AppFlowService: No valid token, returning AuthScreen');
        // No valid token, show auth screen
        return const AuthScreen();
      }
      
      print('AppFlowService: User has valid token, checking setup status...');
      // Check if user has completed setup and has projects selected
      final shouldShowSetup = projectSelectionService.shouldShowSetupScreen();
      print('AppFlowService: shouldShowSetup result: $shouldShowSetup');
      
      if (shouldShowSetup) {
        print('AppFlowService: User needs setup, returning ProjectSelectionScreen');
        // User needs to complete setup or has no projects selected
        return const ProjectSelectionScreen(isSetupMode: true);
      } else {
        print('AppFlowService: User setup complete, returning DashboardScreen');
        // User has completed setup and has projects, go to dashboard
        return const DashboardScreen();
      }
    } catch (e, stackTrace) {
      print('AppFlowService: Error in getInitialScreen: $e');
      print('AppFlowService: Stack trace: $stackTrace');
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
