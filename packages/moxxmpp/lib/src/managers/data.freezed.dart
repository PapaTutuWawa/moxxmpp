// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target

part of 'data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
mixin _$StanzaHandlerData {
// Indicates to the runner that processing is now done. This means that all
// pre-processing is done and no other handlers should be consulted.
  bool get done =>
      throw _privateConstructorUsedError; // Indicates to the runner that processing is to be cancelled and no further handlers
// should run. The stanza also will not be sent.
  bool get cancel =>
      throw _privateConstructorUsedError; // The reason why we cancelled the processing and sending
  dynamic get cancelReason =>
      throw _privateConstructorUsedError; // The stanza that is being dealt with. SHOULD NOT be overwritten, unless it is absolutely
// necessary, e.g. with Message Carbons or OMEMO
  Stanza get stanza =>
      throw _privateConstructorUsedError; // Whether the stanza is retransmitted. Only useful in the context of outgoing
// stanza handlers. MUST NOT be overwritten.
  bool get retransmitted => throw _privateConstructorUsedError;
  StatelessMediaSharingData? get sims => throw _privateConstructorUsedError;
  StatelessFileSharingData? get sfs => throw _privateConstructorUsedError;
  OOBData? get oob => throw _privateConstructorUsedError;
  StableStanzaId? get stableId => throw _privateConstructorUsedError;
  ReplyData? get reply => throw _privateConstructorUsedError;
  ChatState? get chatState => throw _privateConstructorUsedError;
  bool get isCarbon => throw _privateConstructorUsedError;
  bool get deliveryReceiptRequested => throw _privateConstructorUsedError;
  bool get isMarkable =>
      throw _privateConstructorUsedError; // File Upload Notifications
// A notification
  FileMetadataData? get fun =>
      throw _privateConstructorUsedError; // The stanza id this replaces
  String? get funReplacement =>
      throw _privateConstructorUsedError; // The stanza id this cancels
  String? get funCancellation =>
      throw _privateConstructorUsedError; // Whether the stanza was received encrypted
  bool get encrypted =>
      throw _privateConstructorUsedError; // The stated type of encryption used, if any was used
  ExplicitEncryptionType? get encryptionType =>
      throw _privateConstructorUsedError; // Delayed Delivery
  DelayedDelivery? get delayedDelivery =>
      throw _privateConstructorUsedError; // This is for stanza handlers that are not part of the XMPP library but still need
// pass data around.
  Map<String, dynamic> get other => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $StanzaHandlerDataCopyWith<StanzaHandlerData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StanzaHandlerDataCopyWith<$Res> {
  factory $StanzaHandlerDataCopyWith(
          StanzaHandlerData value, $Res Function(StanzaHandlerData) then) =
      _$StanzaHandlerDataCopyWithImpl<$Res>;
  $Res call(
      {bool done,
      bool cancel,
      dynamic cancelReason,
      Stanza stanza,
      bool retransmitted,
      StatelessMediaSharingData? sims,
      StatelessFileSharingData? sfs,
      OOBData? oob,
      StableStanzaId? stableId,
      ReplyData? reply,
      ChatState? chatState,
      bool isCarbon,
      bool deliveryReceiptRequested,
      bool isMarkable,
      FileMetadataData? fun,
      String? funReplacement,
      String? funCancellation,
      bool encrypted,
      ExplicitEncryptionType? encryptionType,
      DelayedDelivery? delayedDelivery,
      Map<String, dynamic> other});
}

/// @nodoc
class _$StanzaHandlerDataCopyWithImpl<$Res>
    implements $StanzaHandlerDataCopyWith<$Res> {
  _$StanzaHandlerDataCopyWithImpl(this._value, this._then);

  final StanzaHandlerData _value;
  // ignore: unused_field
  final $Res Function(StanzaHandlerData) _then;

  @override
  $Res call({
    Object? done = freezed,
    Object? cancel = freezed,
    Object? cancelReason = freezed,
    Object? stanza = freezed,
    Object? retransmitted = freezed,
    Object? sims = freezed,
    Object? sfs = freezed,
    Object? oob = freezed,
    Object? stableId = freezed,
    Object? reply = freezed,
    Object? chatState = freezed,
    Object? isCarbon = freezed,
    Object? deliveryReceiptRequested = freezed,
    Object? isMarkable = freezed,
    Object? fun = freezed,
    Object? funReplacement = freezed,
    Object? funCancellation = freezed,
    Object? encrypted = freezed,
    Object? encryptionType = freezed,
    Object? delayedDelivery = freezed,
    Object? other = freezed,
  }) {
    return _then(_value.copyWith(
      done: done == freezed
          ? _value.done
          : done // ignore: cast_nullable_to_non_nullable
              as bool,
      cancel: cancel == freezed
          ? _value.cancel
          : cancel // ignore: cast_nullable_to_non_nullable
              as bool,
      cancelReason: cancelReason == freezed
          ? _value.cancelReason
          : cancelReason // ignore: cast_nullable_to_non_nullable
              as dynamic,
      stanza: stanza == freezed
          ? _value.stanza
          : stanza // ignore: cast_nullable_to_non_nullable
              as Stanza,
      retransmitted: retransmitted == freezed
          ? _value.retransmitted
          : retransmitted // ignore: cast_nullable_to_non_nullable
              as bool,
      sims: sims == freezed
          ? _value.sims
          : sims // ignore: cast_nullable_to_non_nullable
              as StatelessMediaSharingData?,
      sfs: sfs == freezed
          ? _value.sfs
          : sfs // ignore: cast_nullable_to_non_nullable
              as StatelessFileSharingData?,
      oob: oob == freezed
          ? _value.oob
          : oob // ignore: cast_nullable_to_non_nullable
              as OOBData?,
      stableId: stableId == freezed
          ? _value.stableId
          : stableId // ignore: cast_nullable_to_non_nullable
              as StableStanzaId?,
      reply: reply == freezed
          ? _value.reply
          : reply // ignore: cast_nullable_to_non_nullable
              as ReplyData?,
      chatState: chatState == freezed
          ? _value.chatState
          : chatState // ignore: cast_nullable_to_non_nullable
              as ChatState?,
      isCarbon: isCarbon == freezed
          ? _value.isCarbon
          : isCarbon // ignore: cast_nullable_to_non_nullable
              as bool,
      deliveryReceiptRequested: deliveryReceiptRequested == freezed
          ? _value.deliveryReceiptRequested
          : deliveryReceiptRequested // ignore: cast_nullable_to_non_nullable
              as bool,
      isMarkable: isMarkable == freezed
          ? _value.isMarkable
          : isMarkable // ignore: cast_nullable_to_non_nullable
              as bool,
      fun: fun == freezed
          ? _value.fun
          : fun // ignore: cast_nullable_to_non_nullable
              as FileMetadataData?,
      funReplacement: funReplacement == freezed
          ? _value.funReplacement
          : funReplacement // ignore: cast_nullable_to_non_nullable
              as String?,
      funCancellation: funCancellation == freezed
          ? _value.funCancellation
          : funCancellation // ignore: cast_nullable_to_non_nullable
              as String?,
      encrypted: encrypted == freezed
          ? _value.encrypted
          : encrypted // ignore: cast_nullable_to_non_nullable
              as bool,
      encryptionType: encryptionType == freezed
          ? _value.encryptionType
          : encryptionType // ignore: cast_nullable_to_non_nullable
              as ExplicitEncryptionType?,
      delayedDelivery: delayedDelivery == freezed
          ? _value.delayedDelivery
          : delayedDelivery // ignore: cast_nullable_to_non_nullable
              as DelayedDelivery?,
      other: other == freezed
          ? _value.other
          : other // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
abstract class _$$_StanzaHandlerDataCopyWith<$Res>
    implements $StanzaHandlerDataCopyWith<$Res> {
  factory _$$_StanzaHandlerDataCopyWith(_$_StanzaHandlerData value,
          $Res Function(_$_StanzaHandlerData) then) =
      __$$_StanzaHandlerDataCopyWithImpl<$Res>;
  @override
  $Res call(
      {bool done,
      bool cancel,
      dynamic cancelReason,
      Stanza stanza,
      bool retransmitted,
      StatelessMediaSharingData? sims,
      StatelessFileSharingData? sfs,
      OOBData? oob,
      StableStanzaId? stableId,
      ReplyData? reply,
      ChatState? chatState,
      bool isCarbon,
      bool deliveryReceiptRequested,
      bool isMarkable,
      FileMetadataData? fun,
      String? funReplacement,
      String? funCancellation,
      bool encrypted,
      ExplicitEncryptionType? encryptionType,
      DelayedDelivery? delayedDelivery,
      Map<String, dynamic> other});
}

/// @nodoc
class __$$_StanzaHandlerDataCopyWithImpl<$Res>
    extends _$StanzaHandlerDataCopyWithImpl<$Res>
    implements _$$_StanzaHandlerDataCopyWith<$Res> {
  __$$_StanzaHandlerDataCopyWithImpl(
      _$_StanzaHandlerData _value, $Res Function(_$_StanzaHandlerData) _then)
      : super(_value, (v) => _then(v as _$_StanzaHandlerData));

  @override
  _$_StanzaHandlerData get _value => super._value as _$_StanzaHandlerData;

  @override
  $Res call({
    Object? done = freezed,
    Object? cancel = freezed,
    Object? cancelReason = freezed,
    Object? stanza = freezed,
    Object? retransmitted = freezed,
    Object? sims = freezed,
    Object? sfs = freezed,
    Object? oob = freezed,
    Object? stableId = freezed,
    Object? reply = freezed,
    Object? chatState = freezed,
    Object? isCarbon = freezed,
    Object? deliveryReceiptRequested = freezed,
    Object? isMarkable = freezed,
    Object? fun = freezed,
    Object? funReplacement = freezed,
    Object? funCancellation = freezed,
    Object? encrypted = freezed,
    Object? encryptionType = freezed,
    Object? delayedDelivery = freezed,
    Object? other = freezed,
  }) {
    return _then(_$_StanzaHandlerData(
      done == freezed
          ? _value.done
          : done // ignore: cast_nullable_to_non_nullable
              as bool,
      cancel == freezed
          ? _value.cancel
          : cancel // ignore: cast_nullable_to_non_nullable
              as bool,
      cancelReason == freezed
          ? _value.cancelReason
          : cancelReason // ignore: cast_nullable_to_non_nullable
              as dynamic,
      stanza == freezed
          ? _value.stanza
          : stanza // ignore: cast_nullable_to_non_nullable
              as Stanza,
      retransmitted: retransmitted == freezed
          ? _value.retransmitted
          : retransmitted // ignore: cast_nullable_to_non_nullable
              as bool,
      sims: sims == freezed
          ? _value.sims
          : sims // ignore: cast_nullable_to_non_nullable
              as StatelessMediaSharingData?,
      sfs: sfs == freezed
          ? _value.sfs
          : sfs // ignore: cast_nullable_to_non_nullable
              as StatelessFileSharingData?,
      oob: oob == freezed
          ? _value.oob
          : oob // ignore: cast_nullable_to_non_nullable
              as OOBData?,
      stableId: stableId == freezed
          ? _value.stableId
          : stableId // ignore: cast_nullable_to_non_nullable
              as StableStanzaId?,
      reply: reply == freezed
          ? _value.reply
          : reply // ignore: cast_nullable_to_non_nullable
              as ReplyData?,
      chatState: chatState == freezed
          ? _value.chatState
          : chatState // ignore: cast_nullable_to_non_nullable
              as ChatState?,
      isCarbon: isCarbon == freezed
          ? _value.isCarbon
          : isCarbon // ignore: cast_nullable_to_non_nullable
              as bool,
      deliveryReceiptRequested: deliveryReceiptRequested == freezed
          ? _value.deliveryReceiptRequested
          : deliveryReceiptRequested // ignore: cast_nullable_to_non_nullable
              as bool,
      isMarkable: isMarkable == freezed
          ? _value.isMarkable
          : isMarkable // ignore: cast_nullable_to_non_nullable
              as bool,
      fun: fun == freezed
          ? _value.fun
          : fun // ignore: cast_nullable_to_non_nullable
              as FileMetadataData?,
      funReplacement: funReplacement == freezed
          ? _value.funReplacement
          : funReplacement // ignore: cast_nullable_to_non_nullable
              as String?,
      funCancellation: funCancellation == freezed
          ? _value.funCancellation
          : funCancellation // ignore: cast_nullable_to_non_nullable
              as String?,
      encrypted: encrypted == freezed
          ? _value.encrypted
          : encrypted // ignore: cast_nullable_to_non_nullable
              as bool,
      encryptionType: encryptionType == freezed
          ? _value.encryptionType
          : encryptionType // ignore: cast_nullable_to_non_nullable
              as ExplicitEncryptionType?,
      delayedDelivery: delayedDelivery == freezed
          ? _value.delayedDelivery
          : delayedDelivery // ignore: cast_nullable_to_non_nullable
              as DelayedDelivery?,
      other: other == freezed
          ? _value._other
          : other // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc

class _$_StanzaHandlerData implements _StanzaHandlerData {
  _$_StanzaHandlerData(this.done, this.cancel, this.cancelReason, this.stanza,
      {this.retransmitted = false,
      this.sims,
      this.sfs,
      this.oob,
      this.stableId,
      this.reply,
      this.chatState,
      this.isCarbon = false,
      this.deliveryReceiptRequested = false,
      this.isMarkable = false,
      this.fun,
      this.funReplacement,
      this.funCancellation,
      this.encrypted = false,
      this.encryptionType,
      this.delayedDelivery,
      final Map<String, dynamic> other = const <String, dynamic>{}})
      : _other = other;

// Indicates to the runner that processing is now done. This means that all
// pre-processing is done and no other handlers should be consulted.
  @override
  final bool done;
// Indicates to the runner that processing is to be cancelled and no further handlers
// should run. The stanza also will not be sent.
  @override
  final bool cancel;
// The reason why we cancelled the processing and sending
  @override
  final dynamic cancelReason;
// The stanza that is being dealt with. SHOULD NOT be overwritten, unless it is absolutely
// necessary, e.g. with Message Carbons or OMEMO
  @override
  final Stanza stanza;
// Whether the stanza is retransmitted. Only useful in the context of outgoing
// stanza handlers. MUST NOT be overwritten.
  @override
  @JsonKey()
  final bool retransmitted;
  @override
  final StatelessMediaSharingData? sims;
  @override
  final StatelessFileSharingData? sfs;
  @override
  final OOBData? oob;
  @override
  final StableStanzaId? stableId;
  @override
  final ReplyData? reply;
  @override
  final ChatState? chatState;
  @override
  @JsonKey()
  final bool isCarbon;
  @override
  @JsonKey()
  final bool deliveryReceiptRequested;
  @override
  @JsonKey()
  final bool isMarkable;
// File Upload Notifications
// A notification
  @override
  final FileMetadataData? fun;
// The stanza id this replaces
  @override
  final String? funReplacement;
// The stanza id this cancels
  @override
  final String? funCancellation;
// Whether the stanza was received encrypted
  @override
  @JsonKey()
  final bool encrypted;
// The stated type of encryption used, if any was used
  @override
  final ExplicitEncryptionType? encryptionType;
// Delayed Delivery
  @override
  final DelayedDelivery? delayedDelivery;
// This is for stanza handlers that are not part of the XMPP library but still need
// pass data around.
  final Map<String, dynamic> _other;
// This is for stanza handlers that are not part of the XMPP library but still need
// pass data around.
  @override
  @JsonKey()
  Map<String, dynamic> get other {
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_other);
  }

  @override
  String toString() {
    return 'StanzaHandlerData(done: $done, cancel: $cancel, cancelReason: $cancelReason, stanza: $stanza, retransmitted: $retransmitted, sims: $sims, sfs: $sfs, oob: $oob, stableId: $stableId, reply: $reply, chatState: $chatState, isCarbon: $isCarbon, deliveryReceiptRequested: $deliveryReceiptRequested, isMarkable: $isMarkable, fun: $fun, funReplacement: $funReplacement, funCancellation: $funCancellation, encrypted: $encrypted, encryptionType: $encryptionType, delayedDelivery: $delayedDelivery, other: $other)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_StanzaHandlerData &&
            const DeepCollectionEquality().equals(other.done, done) &&
            const DeepCollectionEquality().equals(other.cancel, cancel) &&
            const DeepCollectionEquality()
                .equals(other.cancelReason, cancelReason) &&
            const DeepCollectionEquality().equals(other.stanza, stanza) &&
            const DeepCollectionEquality()
                .equals(other.retransmitted, retransmitted) &&
            const DeepCollectionEquality().equals(other.sims, sims) &&
            const DeepCollectionEquality().equals(other.sfs, sfs) &&
            const DeepCollectionEquality().equals(other.oob, oob) &&
            const DeepCollectionEquality().equals(other.stableId, stableId) &&
            const DeepCollectionEquality().equals(other.reply, reply) &&
            const DeepCollectionEquality().equals(other.chatState, chatState) &&
            const DeepCollectionEquality().equals(other.isCarbon, isCarbon) &&
            const DeepCollectionEquality().equals(
                other.deliveryReceiptRequested, deliveryReceiptRequested) &&
            const DeepCollectionEquality()
                .equals(other.isMarkable, isMarkable) &&
            const DeepCollectionEquality().equals(other.fun, fun) &&
            const DeepCollectionEquality()
                .equals(other.funReplacement, funReplacement) &&
            const DeepCollectionEquality()
                .equals(other.funCancellation, funCancellation) &&
            const DeepCollectionEquality().equals(other.encrypted, encrypted) &&
            const DeepCollectionEquality()
                .equals(other.encryptionType, encryptionType) &&
            const DeepCollectionEquality()
                .equals(other.delayedDelivery, delayedDelivery) &&
            const DeepCollectionEquality().equals(other._other, this._other));
  }

  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        const DeepCollectionEquality().hash(done),
        const DeepCollectionEquality().hash(cancel),
        const DeepCollectionEquality().hash(cancelReason),
        const DeepCollectionEquality().hash(stanza),
        const DeepCollectionEquality().hash(retransmitted),
        const DeepCollectionEquality().hash(sims),
        const DeepCollectionEquality().hash(sfs),
        const DeepCollectionEquality().hash(oob),
        const DeepCollectionEquality().hash(stableId),
        const DeepCollectionEquality().hash(reply),
        const DeepCollectionEquality().hash(chatState),
        const DeepCollectionEquality().hash(isCarbon),
        const DeepCollectionEquality().hash(deliveryReceiptRequested),
        const DeepCollectionEquality().hash(isMarkable),
        const DeepCollectionEquality().hash(fun),
        const DeepCollectionEquality().hash(funReplacement),
        const DeepCollectionEquality().hash(funCancellation),
        const DeepCollectionEquality().hash(encrypted),
        const DeepCollectionEquality().hash(encryptionType),
        const DeepCollectionEquality().hash(delayedDelivery),
        const DeepCollectionEquality().hash(_other)
      ]);

  @JsonKey(ignore: true)
  @override
  _$$_StanzaHandlerDataCopyWith<_$_StanzaHandlerData> get copyWith =>
      __$$_StanzaHandlerDataCopyWithImpl<_$_StanzaHandlerData>(
          this, _$identity);
}

abstract class _StanzaHandlerData implements StanzaHandlerData {
  factory _StanzaHandlerData(final bool done, final bool cancel,
      final dynamic cancelReason, final Stanza stanza,
      {final bool retransmitted,
      final StatelessMediaSharingData? sims,
      final StatelessFileSharingData? sfs,
      final OOBData? oob,
      final StableStanzaId? stableId,
      final ReplyData? reply,
      final ChatState? chatState,
      final bool isCarbon,
      final bool deliveryReceiptRequested,
      final bool isMarkable,
      final FileMetadataData? fun,
      final String? funReplacement,
      final String? funCancellation,
      final bool encrypted,
      final ExplicitEncryptionType? encryptionType,
      final DelayedDelivery? delayedDelivery,
      final Map<String, dynamic> other}) = _$_StanzaHandlerData;

  @override // Indicates to the runner that processing is now done. This means that all
// pre-processing is done and no other handlers should be consulted.
  bool get done;
  @override // Indicates to the runner that processing is to be cancelled and no further handlers
// should run. The stanza also will not be sent.
  bool get cancel;
  @override // The reason why we cancelled the processing and sending
  dynamic get cancelReason;
  @override // The stanza that is being dealt with. SHOULD NOT be overwritten, unless it is absolutely
// necessary, e.g. with Message Carbons or OMEMO
  Stanza get stanza;
  @override // Whether the stanza is retransmitted. Only useful in the context of outgoing
// stanza handlers. MUST NOT be overwritten.
  bool get retransmitted;
  @override
  StatelessMediaSharingData? get sims;
  @override
  StatelessFileSharingData? get sfs;
  @override
  OOBData? get oob;
  @override
  StableStanzaId? get stableId;
  @override
  ReplyData? get reply;
  @override
  ChatState? get chatState;
  @override
  bool get isCarbon;
  @override
  bool get deliveryReceiptRequested;
  @override
  bool get isMarkable;
  @override // File Upload Notifications
// A notification
  FileMetadataData? get fun;
  @override // The stanza id this replaces
  String? get funReplacement;
  @override // The stanza id this cancels
  String? get funCancellation;
  @override // Whether the stanza was received encrypted
  bool get encrypted;
  @override // The stated type of encryption used, if any was used
  ExplicitEncryptionType? get encryptionType;
  @override // Delayed Delivery
  DelayedDelivery? get delayedDelivery;
  @override // This is for stanza handlers that are not part of the XMPP library but still need
// pass data around.
  Map<String, dynamic> get other;
  @override
  @JsonKey(ignore: true)
  _$$_StanzaHandlerDataCopyWith<_$_StanzaHandlerData> get copyWith =>
      throw _privateConstructorUsedError;
}
