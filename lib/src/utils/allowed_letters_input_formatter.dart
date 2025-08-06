import 'package:flutter/services.dart';

class AllowedLettersInputFormatter extends TextInputFormatter {
  AllowedLettersInputFormatter({required this.allowedLetters});
  final String allowedLetters;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.length < oldValue.text.length) {
      return newValue;
    }

    if (newValue.text.isEmpty) {
      return newValue;
    }

    if (oldValue.text.length < newValue.text.length) {
      final newChar = newValue.text[newValue.text.length - 1].toUpperCase();

      if (!allowedLetters.toUpperCase().contains(newChar)) {
        return oldValue;
      }
    }

    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: TextSelection.collapsed(offset: newValue.text.length),
    );
  }
}
