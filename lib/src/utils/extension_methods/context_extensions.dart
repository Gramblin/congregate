import 'package:congregate/src/constants/app_sizes.dart';
import 'package:congregate/src/utils/extension_methods/string_extensions.dart';
import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

enum SuccessTypeEnum { success, neutral, error }

extension ContextExtensions on BuildContext {
  void showSnackbar(String content) {
    ScaffoldMessenger.of(this).showSnackBar(SnackBar(content: Text(content)));
  }

  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  bool get isDark => Theme.of(this).colorScheme.brightness == Brightness.dark;
  Size get size => MediaQuery.of(this).size;

  void showInformationToast(
    String text, {
    SuccessTypeEnum error = SuccessTypeEnum.success,
    bool autoDismiss = false,
    IconData? icon,
  }) {
    DelightToastBar(
      snackbarDuration: const Duration(milliseconds: 3000),
      autoDismiss: autoDismiss,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(Sizes.p16),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Sizes.p12,
              vertical: Sizes.p16,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Sizes.p10),
              border: Border.all(width: 2),
            ),
            child: Row(
              children: [
                if (icon != null) Icon(icon),
                gapW16,
                SelectableText(
                  error == SuccessTypeEnum.error
                      ? text
                            .removeExceptionTraces()
                            .removeExceptionPrefix()
                            .trim()
                            .capitalizeFirstLetter()
                      : text,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: Sizes.p16,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).show(this);
  }

  void showJoinRoomToast(String roomId) {
    DelightToastBar(
      builder: (context) => ToastCard(
        color: context.colorScheme.errorContainer,
        subtitle: const SelectableText(
          'X Person is calling you to join their game, accept?',
        ),
        leading: Icon(
          MdiIcons.emoticonExcitedOutline,
          color: context.colorScheme.onErrorContainer,
        ),
        title: SelectableText(
          'You got an invitation to room $roomId.',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: Sizes.p14,
            color: context.colorScheme.onErrorContainer,
          ),
        ),
        trailing: OutlinedButton(
          onPressed: DelightToastBar.removeAll,
          child: SelectableText('Join'.hardcoded),
        ),
      ),
    ).show(this);
  }
}
