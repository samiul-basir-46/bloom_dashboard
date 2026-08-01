import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../helpers/navigation_service.dart';

enum WebToastType { success, error, info, warning }

class WebToast {
  static OverlayEntry? _currentOverlay;
  static Timer? _timer;

  static void show({
    required String title,
    required String description,
    WebToastType type = WebToastType.info,
    Duration duration = const Duration(seconds: 4),
  }) {
    // Dismiss existing toast safely first
    dismiss();

    // Retrieve the Root Overlay state so toasts survive page switches & route changes
    final overlayState = NavigationService.navigatorKey.currentState?.overlay ??
        (NavigationService.navigatorKey.currentContext != null
            ? Overlay.of(NavigationService.navigatorKey.currentContext!, rootOverlay: true)
            : null);

    if (overlayState == null) return;

    Color accentColor;
    IconData iconData;

    switch (type) {
      case WebToastType.success:
        accentColor = const Color(0xFF10B981); // Emerald Green
        iconData = Icons.check_circle_rounded;
        break;
      case WebToastType.error:
        accentColor = const Color(0xFFEF4444); // Crimson Red
        iconData = Icons.error_rounded;
        break;
      case WebToastType.warning:
        accentColor = const Color(0xFFF59E0B); // Amber
        iconData = Icons.warning_amber_rounded;
        break;
      case WebToastType.info:
      default:
        accentColor = const Color(0xFF3B82F6); // Royal Blue
        iconData = Icons.info_rounded;
        break;
    }

    _currentOverlay = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: 30,
          right: 30,
          child: Material(
            type: MaterialType.transparency,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutBack,
              tween: Tween<double>(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(60 * (1 - value), 0),
                  child: Opacity(
                    opacity: value.clamp(0.0, 1.0),
                    child: child,
                  ),
                );
              },
              child: Container(
                width: 380,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B1E38),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: accentColor,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.2),
                      blurRadius: 16,
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        iconData,
                        color: accentColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              description,
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                color: Colors.white70,
                                height: 1.35,
                              ),
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: dismiss,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white70,
                            size: 16,
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
      },
    );

    try {
      overlayState.insert(_currentOverlay!);
    } catch (_) {}

    _timer = Timer(duration, () {
      dismiss();
    });
  }

  static void dismiss() {
    _timer?.cancel();
    _timer = null;
    if (_currentOverlay != null) {
      try {
        _currentOverlay!.remove();
      } catch (_) {}
      _currentOverlay = null;
    }
  }
}

void customToastMessage(String title, String description, {WebToastType type = WebToastType.info}) {
  WebToast.show(title: title, description: description, type: type);
}