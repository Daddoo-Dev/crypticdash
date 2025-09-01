import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/github_service.dart';
import '../services/project_selection_service.dart';
import 'package:logger/logger.dart';
import '../screens/project_selection_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/auth_screen.dart';
import '../services/stripe_user_service.dart';

class AppFlowService {
  static final _logger = Logger();
  
  static Future<Widget> getInitialScreen(BuildContext context) async {
    _logger.d('AppFlowService: Starting getInitialScreen...');
    try {
      final githubService = Provider.of<GitHubService>(context, listen: false);
      _logger.d('AppFlowService: Got GitHubService instance');
      
      final projectSelectionService = Provider.of<ProjectSelectionService>(context, listen: false);
      _logger.d('AppFlowService: Got ProjectSelectionService instance');
      
      final stripeUserService = Provider.of<StripeUserService>(context, listen: false);
      _logger.d('AppFlowService: Got StripeUserService instance');
      
      // Check if user has a valid GitHub token
      _logger.d('AppFlowService: Checking if user has valid GitHub token...');
      
      final hasValidToken = await githubService.hasValidToken();
      _logger.d('AppFlowService: hasValidToken result: $hasValidToken');
      
      if (!hasValidToken) {
        _logger.i('AppFlowService: No valid token, returning AuthScreen');
        // No valid token, show auth screen
        return const AuthScreen();
      }
      
      // User has valid token, ensure Stripe data exists
      _logger.d('AppFlowService: User has valid token, ensuring Stripe data exists...');
      try {
        final userData = await githubService.getAuthenticatedUser();
        if (userData != null) {
          await stripeUserService.ensureUserDataExists(
            githubUsername: userData['login'],
            githubUserId: userData['id'],
            email: userData['email'],
            displayName: userData['name'],
          );
          _logger.d('AppFlowService: Stripe data check completed');
        }
      } catch (e) {
        _logger.w('AppFlowService: Error ensuring Stripe data: $e');
      }
      
      _logger.d('AppFlowService: User has valid token, checking setup status...');
      // Check if user has completed setup and has projects selected
      final shouldShowSetup = projectSelectionService.shouldShowSetupScreen();
      _logger.d('AppFlowService: shouldShowSetup result: $shouldShowSetup');
      
      if (shouldShowSetup) {
        _logger.i('AppFlowService: User needs setup, returning ProjectSelectionScreen');
        // User needs to complete setup or has no projects selected
        return const ProjectSelectionScreen(isSetupMode: true);
      } else {
        _logger.i('AppFlowService: User setup complete, returning DashboardScreen');
        // User has completed setup and has projects, go to dashboard
        return const DashboardScreen();
      }
    } catch (e, stackTrace) {
      _logger.e('AppFlowService: Error in getInitialScreen: $e', error: e, stackTrace: stackTrace);
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
