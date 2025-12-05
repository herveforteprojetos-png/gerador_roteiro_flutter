import 'package:json_annotation/json_annotation.dart';

part 'cta_config.g.dart';

/// Enumeration for CTA positioning in the script
enum CtaPosition {
  @JsonValue('beginning')
  beginning('beginning', 'Início do roteiro'),

  @JsonValue('middle')
  middle('middle', 'Meio do roteiro'),

  @JsonValue('end')
  end('end', 'Final do roteiro'),

  @JsonValue('custom')
  custom('custom', 'Posição personalizada');

  const CtaPosition(this.value, this.displayName);

  final String value;
  final String displayName;
}

/// Enumeration for CTA generation type
enum CtaGenerationType {
  @JsonValue('automatic')
  automatic('automatic', 'Automático (baseado no conteúdo)'),

  @JsonValue('manual')
  manual('manual', 'Manual (personalizado)');

  const CtaGenerationType(this.value, this.displayName);

  final String value;
  final String displayName;
}

/// Individual CTA configuration
@JsonSerializable()
class CtaItem {
  final String id;
  final bool isEnabled;
  final String title;
  final String content;
  final CtaPosition position;
  final CtaGenerationType generationType;
  final int? customPositionPercentage; // For custom positioning (0-100%)
  final DateTime createdAt;
  final DateTime updatedAt;

  const CtaItem({
    required this.id,
    required this.isEnabled,
    required this.title,
    required this.content,
    required this.position,
    required this.generationType,
    this.customPositionPercentage,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory for creating a new CTA with automatic generation
  factory CtaItem.createAutomatic({
    required String title,
    required CtaPosition position,
    int? customPositionPercentage,
  }) {
    final now = DateTime.now();
    return CtaItem(
      id: 'cta_${now.millisecondsSinceEpoch}',
      isEnabled: true,
      title: title,
      content: '', // Will be generated automatically
      position: position,
      generationType: CtaGenerationType.automatic,
      customPositionPercentage: customPositionPercentage,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Factory for creating a new CTA with manual content
  factory CtaItem.createManual({
    required String title,
    required String content,
    required CtaPosition position,
    int? customPositionPercentage,
  }) {
    final now = DateTime.now();
    return CtaItem(
      id: 'cta_${now.millisecondsSinceEpoch}',
      isEnabled: true,
      title: title,
      content: content,
      position: position,
      generationType: CtaGenerationType.manual,
      customPositionPercentage: customPositionPercentage,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Copy with method for updates
  CtaItem copyWith({
    String? id,
    bool? isEnabled,
    String? title,
    String? content,
    CtaPosition? position,
    CtaGenerationType? generationType,
    int? customPositionPercentage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CtaItem(
      id: id ?? this.id,
      isEnabled: isEnabled ?? this.isEnabled,
      title: title ?? this.title,
      content: content ?? this.content,
      position: position ?? this.position,
      generationType: generationType ?? this.generationType,
      customPositionPercentage:
          customPositionPercentage ?? this.customPositionPercentage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Check if CTA needs content generation
  bool get needsGeneration =>
      generationType == CtaGenerationType.automatic && content.isEmpty;

  /// Get position description for UI
  String get positionDescription {
    if (position == CtaPosition.custom && customPositionPercentage != null) {
      return '${position.displayName} ($customPositionPercentage%)';
    }
    return position.displayName;
  }

  factory CtaItem.fromJson(Map<String, dynamic> json) =>
      _$CtaItemFromJson(json);
  Map<String, dynamic> toJson() => _$CtaItemToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CtaItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Complete CTA configuration for the application
@JsonSerializable()
class CtaConfig {
  final List<CtaItem> ctas;
  final bool isEnabled; // Global CTA enable/disable
  final int maxCtas; // Maximum number of CTAs allowed
  final DateTime updatedAt;

  const CtaConfig({
    required this.ctas,
    required this.isEnabled,
    this.maxCtas = 4,
    required this.updatedAt,
  });

  /// Create empty CTA configuration
  factory CtaConfig.empty() {
    return CtaConfig(ctas: [], isEnabled: true, updatedAt: DateTime.now());
  }

  /// Create default CTA configuration with common CTAs
  factory CtaConfig.withDefaults() {
    final now = DateTime.now();
    return CtaConfig(
      ctas: [
        CtaItem.createAutomatic(
          title: 'CTA de Inscrição',
          position: CtaPosition.beginning,
        ),
        CtaItem.createAutomatic(
          title: 'CTA de Engajamento',
          position: CtaPosition.middle,
        ),
        CtaItem.createAutomatic(title: 'CTA Final', position: CtaPosition.end),
      ],
      isEnabled: true,
      updatedAt: now,
    );
  }

  /// Get enabled CTAs only
  List<CtaItem> get enabledCtas => ctas.where((cta) => cta.isEnabled).toList();

  /// Get CTAs that need content generation
  List<CtaItem> get ctasNeedingGeneration =>
      enabledCtas.where((cta) => cta.needsGeneration).toList();

  /// Check if can add more CTAs
  bool get canAddMore => ctas.length < maxCtas;

  /// Get available slots
  int get availableSlots => maxCtas - ctas.length;

  /// Add a new CTA
  CtaConfig addCta(CtaItem cta) {
    if (!canAddMore) {
      throw Exception('Maximum number of CTAs ($maxCtas) reached');
    }

    return copyWith(ctas: [...ctas, cta]);
  }

  /// Update an existing CTA
  CtaConfig updateCta(String ctaId, CtaItem updatedCta) {
    final index = ctas.indexWhere((cta) => cta.id == ctaId);
    if (index == -1) {
      throw Exception('CTA with ID $ctaId not found');
    }

    final newCtas = [...ctas];
    newCtas[index] = updatedCta;

    return copyWith(ctas: newCtas);
  }

  /// Remove a CTA
  CtaConfig removeCta(String ctaId) {
    return copyWith(ctas: ctas.where((cta) => cta.id != ctaId).toList());
  }

  /// Copy with method for updates
  CtaConfig copyWith({
    List<CtaItem>? ctas,
    bool? isEnabled,
    int? maxCtas,
    DateTime? updatedAt,
  }) {
    return CtaConfig(
      ctas: ctas ?? this.ctas,
      isEnabled: isEnabled ?? this.isEnabled,
      maxCtas: maxCtas ?? this.maxCtas,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  factory CtaConfig.fromJson(Map<String, dynamic> json) =>
      _$CtaConfigFromJson(json);
  Map<String, dynamic> toJson() => _$CtaConfigToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CtaConfig &&
          runtimeType == other.runtimeType &&
          ctas == other.ctas &&
          isEnabled == other.isEnabled &&
          maxCtas == other.maxCtas;

  @override
  int get hashCode => Object.hash(ctas, isEnabled, maxCtas);
}
