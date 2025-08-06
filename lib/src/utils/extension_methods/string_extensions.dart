extension StringExtension on String {
  String get hardcoded => this;

  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }

  String obscureEmail() {
    if (length > 5) {
      return '${substring(0, 5)}${'*' * (indexOf('@') - 5)}${substring(indexOf('@'))}';
    }
    return '';
  }

  String doubleStringToReadable() {
    return replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  String addSpaceInNWords(int number) =>
      replaceAllMapped(RegExp('.{$number}'), (match) => '${match.group(0)} ');

  String removeExceptionTraces() {
    return toLowerCase()
        .replaceAll('exception', '')
        .replaceAll('dioexception', '')
        .replaceAll('bad response', '')
        .replaceAll('dio', '')
        .replaceAll('[]', '')
        .replaceAll(':', '');
  }

  String convertKeyToReadableLabel() {
    return replaceAllMapped(
      RegExp('[A-Z]'),
      (match) => ' ${match[0]!.capitalize()}',
    ).capitalize().replaceAll('_', ' ');
  }

  String replaceUnderscores() {
    return replaceAll('_', ' ');
  }

  String toTitleCase() {
    return replaceAll(
      RegExp(' +'),
      ' ',
    ).split(' ').map((str) => str.capitalize()).join(' ');
  }

  String cleanedTranslation() {
    final regExp = RegExp('<[^>]*>');
    return replaceAll(regExp, ' ');
  }

  String getFirstCharacter() => substring(0, 1).toUpperCase();

  String lastChars(int n) {
    return length >= n ? substring(length - n) : this;
  }

  String capitalizeFirstLetter() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }

  String removeExceptionPrefix() {
    return replaceFirst('Exception: ', '');
  }
}
