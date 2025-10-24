// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
// import 'package:suffah/src/common/material/wide_flat_button.dart';
// import 'package:suffah/src/common/material/wide_outlined_button.dart';
// import 'package:suffah/src/constants/app_sizes.dart';
// import 'package:suffah/src/constants/suffah_colors.dart';
// import 'package:suffah/src/router/misc_routes/dialog_parameters.dart';
// import 'package:suffah/src/utils/extension_methods/string_extensions.dart';

// final dialogParametersProvider = StateProvider<DialogParameters>(
//   (ref) => DialogParameters(title: '', content: ''),
// );

// class SuffahDialogScreen extends ConsumerWidget {
//   const SuffahDialogScreen({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final dialog = ref.watch(dialogParametersProvider);

//     return Padding(
//       padding: const EdgeInsets.symmetric(
//         horizontal: Sizes.p20,
//         vertical: Sizes.p20,
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           // dialog.icon ?? const SizedBox.shrink(),
//           FittedBox(
//             child: SelectableText(
//               dialog.title.capitalize(),
//               style: const TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: Sizes.p20,
//               ),
//             ),
//           ),
//           gapH16,
//           Flexible(
//             child: SingleChildScrollView(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisSize: MainAxisSize.min,
//                 children: [SelectableText(dialog.content)],
//               ),
//             ),
//           ),
//           gapH16,
//           Row(
//             children: [
//               if (dialog.onlyConfirm ?? false)
//                 Expanded(
//                   child: WideOutlinedButton(
//                     onTap: dialog.onConfirm ?? context.pop,
//                     foregroundColor: SuffahColors.lighterGreen,
//                     child: Expanded(
//                       child: Text(
//                         dialog.confirmLabel ?? 'OK'.hardcoded,
//                         textAlign: TextAlign.center,
//                         style: TextStyle(
//                           color: SuffahColors.lighterGreen,
//                           fontWeight: FontWeight.w500,
//                           fontSize: Sizes.p16,
//                         ),
//                       ),
//                     ),
//                   ),
//                 )
//               else ...[
//                 Expanded(
//                   child: WideOutlinedButton(
//                     onTap: dialog.onConfirm ?? context.pop,
//                     foregroundColor: SuffahColors.lighterGreen,
//                     child: Expanded(
//                       child: Text(
//                         dialog.confirmLabel ?? 'OK'.hardcoded,
//                         textAlign: TextAlign.center,
//                         style: TextStyle(
//                           color: SuffahColors.lighterGreen,
//                           fontWeight: FontWeight.w500,
//                           fontSize: Sizes.p16,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//                 gapW16,
//                 Expanded(
//                   child: WideFlatButton(
//                     backgroundColor: SuffahColors.alertDialogPositiveColor,
//                     foregroundColor: Colors.white,
//                     onTap: dialog.onCancel ?? context.pop,
//                     child: Expanded(
//                       child: Text(
//                         dialog.cancelLabel ?? 'Cancel'.hardcoded,
//                         textAlign: TextAlign.center,
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontWeight: FontWeight.w500,
//                           fontSize: Sizes.p16,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
