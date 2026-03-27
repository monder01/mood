import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';

class LightInterface {
  static bool _isDialogShowing = false;

  static Widget page({
    String message = "جاري التحميل...",
    double size = 34,
    bool withScaffold = true,
    Color? backgroundColor,
  }) {
    final content = Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Colors.cyan[600],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );

    if (withScaffold) {
      return Scaffold(backgroundColor: backgroundColor, body: content);
    }

    return Container(
      color: backgroundColor ?? Colors.transparent,
      alignment: Alignment.center,
      child: content,
    );
  }

  static void showContainerLoading(
    BuildContext context, {
    String message = "جاري التحميل...",
    bool canPopLoading = false,
  }) async {
    if (_isDialogShowing) return;
    _isDialogShowing = true;

    await showDialog(
      context: context,
      barrierDismissible: canPopLoading,
      builder: (dialogContext) {
        return PopScope(
          canPop: canPopLoading,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.cyan[600],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    _isDialogShowing = false;
  }

  static void hideLoading(BuildContext context) {
    if (_isDialogShowing && Navigator.canPop(context)) {
      Navigator.pop(context);
      _isDialogShowing = false;
    }
  }

  Future<bool> undoBottomSheet(
    BuildContext context, {
    String message = "سيتم التنفيذ بعد",
    Duration duration = const Duration(seconds: 3),
  }) async {
    bool undone = false;

    final totalMs = duration.inMilliseconds;
    final progressNotifier = ValueNotifier<double>(1.0);

    final stopwatch = Stopwatch()..start();

    Timer? timer;
    timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      final elapsedMs = stopwatch.elapsedMilliseconds;
      final remaining = 1 - (elapsedMs / totalMs);

      if (remaining <= 0) {
        progressNotifier.value = 0;
        timer?.cancel();
      } else {
        progressNotifier.value = remaining;
      }
    });

    Future.delayed(duration, () {
      if (!undone && context.mounted) {
        Navigator.of(context).pop(false);
      }
    });

    final result = await showModalBottomSheet<bool>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      showDragHandle: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      sheetAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 250),
        reverseDuration: Duration(milliseconds: 200),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: ValueListenableBuilder<double>(
              valueListenable: progressNotifier,
              builder: (context, progress, _) {
                final secondsLeft = (progress * duration.inSeconds)
                    .ceil()
                    .clamp(0, duration.inSeconds);

                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 38,
                      height: 38,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 3,
                            color: Colors.cyan[600],
                          ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            child: Text(
                              "$secondsLeft",
                              key: ValueKey(secondsLeft),
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: () {
                        undone = true;
                        Navigator.of(sheetContext).pop(true);
                      },
                      child: Text(
                        "تراجع",
                        style: TextStyle(color: Colors.cyan[600]),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );

    timer.cancel();
    stopwatch.stop();
    progressNotifier.dispose();

    return result == true;
  }

  // save to clipboard
  void copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    showFlutterToast("تم النسخ الى الحافظة");
  }

  // call phone
  Future<void> callPhoneFun(
    BuildContext context, {
    required String phoneNumber,
  }) async {
    await launchUrl(Uri.parse('tel:$phoneNumber'));
  }

  // show toast
  void showFlutterToast(String message, {Color? color}) {
    Fluttertoast.showToast(
      gravity: ToastGravity.BOTTOM,
      backgroundColor: color ?? Colors.grey,
      textColor: Colors.white,
      msg: message,
    );
  }
}
