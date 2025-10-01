import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Sistema de design unificado para manter consistência na interface
class AppDesignSystem {
  // ======== TIPOGRAFIA ========
  static const TextStyle headingLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.normal,
    color: Colors.white,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.normal,
    color: Colors.white,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.normal,
    color: Colors.grey,
  );

  // ======== ESPAÇAMENTOS ========
  static const double spacingXS = 4.0;
  static const double spacingS = 6.0;
  static const double spacingM = 8.0;
  static const double spacingL = 12.0;
  static const double spacingXL = 16.0;
  static const double spacingXXL = 20.0;

  // ======== PADDING PADRÕES ========
  static const EdgeInsets paddingXS = EdgeInsets.all(spacingXS);
  static const EdgeInsets paddingS = EdgeInsets.all(spacingS);
  static const EdgeInsets paddingM = EdgeInsets.all(spacingM);
  static const EdgeInsets paddingL = EdgeInsets.all(spacingL);
  static const EdgeInsets paddingXL = EdgeInsets.all(spacingXL);

  static const EdgeInsets paddingHorizontalS = EdgeInsets.symmetric(horizontal: spacingS);
  static const EdgeInsets paddingHorizontalM = EdgeInsets.symmetric(horizontal: spacingM);
  static const EdgeInsets paddingHorizontalL = EdgeInsets.symmetric(horizontal: spacingL);
  static const EdgeInsets paddingHorizontalXL = EdgeInsets.symmetric(horizontal: spacingXL);

  static const EdgeInsets paddingVerticalS = EdgeInsets.symmetric(vertical: spacingS);
  static const EdgeInsets paddingVerticalM = EdgeInsets.symmetric(vertical: spacingM);
  static const EdgeInsets paddingVerticalL = EdgeInsets.symmetric(vertical: spacingL);

  // ======== COMPONENTES ========
  
  /// Altura padrão para campos de entrada
  static const double fieldHeight = 40.0;
  
  /// Raio de borda padrão
  static const double borderRadius = 8.0;
  
  /// Altura do header compacto
  static const double headerHeight = 50.0;
  
  /// Altura das abas de workspace
  static const double tabHeight = 45.0;

  // ======== DECORAÇÕES ========
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: AppColors.darkCard,
    borderRadius: BorderRadius.circular(borderRadius),
    border: Border.all(color: AppColors.fireOrange.withOpacity(0.3)),
  );

  static BoxDecoration get headerDecoration => BoxDecoration(
    color: AppColors.darkSecondary,
    border: Border(
      bottom: BorderSide(color: AppColors.fireOrange, width: 2),
    ),
  );

  static InputDecoration getInputDecoration({
    required String hint,
    String? label,
    Widget? suffixIcon,
  }) => InputDecoration(
    labelText: label,
    hintText: hint,
    suffixIcon: suffixIcon,
    labelStyle: labelMedium.copyWith(color: Colors.grey[400]),
    hintStyle: bodyMedium.copyWith(color: Colors.grey[600]),
    contentPadding: paddingHorizontalL.add(paddingVerticalM),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(color: Colors.grey[700]!),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(color: AppColors.fireOrange),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(color: Colors.grey[700]!),
    ),
    filled: true,
    fillColor: AppColors.darkSecondary,
  );

  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: AppColors.fireOrange,
    foregroundColor: Colors.white,
    padding: paddingHorizontalXL.add(paddingVerticalM),
    textStyle: labelMedium.copyWith(fontWeight: FontWeight.bold),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
    ),
    minimumSize: Size(0, fieldHeight),
  );

  static ButtonStyle get secondaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: AppColors.darkSecondary,
    foregroundColor: Colors.white,
    padding: paddingHorizontalL.add(paddingVerticalM),
    textStyle: labelMedium,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      side: BorderSide(color: AppColors.fireOrange.withOpacity(0.5)),
    ),
    minimumSize: Size(0, fieldHeight),
  );

  // ======== SPACING HELPERS ========
  static Widget get verticalSpaceXS => SizedBox(height: spacingXS);
  static Widget get verticalSpaceS => SizedBox(height: spacingS);
  static Widget get verticalSpaceM => SizedBox(height: spacingM);
  static Widget get verticalSpaceL => SizedBox(height: spacingL);
  static Widget get verticalSpaceXL => SizedBox(height: spacingXL);

  static Widget get horizontalSpaceXS => SizedBox(width: spacingXS);
  static Widget get horizontalSpaceS => SizedBox(width: spacingS);
  static Widget get horizontalSpaceM => SizedBox(width: spacingM);
  static Widget get horizontalSpaceL => SizedBox(width: spacingL);
  static Widget get horizontalSpaceXL => SizedBox(width: spacingXL);
}
