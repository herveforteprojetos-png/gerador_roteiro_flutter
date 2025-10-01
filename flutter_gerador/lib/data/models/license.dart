class License {
  final String licenseKey;
  final LicenseType type;
  final DateTime? expiryDate;
  final String deviceId;
  final bool isActive;
  final DateTime createdAt;
  final int? usageLimit;
  final int usageCount;

  const License({
    required this.licenseKey,
    required this.type,
    this.expiryDate,
    required this.deviceId,
    required this.isActive,
    required this.createdAt,
    this.usageLimit,
    required this.usageCount,
  });

  factory License.demo(String deviceId) {
    return License(
      licenseKey: 'DEMO-DEMO-DEMO-DEMO',
      type: LicenseType.demo,
      expiryDate: null,
      deviceId: deviceId,
      isActive: true,
      createdAt: DateTime.now(),
      usageLimit: 10,
      usageCount: 0,
    );
  }

  factory License.lifetime(String licenseKey, String deviceId) {
    return License(
      licenseKey: licenseKey,
      type: LicenseType.lifetime,
      expiryDate: null,
      deviceId: deviceId,
      isActive: true,
      createdAt: DateTime.now(),
      usageLimit: null,
      usageCount: 0,
    );
  }

  License copyWith({
    String? licenseKey,
    LicenseType? type,
    DateTime? expiryDate,
    String? deviceId,
    bool? isActive,
    DateTime? createdAt,
    int? usageLimit,
    int? usageCount,
  }) {
    return License(
      licenseKey: licenseKey ?? this.licenseKey,
      type: type ?? this.type,
      expiryDate: expiryDate ?? this.expiryDate,
      deviceId: deviceId ?? this.deviceId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      usageLimit: usageLimit ?? this.usageLimit,
      usageCount: usageCount ?? this.usageCount,
    );
  }

  bool get isDemo => type == LicenseType.demo;
  bool get isLifetime => type == LicenseType.lifetime;
  bool get hasReachedLimit => usageLimit != null && usageCount >= usageLimit!;
  bool get canGenerate => isActive && !hasReachedLimit;
  int get remainingGenerations => usageLimit != null ? (usageLimit! - usageCount).clamp(0, usageLimit!) : -1;

  Map<String, dynamic> toJson() {
    return {
      'licenseKey': licenseKey,
      'type': type.name,
      'expiryDate': expiryDate?.toIso8601String(),
      'deviceId': deviceId,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'usageLimit': usageLimit,
      'usageCount': usageCount,
    };
  }

  factory License.fromJson(Map<String, dynamic> json) {
    return License(
      licenseKey: json['licenseKey'] as String,
      type: LicenseType.values.firstWhere((e) => e.name == json['type']),
      expiryDate: json['expiryDate'] != null ? DateTime.parse(json['expiryDate'] as String) : null,
      deviceId: json['deviceId'] as String,
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      usageLimit: json['usageLimit'] as int?,
      usageCount: json['usageCount'] as int,
    );
  }
}

enum LicenseType {
  demo,
  lifetime,
}

extension LicenseTypeExtension on LicenseType {
  String get displayName {
    switch (this) {
      case LicenseType.demo:
        return 'Demonstração';
      case LicenseType.lifetime:
        return 'Vitalícia';
    }
  }

  String get description {
    switch (this) {
      case LicenseType.demo:
        return '10 gerações gratuitas';
      case LicenseType.lifetime:
        return 'Uso ilimitado neste PC';
    }
  }
}
