import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

class GenerationButton extends StatelessWidget {
  final bool isFormValid;
  final bool isGenerating;
  final VoidCallback onPressed;

  const GenerationButton({
    super.key,
    required this.isFormValid,
    required this.isGenerating,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: isFormValid && !isGenerating ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.fireOrange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: isGenerating
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  SizedBox(width: 8),
                  Text(AppStrings.generating),
                ],
              )
            : const Text(AppStrings.generateButton, style: TextStyle(fontSize: 16)),
      ),
    );
  }
}
