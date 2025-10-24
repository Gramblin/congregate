import 'package:logger/web.dart';

final logger = Logger(
  printer: PrettyPrinter(
    dateTimeFormat: (time) => '',
    noBoxingByDefault: true,
    methodCount: 0,
    errorMethodCount: 0,
  ),
);
