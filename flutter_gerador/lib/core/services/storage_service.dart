import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Serviço para gerenciar armazenamento seguro de configurações
class StorageService {
  static const String _apiKeyKey = 'gemini_api_key';
  static const String _openAIKeyKey = 'openai_api_key'; // 🤖 NOVO
  static const String _apiKeyHistoryKey = 'api_key_history';
  static const String _modelKey = 'selected_model';
  static const String _qualityModeKey = 'quality_mode';
  static const String _languageKey = 'selected_language';
  static const String _perspectiveKey = 'selected_perspective';
  static const String _measureTypeKey = 'selected_measure_type';
  static const String _quantityKey = 'selected_quantity';
  static const String _personalizedThemeKey = 'personalized_theme';
  static const String _usePersonalizedThemeKey = 'use_personalized_theme';
  static const String _localizationLevelKey = 'localization_level';

  /// Salva a chave API de forma segura (com hash bÃ¡sico para obscurecer)
  static Future<void> saveApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();

    if (apiKey.isEmpty) {
      await prefs.remove(_apiKeyKey);
      return;
    }

    // Aplicar hash bÃ¡sico para obscurecer a chave (nÃ£o Ã© criptografia real)
    final obscuredKey = _obscureKey(apiKey);
    await prefs.setString(_apiKeyKey, obscuredKey);

    // Adicionar ao histÃ³rico
    await _addToApiKeyHistory(apiKey);
  }

  /// Adiciona uma chave ao histÃ³rico (mantÃ©m apenas as Ãºltimas 5)
  static Future<void> _addToApiKeyHistory(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();

    // Obter histÃ³rico atual
    final history = await getApiKeyHistory();

    // Remover se jÃ¡ existe para evitar duplicatas
    history.removeWhere((key) => key == apiKey);

    // Adicionar no inÃ­cio
    history.insert(0, apiKey);

    // Manter apenas as Ãºltimas 5 chaves
    if (history.length > 5) {
      history.removeRange(5, history.length);
    }

    // Salvar histÃ³rico obscurecido
    final obscuredHistory = history.map((key) => _obscureKey(key)).toList();
    await prefs.setStringList(_apiKeyHistoryKey, obscuredHistory);
  }

  /// ObtÃ©m o histÃ³rico de chaves API (mÃ¡ximo 5)
  static Future<List<String>> getApiKeyHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final obscuredHistory = prefs.getStringList(_apiKeyHistoryKey) ?? [];

    // Desobscurecer as chaves
    return obscuredHistory
        .map((key) => _deobscureKey(key))
        .where((key) => key.isNotEmpty)
        .toList();
  }

  /// Remove uma chave especÃ­fica do histÃ³rico
  static Future<void> removeApiKeyFromHistory(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getApiKeyHistory();

    history.removeWhere((key) => key == apiKey);

    final obscuredHistory = history.map((key) => _obscureKey(key)).toList();
    await prefs.setStringList(_apiKeyHistoryKey, obscuredHistory);
  }

  /// Recupera a chave API salva
  static Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final obscuredKey = prefs.getString(_apiKeyKey);

    if (obscuredKey == null) return null;

    // Desobscurecer a chave
    return _deobscureKey(obscuredKey);
  }

  /// 🤖 Salva a chave OpenAI de forma segura
  static Future<void> saveOpenAIKey(String openAIKey) async {
    final prefs = await SharedPreferences.getInstance();

    if (openAIKey.isEmpty) {
      await prefs.remove(_openAIKeyKey);
      return;
    }

    final obscuredKey = _obscureKey(openAIKey);
    await prefs.setString(_openAIKeyKey, obscuredKey);
  }

  /// 🤖 Recupera a chave OpenAI salva
  static Future<String?> getOpenAIKey() async {
    final prefs = await SharedPreferences.getInstance();
    final obscuredKey = prefs.getString(_openAIKeyKey);

    if (obscuredKey == null) return null;

    return _deobscureKey(obscuredKey);
  }

  /// Salva o modelo selecionado
  static Future<void> saveSelectedModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modelKey, model);
  }

  /// Recupera o modelo selecionado
  static Future<String?> getSelectedModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_modelKey);
  }

  /// Salva as configuraÃ§Ãµes do usuÃ¡rio
  static Future<void> saveUserPreferences({
    String? language,
    String? perspective,
    String? measureType,
    int? quantity,
    String? personalizedTheme,
    bool? usePersonalizedTheme,
    String? localizationLevel,
    String? qualityMode,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (language != null) await prefs.setString(_languageKey, language);
    if (perspective != null) {
      await prefs.setString(_perspectiveKey, perspective);
    }
    if (measureType != null) {
      await prefs.setString(_measureTypeKey, measureType);
    }
    if (quantity != null) await prefs.setInt(_quantityKey, quantity);
    if (personalizedTheme != null) {
      await prefs.setString(_personalizedThemeKey, personalizedTheme);
    }
    if (usePersonalizedTheme != null) {
      await prefs.setBool(_usePersonalizedThemeKey, usePersonalizedTheme);
    }
    if (localizationLevel != null) {
      await prefs.setString(_localizationLevelKey, localizationLevel);
    }
    if (qualityMode != null) {
      await prefs.setString(_qualityModeKey, qualityMode);
    }
  }

  /// Recupera as configuraÃ§Ãµes do usuÃ¡rio
  static Future<Map<String, dynamic>> getUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'language': prefs.getString(_languageKey) ?? 'PortuguÃªs',
      'perspective': prefs.getString(_perspectiveKey) ?? 'terceira_pessoa',
      'measureType': prefs.getString(_measureTypeKey) ?? 'palavras',
      'quantity': prefs.getInt(_quantityKey) ?? 2000,
      'personalizedTheme': prefs.getString(_personalizedThemeKey) ?? '',
      'usePersonalizedTheme': prefs.getBool(_usePersonalizedThemeKey) ?? false,
      'localizationLevel': prefs.getString(_localizationLevelKey) ?? 'national',
      'qualityMode': prefs.getString(_qualityModeKey) ?? 'pro',
    };
  }

  /// Remove a chave API salva
  static Future<void> clearApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_apiKeyKey);
  }

  /// Verifica se existe uma chave API salva
  static Future<bool> hasApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_apiKeyKey);
  }

  // MÃ©todos privados para obscurecer/desobscurecer a chave
  static String _obscureKey(String key) {
    // Hash simples para obscurecer (nÃ£o Ã© seguranÃ§a real, apenas visual)
    final bytes = utf8.encode('${key}flutter_gerador_salt');
    final digest = sha256.convert(bytes);

    // Combinamos o hash com a chave original de forma reversÃ­vel
    final combined = base64.encode(utf8.encode(key));
    return '$digest:$combined';
  }

  static String _deobscureKey(String obscuredKey) {
    try {
      final parts = obscuredKey.split(':');
      if (parts.length != 2) return '';

      // Recuperar a chave original da parte base64
      final originalBytes = base64.decode(parts[1]);
      return utf8.decode(originalBytes);
    } catch (e) {
      return '';
    }
  }

  /// Limpa todas as configuraÃ§Ãµes salvas (para debug/reset)
  static Future<void> clearAllSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
