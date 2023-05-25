// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

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
  OOBData? get oob =>
      throw _privateConstructorUsedError; // XEP-0359 <origin-id />'s id attribute, if available.
  String? get originId =>
      throw _privateConstructorUsedError; // XEP-0359 <stanza-id /> elements, if available.
  List<StanzaId>? get stanzaIds => throw _privateConstructorUsedError;
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
      throw _privateConstructorUsedError; // If true, forces the encryption manager to encrypt to the JID, even if it
// would not normally. In the case of OMEMO: If shouldEncrypt returns false
// but forceEncryption is true, then the OMEMO manager will try to encrypt
// to the JID anyway.
  bool get forceEncryption =>
      throw _privateConstructorUsedError; // The stated type of encryption used, if any was used
  ExplicitEncryptionType? get encryptionType =>
      throw _privateConstructorUsedError; // Delayed Delivery
  DelayedDelivery? get delayedDelivery =>
      throw _privateConstructorUsedError; // This is for stanza handlers that are not part of the XMPP library but still need
// pass data around.
  Map<String, dynamic> get other =>
      throw _privateConstructorUsedError; // If non-null, then it indicates the origin Id of the message that should be
// retracted
  MessageRetractionData? get messageRetraction =>
      throw _privateConstructorUsedError; // If non-null, then the message is a correction for the specified stanza Id
  String? get lastMessageCorrectionSid =>
      throw _privateConstructorUsedError; // Reactions data
  MessageReactions? get messageReactions =>
      throw _privateConstructorUsedError; // The Id of the sticker pack this sticker belongs to
  String? get stickerPackId => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $StanzaHandlerDataCopyWith<StanzaHandlerData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StanzaHandlerDataCopyWith<$Res> {
  factory $StanzaHandlerDataCopyWith(
          StanzaHandlerData value, $Res Function(StanzaHandlerData) then) =
      _$StanzaHandlerDataCopyWithImpl<$Res, StanzaHandlerData>;
  @useResult
  $Res call(
      {bool done,
      bool cancel,
      dynamic cancelReason,
      Stanza stanza,
      bool retransmitted,
      StatelessMediaSharingData? sims,
      StatelessFileSharingData? sfs,
      OOBData? oob,
      String? originId,
      List<StanzaId>? stanzaIds,
      ReplyData? reply,
      ChatState? chatState,
      bool isCarbon,
      bool deliveryReceiptRequested,
      bool isMarkable,
      FileMetadataData? fun,
      String? funReplacement,
      String? funCancellation,
      bool encrypted,
      bool forceEncryption,
      ExplicitEncryptionType? encryptionType,
      DelayedDelivery? delayedDelivery,
      Map<String, dynamic> other,
      MessageRetractionData? messageRetraction,
      String? lastMessageCorrectionSid,
      MessageReactions? messageReactions,
      String? stickerPackId});
}

