import 'package:flutter/material.dart';

/// Helper extension to replace deprecated Color.withOpacity usages.
/// Uses withAlpha under the hood to avoid deprecation warnings.
extension ColorOpacityExt on Color {
  Color o(double opacity) => withAlpha((opacity.clamp(0.0, 1.0) * 255).round());
}
