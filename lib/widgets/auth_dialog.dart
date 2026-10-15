import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/app_colors.dart';

// ════════════════════════════════════════════════════════════════
//  auth_dialog.dart  —  Reusable success/error dialog
//  Usage:
//    AuthDialog.show(context,
//      type: AuthDialogType.success,
//      title: 'Login Successful!',
//      message: 'Please wait...\nYou will be directed to the homepage.',
//      onDone: () => Navigator.pushReplacement(...),
//    );
// ════════════════════════════════════════════════════════════════

enum AuthDialogType { success, error }

class AuthDialog {
  static Future<void> show(
    BuildContext context, {
    required AuthDialogType type,
    required String title,
    required String message,
    VoidCallback? onDone,

    /// Auto-dismiss after this duration (only for success).
    /// Set null to disable auto-dismiss.
    Duration autoDismiss = const Duration(seconds: 3),
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (_) => _AuthDialogContent(
        type: type,
        title: title,
        message: message,
        onDone: onDone,
        autoDismiss: autoDismiss,
      ),
    );
  }
}

class _AuthDialogContent extends StatefulWidget {
  final AuthDialogType type;
  final String title;
  final String message;
  final VoidCallback? onDone;
  final Duration autoDismiss;

  const _AuthDialogContent({
    required this.type,
    required this.title,
    required this.message,
    required this.autoDismiss,
    this.onDone,
  });

  @override
  State<_AuthDialogContent> createState() => _AuthDialogContentState();
}

class _AuthDialogContentState extends State<_AuthDialogContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  bool _showSpinner = false;

  // Dot positions around the icon
  final List<_Dot> _dots = const [
    _Dot(top: 18, left: 30, size: 10, opacity: 1.0),
    _Dot(top: 24, right: 20, size: 6, opacity: 0.5),
    _Dot(top: 60, right: 10, size: 8, opacity: 0.7),
    _Dot(bottom: 20, left: 16, size: 7, opacity: 0.5),
    _Dot(bottom: 10, right: 40, size: 5, opacity: 0.4),
    _Dot(top: 80, left: 8, size: 5, opacity: 0.35),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();

    // Show spinner + auto-dismiss for success
    if (widget.type == AuthDialogType.success) {
      setState(() => _showSpinner = true);
      Future.delayed(widget.autoDismiss, () {
        if (mounted) {
          Navigator.of(context).pop();
          widget.onDone?.call();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _accentColor => widget.type == AuthDialogType.success
      ? const Color(0xFF2DB56A)
      : const Color(0xFFE53935);

  Color get _bgCircleColor => widget.type == AuthDialogType.success
      ? const Color(0xFF2DB56A)
      : const Color(0xFFE53935);

  IconData get _icon => widget.type == AuthDialogType.success
      ? Icons.lock_outline_rounded
      : Icons.error_outline_rounded;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Dialog(
          backgroundColor: context.appColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 36),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 36, 28, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Icon with decorative dots ─────────────────
                SizedBox(
                  height: 120,
                  width: 120,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      // Dots
                      for (final dot in _dots) _buildDot(dot),

                      // Main circle
                      Container(
                        height: 88,
                        width: 88,
                        decoration: BoxDecoration(
                          color: _bgCircleColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _bgCircleColor.withOpacity(0.35),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(
                          _icon,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Title ─────────────────────────────────────
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _accentColor,
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 12),

                // ── Message ───────────────────────────────────
                Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black.withOpacity(0.5),
                    height: 1.6,
                  ),
                ),

                const SizedBox(height: 28),

                // ── Spinner (success) or Close button (error) ─
                if (_showSpinner)
                  SizedBox(
                    height: 32,
                    width: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: _accentColor,
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onDone?.call();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Try Again',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDot(_Dot dot) {
    return Positioned(
      top: dot.top,
      bottom: dot.bottom,
      left: dot.left,
      right: dot.right,
      child: Container(
        height: dot.size,
        width: dot.size,
        decoration: BoxDecoration(
          color: _accentColor.withOpacity(dot.opacity),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _Dot {
  final double? top, bottom, left, right;
  final double size;
  final double opacity;

  const _Dot({
    this.top,
    this.bottom,
    this.left,
    this.right,
    this.size = 8,
    this.opacity = 0.6,
  });
}