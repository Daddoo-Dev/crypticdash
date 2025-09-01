import 'package:flutter/material.dart';
import 'package:image_sequence_animator/image_sequence_animator.dart';
import '../theme/app_themes.dart';

class YetiLoadingWidget extends StatefulWidget {
  final String message;
  final bool isVisible;

  const YetiLoadingWidget({
    super.key,
    required this.message,
    this.isVisible = true,
  });

  @override
  State<YetiLoadingWidget> createState() => _YetiLoadingWidgetState();
}

class _YetiLoadingWidgetState extends State<YetiLoadingWidget>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    if (widget.isVisible) {
      _fadeController.forward();
    }
  }

  @override
  void didUpdateWidget(YetiLoadingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _fadeController.forward();
      } else {
        _fadeController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
                        color: AppThemes.primaryBlue.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
                         color: AppThemes.primaryBlue.withValues(alpha: 0.2),
            width: 1.0,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Yeti Animation
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(60),
                                 color: AppThemes.primaryBlue.withValues(alpha: 0.1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(60),
                child: ImageSequenceAnimator(
                  "assets/yeti_animation", // folder path
                  "yeti_frame_",           // base name
                  1,                       // suffix start
                  1,                       // suffix count
                  "png",                   // file format
                  4.0,                     // number of frames
                  fps: 2,                  // frames per second
                  isLooping: true,
                  isAutoPlay: true,
                  onReadyToPlay: (state) => debugPrint("Yeti animation ready!"),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Loading Message
            Text(
              widget.message,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppThemes.primaryBlue,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            // Subtitle
            Text(
              'The yeti is analyzing your repository...',
              style: TextStyle(
                fontSize: 14,
                                 color: AppThemes.primaryBlue.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
