import 'dart:convert';
import 'dart:io';

class ApiValidationService {
  /// Testa se a chave da API Gemini é válida fazendo uma chamada real
  static Future<ApiValidationResult> validateGeminiApiKey(String apiKey) async {
    if (apiKey.isEmpty) {
      return ApiValidationResult(
        isValid: false,
        errorMessage: 'Chave da API é obrigatória',
        errorType: ApiErrorType.empty,
      );
    }

    // Validação de formato básico
    if (!apiKey.startsWith('AIza') || apiKey.length != 39) {
      return ApiValidationResult(
        isValid: false,
        errorMessage: 'Formato inválido (deve começar com "AIza" e ter 39 caracteres)',
        errorType: ApiErrorType.invalidFormat,
      );
    }

    try {
      // Teste real da API com uma requisição simples
      final client = HttpClient();
      final request = await client.getUrl(
        Uri.parse('https://generativelanguage.googleapis.com/v1/models?key=$apiKey'),
      );
      
      request.headers.set('Content-Type', 'application/json');
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      
      client.close();

      if (response.statusCode == 200) {
        // API válida
        return ApiValidationResult(
          isValid: true,
          errorMessage: null,
          errorType: null,
        );
      } else if (response.statusCode == 400) {
        // Chave inválida
        final responseData = json.decode(responseBody);
        final errorMessage = responseData['error']?['message'] ?? 'Chave da API inválida';
        
        return ApiValidationResult(
          isValid: false,
          errorMessage: 'Chave inválida: $errorMessage',
          errorType: ApiErrorType.invalidKey,
        );
      } else if (response.statusCode == 403) {
        // Chave sem permissão ou bloqueada
        return ApiValidationResult(
          isValid: false,
          errorMessage: 'Chave sem permissão ou bloqueada',
          errorType: ApiErrorType.forbidden,
        );
      } else {
        // Outro erro
        return ApiValidationResult(
          isValid: false,
          errorMessage: 'Erro ao validar API (código ${response.statusCode})',
          errorType: ApiErrorType.networkError,
        );
      }
    } catch (e) {
      // Erro de conexão
      return ApiValidationResult(
        isValid: false,
        errorMessage: 'Erro de conexão: ${e.toString()}',
        errorType: ApiErrorType.connectionError,
      );
    }
  }
}

class ApiValidationResult {
  final bool isValid;
  final String? errorMessage;
  final ApiErrorType? errorType;

  ApiValidationResult({
    required this.isValid,
    this.errorMessage,
    this.errorType,
  });
}

enum ApiErrorType {
  empty,
  invalidFormat,
  invalidKey,
  forbidden,
  networkError,
  connectionError,
}

enum ValidationState {
  initial,     // Estado inicial, sem validação
  validating,  // Validando a chave
  valid,       // Chave válida
  invalid,     // Chave inválida
}
