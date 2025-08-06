import 'package:congregate/src/utils/extension_methods/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class GramblinServices {
  static Future<void> copyToClipboard(
    BuildContext context, {
    required String text,
    String? customToastMessage,
  }) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;

    context.showInformationToast(
      customToastMessage ?? 'Copied $text to clipboard!',
      autoDismiss: true,
    );
  }

  static Future<ShareResult> share({
    required String text,
    String? clipboardTitle,
  }) async =>
      SharePlus.instance.share(ShareParams(title: clipboardTitle, text: text));
}
