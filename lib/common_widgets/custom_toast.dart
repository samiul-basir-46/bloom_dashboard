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
    final context = NavigationService.navigatorKey.currentContext;
    if (context == null) return;

    final overlayState = Overlay.of(context);

    // Dismiss existing toast if showing
    dismiss();

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
          top: 24,
          right: 24,
          child: Material(
            color: Colors.transparent,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              tween: Tween<double>(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(50 * (1 - value), 0),
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: Container(
                width: 380,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B1E38),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: accentColor.withOpacity(0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: accentColor.withOpacity(0.15),
                      blurRadius: 12,
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        iconData,
                        color: accentColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
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
                                height: 1.3,
                              ),
                              maxLines: 3,
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
                            color: Colors.white.withOpacity(0.06),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white70,
                            size: 14,
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

    overlayState.insert(_currentOverlay!);

    _timer = Timer(duration, () {
      dismiss();
    });
  }

  static void dismiss() {
    _timer?.cancel();
    _timer = null;
    _currentOverlay?.remove();
    _currentOverlay = null;
  }
}

void customToastMessage(String title, String description, {WebToastType type = WebToastType.info}) {
  WebToast.show(title: title, description: description, type: type);
}