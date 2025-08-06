// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:gramblin/src/router/app_router.dart';
// import 'package:gramblin/src/router/misc_routes/alert_dialog_screen.dart';
// import 'package:gramblin/src/router/misc_routes/dialog_parameters.dart';
// import 'package:gramblin/src/router/routes.dart';

// extension DialogRefExtension on Ref {
//   void updateDialogParameters({
//     required bool dismissible,
//     required String title,
//     required String content,
//     bool onlyConfirm = false,
//     Icon? icon,
//     String cancelLabel = 'Cancel',
//     String confirmLabel = 'Confirm',
//     VoidCallback? onConfirm,
//     VoidCallback? onCancel,
//   }) {
//     final navigatorKeyContext = rootNavigatorKey.currentContext;
//     if (navigatorKeyContext == null) return;

//     read(dialogParametersProvider.notifier).update(
//       (state) => DialogParameters(
//         dismissible: dismissible,
//         title: title,
//         content: content,
//         cancelLabel: cancelLabel,
//         confirmLabel: confirmLabel,
//         onCancel: onCancel ?? read(routerProvider).pop,
//         onConfirm: onConfirm ?? read(routerProvider).pop,
//         icon: icon,
//         onlyConfirm: onlyConfirm,
//       ),
//     );
//     const InfoDialogRoute().push<void>(navigatorKeyContext);
//   }
// }

// extension DialogWidgetRefExtension on WidgetRef {
//   void showInfoDialog({
//     required bool dismissible,
//     required String title,
//     required String content,
//     Icon? icon,
//     String cancelLabel = 'Cancel',
//     String confirmLabel = 'Confirm',
//     VoidCallback? onConfirm,
//     VoidCallback? onCancel,
//   }) {
//     final navigatorKeyContext = rootNavigatorKey.currentContext;
//     if (navigatorKeyContext == null) return;

//     read(dialogParametersProvider.notifier).update(
//       (state) => DialogParameters(
//         dismissible: dismissible,
//         title: title,
//         content: content,
//         cancelLabel: cancelLabel,
//         confirmLabel: confirmLabel,
//         onCancel: onCancel ?? read(routerProvider).pop,
//         onConfirm: onConfirm ?? read(routerProvider).pop,
//         icon: icon,
//         onlyConfirm: false,
//       ),
//     );
//     const InfoDialogRoute().push<void>(navigatorKeyContext);
//   }
// }
