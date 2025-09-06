import 'package:flutter/material.dart';
import 'package:flutter_gerador/core/constants/app_colors.dart';
import 'package:flutter_gerador/core/constants/app_strings.dart';

class ApiConfigSection extends StatefulWidget {
  final TextEditingController apiKeyController;
  final String selectedModel;
  final ValueChanged<String?> onModelChanged;

  const ApiConfigSection({
    super.key,
    required this.apiKeyController,
    required this.selectedModel,
    required this.onModelChanged,
  });

  @override
  State<ApiConfigSection> createState() => _ApiConfigSectionState();
}

class _ApiConfigSectionState extends State<ApiConfigSection> {
  String? _apiError;
  bool get _isApiKeyValid => widget.apiKeyController.text.isNotEmpty && widget.apiKeyController.text.length >= 20;

  @override
  void initState() {
    super.initState();
    widget.apiKeyController.addListener(_validateApiKey);
  }

  @override
  void dispose() {
    widget.apiKeyController.removeListener(_validateApiKey);
    super.dispose();
  }

  void _validateApiKey() {
    setState(() {
      if (widget.apiKeyController.text.isEmpty) {
        _apiError = 'Informe a chave da API Gemini.';
      } else if (widget.apiKeyController.text.length < 20) {
        _apiError = 'Chave muito curta ou inválida.';
      } else {
        _apiError = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          alignment: Alignment.centerRight,
          children: [
            TextField(
              controller: widget.apiKeyController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: AppStrings.apiKeyLabel,
                prefixIcon: Icon(Icons.key, color: AppColors.fireOrange),
                border: OutlineInputBorder(),
                suffixIcon: _isApiKeyValid
                    ? Icon(Icons.check_circle, color: Colors.green)
                    : null,
              ),
            ),
          ],
        ),
        if (_apiError != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              _apiError!,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: widget.selectedModel,
          decoration: InputDecoration(labelText: AppStrings.modelLabel),
          items: const [
            DropdownMenuItem(value: 'gemini-2.5-pro', child: Text('Gemini 2.5 Pro')),
            DropdownMenuItem(value: 'gemini-1.5-flash', child: Text('Gemini 1.5 Flash (Rápido)')),
          ],
          onChanged: widget.onModelChanged,
        ),
      ],
    );
  }
}
