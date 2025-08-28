import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/github_service.dart';
import '../services/project_selection_service.dart';
import '../services/logging_service.dart';
import '../screens/project_selection_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/auth_screen.dart';
import '../services/appwrite_auth_service.dart';

class AppFlowService {
  static Future<Widget> getInitialScreen(BuildContext context) async {
    LoggingService.debug('AppFlowService: Starting getInitialScreen...');
    try {
      final githubService = Provider.of<GitHubService>(context, listen: false);
      LoggingService.debug('AppFlowService: Got GitHubService instance');
      
      final projectSelectionService = Provider.of<ProjectSelectionService>(context, listen: false);
      LoggingService.debug('AppFlowService: Got ProjectSelectionService instance');
      
      // Check if user has a valid GitHub token
      LoggingService.debug('AppFlowService: Checking if user has valid GitHub token...');
      
      final hasValidToken = await githubService.hasValidToken();
      LoggingService.debug('AppFlowService: hasValidToken result: $hasValidToken');
      
      if (!hasValidToken) {
        LoggingService.info('AppFlowService: No valid token, returning AuthScreen');
        // No valid token, show auth screen
        return const AuthScreen();
      }
      
      // User has valid token, ensure Appwrite data exists
      LoggingService.debug('AppFlowService: User has valid token, ensuring Appwrite data exists...');
      try {
        final userData = await githubService.getAuthenticatedUser();
        if (userData != null) {
          final appwriteAuthService = Provider.of<AppwriteAuthService>(context, listen: false);
          await appwriteAuthService.ensureUserDataExists(
            githubUsername: userData['login'],
            githubUserId: userData['id'],
            email: userData['email'],
            displayName: userData['name'],
          );
          LoggingService.debug('AppFlowService: Appwrite data check completed');
        }
      } catch (e) {
        LoggingService.warning('AppFlowService: Error ensuring Appwrite data: $e');
      }
      
      LoggingService.debug('AppFlowService: User has valid token, checking setup status...');
      // Check if user has completed setup and has projects selected
      final shouldShowSetup = projectSelectionService.shouldShowSetupScreen();
      LoggingService.debug('AppFlowService: shouldShowSetup result: $shouldShowSetup');
      
      if (shouldShowSetup) {
        LoggingService.info('AppFlowService: User needs setup, returning ProjectSelectionScreen');
        // User needs to complete setup or has no projects selected
        return const ProjectSelectionScreen(isSetupMode: true);
      } else {
        LoggingService.success('AppFlowService: User setup complete, returning DashboardScreen');
        // User has completed setup and has projects, go to dashboard
        return const DashboardScreen();
      }
    } catch (e, stackTrace) {
      LoggingService.error('AppFlowService: Error in getInitialScreen: $e', e, stackTrace);
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
