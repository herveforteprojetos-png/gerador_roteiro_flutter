class ValidationUtils {
  static bool isValidApiKey(String apiKey, String model) {
    if (apiKey.isEmpty) return false;
    
    switch (model) {
      case 'gemini-pro':
      case 'gemini-2.5-pro':
        // Gemini API keys geralmente começam com "AIza" e têm 39 caracteres
        return apiKey.startsWith('AIza') && apiKey.length == 39;
      case 'gpt-4':
      case 'gpt-3.5-turbo':
        // OpenAI API keys começam com "sk-" e têm 51 caracteres
        return apiKey.startsWith('sk-') && apiKey.length == 51;
      case 'claude-3':
        // Claude API keys começam com "sk-ant-" 
        return apiKey.startsWith('sk-ant-') && apiKey.length > 20;
      default:
        return apiKey.length >= 20; // Validação genérica
    }
  }

  static String? validateApiKey(String value, String model) {
    if (value.isEmpty) {
      return 'Chave da API é obrigatória';
    }
    
    if (!isValidApiKey(value, model)) {
      switch (model) {
        case 'gemini-pro':
        case 'gemini-2.5-pro':
        case 'gemini-2.5-pro': // CORREÇÃO: Apenas Pro 2.5 disponível
          return 'Chave Gemini inválida (deve começar com "AIza")';
        case 'gpt-4':
        case 'gpt-3.5-turbo':
          return 'Chave OpenAI inválida (deve começar com "sk-")';
        case 'claude-3':
          return 'Chave Claude inválida (deve começar com "sk-ant-")';
        default:
          return 'Formato de chave inválido';
      }
    }
    
    return null;
  }

  static String? validateTitle(String value) {
    if (value.trim().isEmpty) {
      return 'Título é obrigatório';
    }
    if (value.trim().length < 3) {
      return 'Título deve ter pelo menos 3 caracteres';
    }
    if (value.length > 100) {
      return 'Título deve ter no máximo 100 caracteres';
    }
    return null;
  }

  static String? validateContext(String value) {
    if (value.trim().isEmpty) {
      return 'Contexto é obrigatório';
    }
    if (value.trim().length < 10) {
      return 'Contexto deve ter pelo menos 10 caracteres';
    }
    if (value.length > 50000) {
      return 'Contexto deve ter no máximo 50.000 caracteres';
    }
    return null;
  }

  static bool isValidQuantity(int quantity, String measureType) {
    switch (measureType) {
      case 'palavras':
        return quantity >= 100 && quantity <= 100000;
      case 'caracteres':
        return quantity >= 500 && quantity <= 500000;
      default:
        return false;
    }
  }

  static String? validateQuantity(String value, String measureType) {
    final quantity = int.tryParse(value);
    if (quantity == null) {
      return 'Quantidade deve ser um número';
    }
    
    if (!isValidQuantity(quantity, measureType)) {
      switch (measureType) {
        case 'palavras':
          return 'Palavras: entre 100 e 100.000';
        case 'caracteres':
          return 'Caracteres: entre 500 e 500.000';
        default:
          return 'Quantidade inválida';
      }
    }
    
    return null;
  }

  static int getMinQuantity(String measureType) {
    switch (measureType) {
      case 'palavras':
        return 100;
      case 'caracteres':
        return 500;
      default:
        return 100;
    }
  }

  static int getMaxQuantity(String measureType) {
    switch (measureType) {
      case 'palavras':
        return 100000;
      case 'caracteres':
        return 500000;
      default:
        return 100000;
    }
  }
}
