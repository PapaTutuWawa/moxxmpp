import 'package:meta/meta.dart';

const _smNotSpecified = Object();

@immutable
class StreamManagementState {
  const StreamManagementState(
    this.c2s,
    this.s2c, {
    this.streamResumptionLocation,
    this.streamResumptionId,
  });

  /// The counter of stanzas sent from the client to the server.
  final int c2s;

  /// The counter of stanzas sent from the server to the client.
  final int s2c;

  /// If set, the server's preferred location for resumption.
  final String? streamResumptionLocation;

  /// If set, the token to allow using stream resumption.
  final String? streamResumptionId;

  StreamManagementState copyWith({
    Object c2s = _smNotSpecified,
    Object s2c = _smNotSpecified,
    Object? streamResumptionLocation = _smNotSpecified,
    Object? streamResumptionId = _smNotSpecified,
  }) {
    return StreamManagementState(
      c2s != _smNotSpecified ? c2s as int : this.c2s,
      s2c != _smNotSpecified ? s2c as int : this.s2c,
      streamResumptionLocation: streamResumptionLocation != _smNotSpecified
          ? streamResumptionLocation as String?
          : this.streamResumptionLocation,
      streamResumptionId: streamResumptionId != _smNotSpecified
          ? streamResumptionId as String?
          : this.streamResumptionId,
    );
  }
}
