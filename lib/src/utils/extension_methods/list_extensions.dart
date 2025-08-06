extension ListExtensions<T> on List<T> {
  // ignore: avoid_positional_boolean_parameters
  List<T> conditionalReversed(bool reverse) {
    return reverse ? reversed.toList() : this;
  }
}
