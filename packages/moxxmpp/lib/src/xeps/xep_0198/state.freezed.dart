// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target

part of 'state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

StreamManagementState _$StreamManagementStateFromJson(
    Map<String, dynamic> json) {
  return _StreamManagementState.fromJson(json);
}

/// @nodoc
mixin _$StreamManagementState {
  int get c2s => throw _privateConstructorUsedError;
  int get s2c => throw _privateConstructorUsedError;
  String? get streamResumptionLocation => throw _privateConstructorUsedError;
  String? get streamResumptionId => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $StreamManagementStateCopyWith<StreamManagementState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StreamManagementStateCopyWith<$Res> {
  factory $StreamManagementStateCopyWith(StreamManagementState value,
          $Res Function(StreamManagementState) then) =
      _$StreamManagementStateCopyWithImpl<$Res>;
  $Res call(
      {int c2s,
      int s2c,
      String? streamResumptionLocation,
      String? streamResumptionId});
}

/// @nodoc
class _$StreamManagementStateCopyWithImpl<$Res>
    implements $StreamManagementStateCopyWith<$Res> {
  _$StreamManagementStateCopyWithImpl(this._value, this._then);

  final StreamManagementState _value;
  // ignore: unused_field
  final $Res Function(StreamManagementState) _then;

  @override
  $Res call({
    Object? c2s = freezed,
    Object? s2c = freezed,
    Object? streamResumptionLocation = freezed,
    Object? streamResumptionId = freezed,
  }) {
    return _then(_value.copyWith(
      c2s: c2s == freezed
          ? _value.c2s
          : c2s // ignore: cast_nullable_to_non_nullable
              as int,
      s2c: s2c == freezed
          ? _value.s2c
          : s2c // ignore: cast_nullable_to_non_nullable
              as int,
      streamResumptionLocation: streamResumptionLocation == freezed
          ? _value.streamResumptionLocation
          : streamResumptionLocation // ignore: cast_nullable_to_non_nullable
              as String?,
      streamResumptionId: streamResumptionId == freezed
          ? _value.streamResumptionId
          : streamResumptionId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
abstract class _$$_StreamManagementStateCopyWith<$Res>
    implements $StreamManagementStateCopyWith<$Res> {
  factory _$$_StreamManagementStateCopyWith(_$_StreamManagementState value,
          $Res Function(_$_StreamManagementState) then) =
      __$$_StreamManagementStateCopyWithImpl<$Res>;
  @override
  $Res call(
      {int c2s,
      int s2c,
      String? streamResumptionLocation,
      String? streamResumptionId});
}

/// @nodoc
class __$$_StreamManagementStateCopyWithImpl<$Res>
    extends _$StreamManagementStateCopyWithImpl<$Res>
    implements _$$_StreamManagementStateCopyWith<$Res> {
  __$$_StreamManagementStateCopyWithImpl(_$_StreamManagementState _value,
      $Res Function(_$_StreamManagementState) _then)
      : super(_value, (v) => _then(v as _$_StreamManagementState));

  @override
  _$_StreamManagementState get _value =>
      super._value as _$_StreamManagementState;

  @override
  $Res call({
    Object? c2s = freezed,
    Object? s2c = freezed,
    Object? streamResumptionLocation = freezed,
    Object? streamResumptionId = freezed,
  }) {
    return _then(_$_StreamManagementState(
      c2s == freezed
          ? _value.c2s
          : c2s // ignore: cast_nullable_to_non_nullable
              as int,
      s2c == freezed
          ? _value.s2c
          : s2c // ignore: cast_nullable_to_non_nullable
              as int,
      streamResumptionLocation: streamResumptionLocation == freezed
          ? _value.streamResumptionLocation
          : streamResumptionLocation // ignore: cast_nullable_to_non_nullable
              as String?,
      streamResumptionId: streamResumptionId == freezed
          ? _value.streamResumptionId
          : streamResumptionId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_StreamManagementState implements _StreamManagementState {
  _$_StreamManagementState(this.c2s, this.s2c,
      {this.streamResumptionLocation, this.streamResumptionId});

  factory _$_StreamManagementState.fromJson(Map<String, dynamic> json) =>
      _$$_StreamManagementStateFromJson(json);

  @override
  final int c2s;
  @override
  final int s2c;
  @override
  final String? streamResumptionLocation;
  @override
  final String? streamResumptionId;

  @override
  String toString() {
    return 'StreamManagementState(c2s: $c2s, s2c: $s2c, streamResumptionLocation: $streamResumptionLocation, streamResumptionId: $streamResumptionId)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_StreamManagementState &&
            const DeepCollectionEquality().equals(other.c2s, c2s) &&
            const DeepCollectionEquality().equals(other.s2c, s2c) &&
            const DeepCollectionEquality().equals(
                other.streamResumptionLocation, streamResumptionLocation) &&
            const DeepCollectionEquality()
                .equals(other.streamResumptionId, streamResumptionId));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(c2s),
      const DeepCollectionEquality().hash(s2c),
      const DeepCollectionEquality().hash(streamResumptionLocation),
      const DeepCollectionEquality().hash(streamResumptionId));

  @JsonKey(ignore: true)
  @override
  _$$_StreamManagementStateCopyWith<_$_StreamManagementState> get copyWith =>
      __$$_StreamManagementStateCopyWithImpl<_$_StreamManagementState>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_StreamManagementStateToJson(
      this,
    );
  }
}

abstract class _StreamManagementState implements StreamManagementState {
  factory _StreamManagementState(final int c2s, final int s2c,
      {final String? streamResumptionLocation,
      final String? streamResumptionId}) = _$_StreamManagementState;

  factory _StreamManagementState.fromJson(Map<String, dynamic> json) =
      _$_StreamManagementState.fromJson;

  @override
  int get c2s;
  @override
  int get s2c;
  @override
  String? get streamResumptionLocation;
  @override
  String? get streamResumptionId;
  @override
  @JsonKey(ignore: true)
  _$$_StreamManagementStateCopyWith<_$_StreamManagementState> get copyWith =>
      throw _privateConstructorUsedError;
}
