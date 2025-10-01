// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cta_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CtaItem _$CtaItemFromJson(Map<String, dynamic> json) => CtaItem(
  id: json['id'] as String,
  isEnabled: json['isEnabled'] as bool,
  title: json['title'] as String,
  content: json['content'] as String,
  position: $enumDecode(_$CtaPositionEnumMap, json['position']),
  generationType: $enumDecode(
    _$CtaGenerationTypeEnumMap,
    json['generationType'],
  ),
  customPositionPercentage: (json['customPositionPercentage'] as num?)?.toInt(),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$CtaItemToJson(CtaItem instance) => <String, dynamic>{
  'id': instance.id,
  'isEnabled': instance.isEnabled,
  'title': instance.title,
  'content': instance.content,
  'position': _$CtaPositionEnumMap[instance.position]!,
  'generationType': _$CtaGenerationTypeEnumMap[instance.generationType]!,
  'customPositionPercentage': instance.customPositionPercentage,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};

const _$CtaPositionEnumMap = {
  CtaPosition.beginning: 'beginning',
  CtaPosition.middle: 'middle',
  CtaPosition.end: 'end',
  CtaPosition.custom: 'custom',
};

const _$CtaGenerationTypeEnumMap = {
  CtaGenerationType.automatic: 'automatic',
  CtaGenerationType.manual: 'manual',
};

CtaConfig _$CtaConfigFromJson(Map<String, dynamic> json) => CtaConfig(
  ctas: (json['ctas'] as List<dynamic>)
      .map((e) => CtaItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  isEnabled: json['isEnabled'] as bool,
  maxCtas: (json['maxCtas'] as num?)?.toInt() ?? 4,
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$CtaConfigToJson(CtaConfig instance) => <String, dynamic>{
  'ctas': instance.ctas,
  'isEnabled': instance.isEnabled,
  'maxCtas': instance.maxCtas,
  'updatedAt': instance.updatedAt.toIso8601String(),
};
