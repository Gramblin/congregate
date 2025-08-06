import 'dart:math' as math;
import 'dart:ui';

bool validateEmailAdress(String input, String regExp) {
  if (RegExp(regExp).hasMatch(input)) {
    return true;
  } else {
    return false;
  }
}

Color getRandomBrightColor() {
  final random = math.Random();
  const minBrightness = 100;
  return Color.fromARGB(
    255,
    minBrightness + random.nextInt(256 - minBrightness),
    minBrightness + random.nextInt(256 - minBrightness),
    minBrightness + random.nextInt(256 - minBrightness),
  );
}

double degreesToRadians(double degrees) => degrees * (3.1415926535 / 180);