/// @nodoc
class _$StanzaHandlerDataCopyWithImpl<$Res, $Val extends StanzaHandlerData>
    implements $StanzaHandlerDataCopyWith<$Res> {
  _$StanzaHandlerDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? done = null,
    Object? cancel = null,
    Object? cancelReason = freezed,
    Object? stanza = null,
    Object? retransmitted = null,
    Object? sims = freezed,
    Object? sfs = freezed,
    Object? oob = freezed,
    Object? originId = freezed,
    Object? stanzaIds = freezed,
    Object? reply = freezed,
    Object? chatState = freezed,
    Object? isCarbon = null,
    Object? deliveryReceiptRequested = null,
    Object? isMarkable = null,
    Object? fun = freezed,
    Object? funReplacement = freezed,
    Object? funCancellation = freezed,
    Object? encrypted = null,
    Object? forceEncryption = null,
    Object? encryptionType = freezed,
    Object? delayedDelivery = freezed,
    Object? other = null,
    Object? messageRetraction = freezed,
    Object? lastMessageCorrectionSid = freezed,
    Object? messageReactions = freezed,
    Object? stickerPackId = freezed,
  }) {
    return _then(_value.copyWith(
      done: null == done
          ? _value.done
          : done // ignore: cast_nullable_to_non_nullable
              as bool,
      cancel: null == cancel
          ? _value.cancel
          : cancel // ignore: cast_nullable_to_non_nullable
              as bool,
      cancelReason: freezed == cancelReason
          ? _value.cancelReason
          : cancelReason // ignore: cast_nullable_to_non_nullable
              as dynamic,
      stanza: null == stanza
          ? _value.stanza
          : stanza // ignore: cast_nullable_to_non_nullable
              as Stanza,
      retransmitted: null == retransmitted
          ? _value.retransmitted
          : retransmitted // ignore: cast_nullable_to_non_nullable
              as bool,
      sims: freezed == sims
          ? _value.sims
          : sims // ignore: cast_nullable_to_non_nullable
              as StatelessMediaSharingData?,
      sfs: freezed == sfs
          ? _value.sfs
          : sfs // ignore: cast_nullable_to_non_nullable
              as StatelessFileSharingData?,
      oob: freezed == oob
          ? _value.oob
          : oob // ignore: cast_nullable_to_non_nullable
              as OOBData?,
      originId: freezed == originId
          ? _value.originId
          : originId // ignore: cast_nullable_to_non_nullable
              as String?,
      stanzaIds: freezed == stanzaIds
          ? _value.stanzaIds
          : stanzaIds // ignore: cast_nullable_to_non_nullable
              as List<StanzaId>?,
      reply: freezed == reply
          ? _value.reply
          : reply // ignore: cast_nullable_to_non_nullable
              as ReplyData?,
      chatState: freezed == chatState
          ? _value.chatState
          : chatState // ignore: cast_nullable_to_non_nullable
              as ChatState?,
      isCarbon: null == isCarbon
          ? _value.isCarbon
          : isCarbon // ignore: cast_nullable_to_non_nullable
              as bool,
      deliveryReceiptRequested: null == deliveryReceiptRequested
          ? _value.deliveryReceiptRequested
          : deliveryReceiptRequested // ignore: cast_nullable_to_non_nullable
              as bool,
      isMarkable: null == isMarkable
          ? _value.isMarkable
          : isMarkable // ignore: cast_nullable_to_non_nullable
              as bool,
      fun: freezed == fun
          ? _value.fun
          : fun // ignore: cast_nullable_to_non_nullable
              as FileMetadataData?,
      funReplacement: freezed == funReplacement
          ? _value.funReplacement
          : funReplacement // ignore: cast_nullable_to_non_nullable
              as String?,
      funCancellation: freezed == funCancellation
          ? _value.funCancellation
          : funCancellation // ignore: cast_nullable_to_non_nullable
              as String?,
      encrypted: null == encrypted
          ? _value.encrypted
          : encrypted // ignore: cast_nullable_to_non_nullable
              as bool,
      forceEncryption: null == forceEncryption
          ? _value.forceEncryption
          : forceEncryption // ignore: cast_nullable_to_non_nullable
              as bool,
      encryptionType: freezed == encryptionType
          ? _value.encryptionType
          : encryptionType // ignore: cast_nullable_to_non_nullable
              as ExplicitEncryptionType?,
      delayedDelivery: freezed == delayedDelivery
          ? _value.delayedDelivery
          : delayedDelivery // ignore: cast_nullable_to_non_nullable
              as DelayedDelivery?,
      other: null == other
          ? _value.other
          : other // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      messageRetraction: freezed == messageRetraction
          ? _value.messageRetraction
          : messageRetraction // ignore: cast_nullable_to_non_nullable
              as MessageRetractionData?,
      lastMessageCorrectionSid: freezed == lastMessageCorrectionSid
          ? _value.lastMessageCorrectionSid
          : lastMessageCorrectionSid // ignore: cast_nullable_to_non_nullable
              as String?,
      messageReactions: freezed == messageReactions
          ? _value.messageReactions
          : messageReactions // ignore: cast_nullable_to_non_nullable
              as MessageReactions?,
      stickerPackId: freezed == stickerPackId
          ? _value.stickerPackId
          : stickerPackId // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_StanzaHandlerDataCopyWith<$Res>
    implements $StanzaHandlerDataCopyWith<$Res> {
  factory _$$_StanzaHandlerDataCopyWith(_$_StanzaHandlerData value,
          $Res Function(_$_StanzaHandlerData) then) =
      __$$_StanzaHandlerDataCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool done,
      bool cancel,
      dynamic cancelReason,
      Stanza stanza,
      bool retransmitted,
      StatelessMediaSharingData? sims,
      StatelessFileSharingData? sfs,
      OOBData? oob,
      String? originId,
      List<StanzaId>? stanzaIds,
      ReplyData? reply,
      ChatState? chatState,
      bool isCarbon,
      bool deliveryReceiptRequested,
      bool isMarkable,
      FileMetadataData? fun,
      String? funReplacement,
      String? funCancellation,
      bool encrypted,
      bool forceEncryption,
      ExplicitEncryptionType? encryptionType,
      DelayedDelivery? delayedDelivery,
      Map<String, dynamic> other,
      MessageRetractionData? messageRetraction,
      String? lastMessageCorrectionSid,
      MessageReactions? messageReactions,
      String? stickerPackId});
}

/// @nodoc
class __$$_StanzaHandlerDataCopyWithImpl<$Res>
    extends _$StanzaHandlerDataCopyWithImpl<$Res, _$_StanzaHandlerData>
    implements _$$_StanzaHandlerDataCopyWith<$Res> {
  __$$_StanzaHandlerDataCopyWithImpl(
      _$_StanzaHandlerData _value, $Res Function(_$_StanzaHandlerData) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? done = null,
    Object? cancel = null,
    Object? cancelReason = freezed,
    Object? stanza = null,
    Object? retransmitted = null,
    Object? sims = freezed,
    Object? sfs = freezed,
    Object? oob = freezed,
    Object? originId = freezed,
    Object? stanzaIds = freezed,
    Object? reply = freezed,
    Object? chatState = freezed,
    Object? isCarbon = null,
    Object? deliveryReceiptRequested = null,
    Object? isMarkable = null,
    Object? fun = freezed,
    Object? funReplacement = freezed,
    Object? funCancellation = freezed,
    Object? encrypted = null,
    Object? forceEncryption = null,
    Object? encryptionType = freezed,
    Object? delayedDelivery = freezed,
    Object? other = null,
    Object? messageRetraction = freezed,
    Object? lastMessageCorrectionSid = freezed,
    Object? messageReactions = freezed,
    Object? stickerPackId = freezed,
  }) {
    return _then(_$_StanzaHandlerData(
      null == done
          ? _value.done
          : done // ignore: cast_nullable_to_non_nullable
              as bool,
      null == cancel
          ? _value.cancel
          : cancel // ignore: cast_nullable_to_non_nullable
              as bool,
      freezed == cancelReason
          ? _value.cancelReason
          : cancelReason // ignore: cast_nullable_to_non_nullable
              as dynamic,
      null == stanza
          ? _value.stanza
          : stanza // ignore: cast_nullable_to_non_nullable
              as Stanza,
      retransmitted: null == retransmitted
          ? _value.retransmitted
          : retransmitted // ignore: cast_nullable_to_non_nullable
              as bool,
      sims: freezed == sims
          ? _value.sims
          : sims // ignore: cast_nullable_to_non_nullable
              as StatelessMediaSharingData?,
      sfs: freezed == sfs
          ? _value.sfs
          : sfs // ignore: cast_nullable_to_non_nullable
              as StatelessFileSharingData?,
      oob: freezed == oob
          ? _value.oob
          : oob // ignore: cast_nullable_to_non_nullable
              as OOBData?,
      originId: freezed == originId
          ? _value.originId
          : originId // ignore: cast_nullable_to_non_nullable
              as String?,
      stanzaIds: freezed == stanzaIds
          ? _value._stanzaIds
          : stanzaIds // ignore: cast_nullable_to_non_nullable
              as List<StanzaId>?,
      reply: freezed == reply
          ? _value.reply
          : reply // ignore: cast_nullable_to_non_nullable
              as ReplyData?,
      chatState: freezed == chatState
          ? _value.chatState
          : chatState // ignore: cast_nullable_to_non_nullable
              as ChatState?,
      isCarbon: null == isCarbon
          ? _value.isCarbon
          : isCarbon // ignore: cast_nullable_to_non_nullable
              as bool,
      deliveryReceiptRequested: null == deliveryReceiptRequested
          ? _value.deliveryReceiptRequested
          : deliveryReceiptRequested // ignore: cast_nullable_to_non_nullable
              as bool,
      isMarkable: null == isMarkable
          ? _value.isMarkable
          : isMarkable // ignore: cast_nullable_to_non_nullable
              as bool,
      fun: freezed == fun
          ? _value.fun
          : fun // ignore: cast_nullable_to_non_nullable
              as FileMetadataData?,
      funReplacement: freezed == funReplacement
          ? _value.funReplacement
          : funReplacement // ignore: cast_nullable_to_non_nullable
              as String?,
      funCancellation: freezed == funCancellation
          ? _value.funCancellation
          : funCancellation // ignore: cast_nullable_to_non_nullable
              as String?,
      encrypted: null == encrypted
          ? _value.encrypted
          : encrypted // ignore: cast_nullable_to_non_nullable
              as bool,
      forceEncryption: null == forceEncryption
          ? _value.forceEncryption
          : forceEncryption // ignore: cast_nullable_to_non_nullable
              as bool,
      encryptionType: freezed == encryptionType
          ? _value.encryptionType
          : encryptionType // ignore: cast_nullable_to_non_nullable
              as ExplicitEncryptionType?,
      delayedDelivery: freezed == delayedDelivery
          ? _value.delayedDelivery
          : delayedDelivery // ignore: cast_nullable_to_non_nullable
              as DelayedDelivery?,
      other: null == other
          ? _value._other
          : other // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      messageRetraction: freezed == messageRetraction
          ? _value.messageRetraction
          : messageRetraction // ignore: cast_nullable_to_non_nullable
              as MessageRetractionData?,
      lastMessageCorrectionSid: freezed == lastMessageCorrectionSid
          ? _value.lastMessageCorrectionSid
          : lastMessageCorrectionSid // ignore: cast_nullable_to_non_nullable
              as String?,
      messageReactions: freezed == messageReactions
          ? _value.messageReactions
          : messageReactions // ignore: cast_nullable_to_non_nullable
              as MessageReactions?,
      stickerPackId: freezed == stickerPackId
          ? _value.stickerPackId
          : stickerPackId // ignore: cast_nullable_to_non_nullable
              as String?,
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
      this.originId,
      final List<StanzaId>? stanzaIds,
      this.reply,
      this.chatState,
      this.isCarbon = false,
      this.deliveryReceiptRequested = false,
      this.isMarkable = false,
      this.fun,
      this.funReplacement,
      this.funCancellation,
      this.encrypted = false,
      this.forceEncryption = false,
      this.encryptionType,
      this.delayedDelivery,
      final Map<String, dynamic> other = const <String, dynamic>{},
      this.messageRetraction,
      this.lastMessageCorrectionSid,
      this.messageReactions,
      this.stickerPackId})
      : _stanzaIds = stanzaIds,
        _other = other;

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
// XEP-0359 <origin-id />'s id attribute, if available.
  @override
  final String? originId;
// XEP-0359 <stanza-id /> elements, if available.
  final List<StanzaId>? _stanzaIds;
// XEP-0359 <stanza-id /> elements, if available.
  @override
  List<StanzaId>? get stanzaIds {
    final value = _stanzaIds;
    if (value == null) return null;
    if (_stanzaIds is EqualUnmodifiableListView) return _stanzaIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

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
// If true, forces the encryption manager to encrypt to the JID, even if it
// would not normally. In the case of OMEMO: If shouldEncrypt returns false
// but forceEncryption is true, then the OMEMO manager will try to encrypt
// to the JID anyway.
  @override
  @JsonKey()
  final bool forceEncryption;
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
    if (_other is EqualUnmodifiableMapView) return _other;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_other);
  }

// If non-null, then it indicates the origin Id of the message that should be
// retracted
  @override
  final MessageRetractionData? messageRetraction;
// If non-null, then the message is a correction for the specified stanza Id
  @override
  final String? lastMessageCorrectionSid;
// Reactions data
  @override
  final MessageReactions? messageReactions;
// The Id of the sticker pack this sticker belongs to
  @override
  final String? stickerPackId;

  @override
  String toString() {
    return 'StanzaHandlerData(done: $done, cancel: $cancel, cancelReason: $cancelReason, stanza: $stanza, retransmitted: $retransmitted, sims: $sims, sfs: $sfs, oob: $oob, originId: $originId, stanzaIds: $stanzaIds, reply: $reply, chatState: $chatState, isCarbon: $isCarbon, deliveryReceiptRequested: $deliveryReceiptRequested, isMarkable: $isMarkable, fun: $fun, funReplacement: $funReplacement, funCancellation: $funCancellation, encrypted: $encrypted, forceEncryption: $forceEncryption, encryptionType: $encryptionType, delayedDelivery: $delayedDelivery, other: $other, messageRetraction: $messageRetraction, lastMessageCorrectionSid: $lastMessageCorrectionSid, messageReactions: $messageReactions, stickerPackId: $stickerPackId)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_StanzaHandlerData &&
            (identical(other.done, done) || other.done == done) &&
            (identical(other.cancel, cancel) || other.cancel == cancel) &&
            const DeepCollectionEquality()
                .equals(other.cancelReason, cancelReason) &&
            (identical(other.stanza, stanza) || other.stanza == stanza) &&
            (identical(other.retransmitted, retransmitted) ||
                other.retransmitted == retransmitted) &&
            (identical(other.sims, sims) || other.sims == sims) &&
            (identical(other.sfs, sfs) || other.sfs == sfs) &&
            (identical(other.oob, oob) || other.oob == oob) &&
            (identical(other.originId, originId) ||
                other.originId == originId) &&
            const DeepCollectionEquality()
                .equals(other._stanzaIds, _stanzaIds) &&
            (identical(other.reply, reply) || other.reply == reply) &&
            (identical(other.chatState, chatState) ||
                other.chatState == chatState) &&
            (identical(other.isCarbon, isCarbon) ||
                other.isCarbon == isCarbon) &&
            (identical(
                    other.deliveryReceiptRequested, deliveryReceiptRequested) ||
                other.deliveryReceiptRequested == deliveryReceiptRequested) &&
            (identical(other.isMarkable, isMarkable) ||
                other.isMarkable == isMarkable) &&
            (identical(other.fun, fun) || other.fun == fun) &&
            (identical(other.funReplacement, funReplacement) ||
                other.funReplacement == funReplacement) &&
            (identical(other.funCancellation, funCancellation) ||
                other.funCancellation == funCancellation) &&
            (identical(other.encrypted, encrypted) ||
                other.encrypted == encrypted) &&
            (identical(other.forceEncryption, forceEncryption) ||
                other.forceEncryption == forceEncryption) &&
            (identical(other.encryptionType, encryptionType) ||
                other.encryptionType == encryptionType) &&
            (identical(other.delayedDelivery, delayedDelivery) ||
                other.delayedDelivery == delayedDelivery) &&
            const DeepCollectionEquality().equals(other._other, this._other) &&
            (identical(other.messageRetraction, messageRetraction) ||
                other.messageRetraction == messageRetraction) &&
            (identical(
                    other.lastMessageCorrectionSid, lastMessageCorrectionSid) ||
                other.lastMessageCorrectionSid == lastMessageCorrectionSid) &&
            (identical(other.messageReactions, messageReactions) ||
                other.messageReactions == messageReactions) &&
            (identical(other.stickerPackId, stickerPackId) ||
                other.stickerPackId == stickerPackId));
  }

  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        done,
        cancel,
        const DeepCollectionEquality().hash(cancelReason),
        stanza,
        retransmitted,
        sims,
        sfs,
        oob,
        originId,
        const DeepCollectionEquality().hash(_stanzaIds),
        reply,
        chatState,
        isCarbon,
        deliveryReceiptRequested,
        isMarkable,
        fun,
        funReplacement,
        funCancellation,
        encrypted,
        forceEncryption,
        encryptionType,
        delayedDelivery,
        const DeepCollectionEquality().hash(_other),
        messageRetraction,
        lastMessageCorrectionSid,
        messageReactions,
        stickerPackId
      ]);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
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
      final String? originId,
      final List<StanzaId>? stanzaIds,
      final ReplyData? reply,
      final ChatState? chatState,
      final bool isCarbon,
      final bool deliveryReceiptRequested,
      final bool isMarkable,
      final FileMetadataData? fun,
      final String? funReplacement,
      final String? funCancellation,
      final bool encrypted,
      final bool forceEncryption,
      final ExplicitEncryptionType? encryptionType,
      final DelayedDelivery? delayedDelivery,
      final Map<String, dynamic> other,
      final MessageRetractionData? messageRetraction,
      final String? lastMessageCorrectionSid,
      final MessageReactions? messageReactions,
      final String? stickerPackId}) = _$_StanzaHandlerData;

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
  @override // XEP-0359 <origin-id />'s id attribute, if available.
  String? get originId;
  @override // XEP-0359 <stanza-id /> elements, if available.
  List<StanzaId>? get stanzaIds;
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
  @override // If true, forces the encryption manager to encrypt to the JID, even if it
// would not normally. In the case of OMEMO: If shouldEncrypt returns false
// but forceEncryption is true, then the OMEMO manager will try to encrypt
// to the JID anyway.
  bool get forceEncryption;
  @override // The stated type of encryption used, if any was used
  ExplicitEncryptionType? get encryptionType;
  @override // Delayed Delivery
  DelayedDelivery? get delayedDelivery;
  @override // This is for stanza handlers that are not part of the XMPP library but still need
// pass data around.
  Map<String, dynamic> get other;
  @override // If non-null, then it indicates the origin Id of the message that should be
// retracted
  MessageRetractionData? get messageRetraction;
  @override // If non-null, then the message is a correction for the specified stanza Id
  String? get lastMessageCorrectionSid;
  @override // Reactions data
  MessageReactions? get messageReactions;
  @override // The Id of the sticker pack this sticker belongs to
  String? get stickerPackId;
  @override
  @JsonKey(ignore: true)
  _$$_StanzaHandlerDataCopyWith<_$_StanzaHandlerData> get copyWith =>
      throw _privateConstructorUsedError;
}
