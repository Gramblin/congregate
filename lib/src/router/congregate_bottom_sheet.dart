import 'package:congregate/src/constants/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

class CongregateBottomSheet extends StatelessWidget {
  const CongregateBottomSheet({
    this.title,
    this.description,
    this.children = const [],
    this.headerIcon,
    this.headerWidget,
    this.iconDelay = 200,
    this.titleDelay = 250,
    this.descriptionDelay = 400,
    super.key,
  }) : assert(
         headerIcon == null || headerWidget == null,
         'Cannot provide both headerIcon and headerWidget',
       );

  final String? title;
  final String? description;
  final List<Widget> children;
  final IconData? headerIcon;
  final Widget? headerWidget;
  final int iconDelay;
  final int titleDelay;
  final int descriptionDelay;

  @override
  Widget build(BuildContext context) {
    return Sheet(
      scrollConfiguration: const SheetScrollConfiguration(),
      decoration: const MaterialSheetDecoration(
        size: SheetSize.stretch,
        // color: GramblinColors.lighterWhite,
        // shadowColor: GramblinColors.lighterWhite,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Sizes.p32)),
        ),
      ),
      child: SheetContentScaffold(
        bottomBarVisibility: const BottomBarVisibility.always(
          ignoreBottomInset: true,
        ),
        // backgroundColor: GramblinColors.lighterWhite,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(Sizes.p16),
          child: Column(
            children: [
              Divider(
                thickness: Sizes.p8,
                radius: BorderRadius.circular(Sizes.p10),
                height: Sizes.p6,
                color: Colors.black38,
                endIndent: 160,
                indent: 160,
              ),
              gapH24,
              if (headerIcon != null)
                // CircledAccentIcon(
                //   iconData: headerIcon!,
                // ).animate().scale(
                //   delay: Duration(milliseconds: iconDelay),
                //   curve: Curves.elasticOut,
                //   duration: const Duration(milliseconds: 400),
                // )
                // else
                //   ?headerWidget,
                if (headerIcon != null || headerWidget != null) gapH8,
              if (title != null)
                Text(
                  title!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: Sizes.p32,
                  ),
                  textAlign: TextAlign.center,
                ),
              // .animate().fadeIn(delay: Duration(milliseconds: titleDelay)),
              if (title != null) gapH16,
              if (description != null)
                Text(
                  description!,
                ),
              // .animate().fadeIn(
              //   delay: Duration(milliseconds: descriptionDelay),
              // ),
              if (description != null) gapH16,
              ...children,
              gapH32,
            ],
          ),
        ),
      ),
    );
  }
}
