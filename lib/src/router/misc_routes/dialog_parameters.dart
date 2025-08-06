import 'package:flutter/widgets.dart';

class DialogParameters {
  DialogParameters({
    required this.title,
    required this.content,
    this.icon,
    this.dismissible = true,
    this.cancelLabel,
    this.confirmLabel,
    this.onCancel,
    this.onConfirm,
    this.onlyConfirm,
  });

  final bool dismissible;
  final String title;
  final String content;
  final String? cancelLabel;
  final String? confirmLabel;
  final Icon? icon;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool? onlyConfirm;
}
