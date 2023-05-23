extension ListItemCountExtension<T> on List<T> {
  int count(bool Function(T) matches) {
    return where(matches).length;
  }
}
