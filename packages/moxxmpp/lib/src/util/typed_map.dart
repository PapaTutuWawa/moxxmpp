/// A map, similar to Map, but always uses the type of the value as the key.
class TypedMap<B> {
  /// Create an empty typed map.
  TypedMap();

  /// Create a typed map from a list of values.
  TypedMap.fromList(List<B> items) {
    for (final item in items) {
      _data[item.runtimeType] = item;
    }
  }

  /// The internal mapping of type -> data
  final Map<Object, B> _data = {};

  /// Associate the type of [value] with [value] in the map.
  void set<T extends B>(T value) {
    _data[T] = value;
  }

  /// Return the object of type [T] from the map, if it has been stored.
  T? get<T>() => _data[T] as T?;
}
