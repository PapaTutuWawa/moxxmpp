// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$_StreamManagementState _$$_StreamManagementStateFromJson(
        Map<String, dynamic> json) =>
    _$_StreamManagementState(
      json['c2s'] as int,
      json['s2c'] as int,
      streamResumptionLocation: json['streamResumptionLocation'] as String?,
      streamResumptionId: json['streamResumptionId'] as String?,
    );

Map<String, dynamic> _$$_StreamManagementStateToJson(
        _$_StreamManagementState instance) =>
    <String, dynamic>{
      'c2s': instance.c2s,
      's2c': instance.s2c,
      'streamResumptionLocation': instance.streamResumptionLocation,
      'streamResumptionId': instance.streamResumptionId,
    };
