class LicenseModel {
  final String licenseKey;
  final String clientName;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool isActive;
  final int maxGenerations;
  final int usedGenerations;

  const LicenseModel({
    required this.licenseKey,
    required this.clientName,
    required this.createdAt,
    this.expiresAt,
    this.isActive = true,
    this.maxGenerations = -1, // -1 = unlimited
    this.usedGenerations = 0,
  });

  LicenseModel copyWith({
    String? licenseKey,
    String? clientName,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? isActive,
    int? maxGenerations,
    int? usedGenerations,
  }) {
    return LicenseModel(
      licenseKey: licenseKey ?? this.licenseKey,
      clientName: clientName ?? this.clientName,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
      maxGenerations: maxGenerations ?? this.maxGenerations,
      usedGenerations: usedGenerations ?? this.usedGenerations,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'licenseKey': licenseKey,
      'clientName': clientName,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'isActive': isActive,
      'maxGenerations': maxGenerations,
      'usedGenerations': usedGenerations,
    };
  }

  factory LicenseModel.fromJson(Map<String, dynamic> json) {
    return LicenseModel(
      licenseKey: json['licenseKey'],
      clientName: json['clientName'],
      createdAt: DateTime.parse(json['createdAt']),
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
      isActive: json['isActive'] ?? true,
      maxGenerations: json['maxGenerations'] ?? -1,
      usedGenerations: json['usedGenerations'] ?? 0,
    );
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  bool get hasGenerationsLeft {
    if (maxGenerations == -1) return true; // unlimited
    return usedGenerations < maxGenerations;
  }

  bool get isValid {
    return isActive && !isExpired && hasGenerationsLeft;
  }
}
