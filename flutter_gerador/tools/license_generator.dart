// GERADOR DE CHAVES DE LICENÇA
// Execute este arquivo em um ambiente Dart/Flutter para gerar chaves para seus clientes

import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

class LicenseGenerator {
  static const String _secretKey = 'FLUTTER_GERADOR_SECRET_2024';
  
  // Gerar uma chave de licença única
  static String generateLicenseKey(String clientName) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final data = '$clientName-$timestamp-$_secretKey';
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    
    // Formatar como XXXX-XXXX-XXXX-XXXX
    final key = digest.toString().substring(0, 16).toUpperCase();
    return '${key.substring(0, 4)}-${key.substring(4, 8)}-${key.substring(8, 12)}-${key.substring(12, 16)}';
  }
  
  // Gerar múltiplas licenças
  static void generateBatchLicenses() {
    if (kDebugMode) {
      debugPrint('=== GERADOR DE CHAVES DE LICENÇA ===\n');
    }
    
    // Exemplos de clientes - substitua pelos seus clientes reais
    final clients = [
      {
        'name': 'João Silva',
        'maxGenerations': 50,
        'expiresInDays': 365,
      },
      {
        'name': 'Maria Santos',
        'maxGenerations': 100,
        'expiresInDays': 365,
      },
      {
        'name': 'Pedro Costa',
        'maxGenerations': -1, // Ilimitado
        'expiresInDays': null, // Sem expiração
      },
      {
        'name': 'Ana Oliveira',
        'maxGenerations': 25,
        'expiresInDays': 180,
      },
    ];
    
    for (final client in clients) {
      final licenseKey = generateLicenseKey(client['name'] as String);
      final maxGen = client['maxGenerations'] as int;
      final expireDays = client['expiresInDays'] as int?;
      
      if (kDebugMode) {
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        debugPrint('Cliente: ${client['name']}');
        debugPrint('Chave de Licença: $licenseKey');
        debugPrint('Gerações: ${maxGen == -1 ? 'Ilimitadas' : maxGen}');
        if (expireDays != null) {
          final expiryDate = DateTime.now().add(Duration(days: expireDays));
          debugPrint('Expira em: ${expiryDate.day}/${expiryDate.month}/${expiryDate.year}');
        } else {
          debugPrint('Expira em: Nunca');
        }
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
      }
    }
  }
  
  // Gerar chave individual
  static void generateSingleLicense() {
    if (kDebugMode) {
      debugPrint('=== GERADOR DE CHAVE INDIVIDUAL ===\n');
    }
    
    stdout.write('Nome do cliente: ');
    final clientName = stdin.readLineSync() ?? '';
    
    if (clientName.isEmpty) {
      if (kDebugMode) {
        debugPrint('Nome do cliente é obrigatório!');
      }
      return;
    }
    
    stdout.write('Número máximo de gerações (-1 para ilimitado): ');
    final maxGenInput = stdin.readLineSync() ?? '';
    final maxGenerations = int.tryParse(maxGenInput) ?? -1;
    
    stdout.write('Dias até expirar (deixe vazio para nunca): ');
    final expireDaysInput = stdin.readLineSync() ?? '';
    final expireDays = expireDaysInput.isEmpty ? null : int.tryParse(expireDaysInput);
    
    final licenseKey = generateLicenseKey(clientName);
    
    if (kDebugMode) {
      debugPrint('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('CHAVE DE LICENÇA GERADA');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('Cliente: $clientName');
      debugPrint('Chave: $licenseKey');
      debugPrint('Gerações: ${maxGenerations == -1 ? 'Ilimitadas' : maxGenerations}');
      if (expireDays != null) {
        final expiryDate = DateTime.now().add(Duration(days: expireDays));
        debugPrint('Expira em: ${expiryDate.day}/${expiryDate.month}/${expiryDate.year}');
      } else {
        debugPrint('Expira em: Nunca');
      }
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
      
      debugPrint('⚠️  IMPORTANTE: Adicione esta chave no código do LicenseService:');
      debugPrint("'$licenseKey': LicenseModel(");
      debugPrint("  licenseKey: '$licenseKey',");
      debugPrint("  clientName: '$clientName',");
      debugPrint("  createdAt: DateTime.now(),");
      if (expireDays != null) {
        debugPrint("  expiresAt: DateTime.now().add(Duration(days: $expireDays)),");
      }
      debugPrint("  maxGenerations: $maxGenerations,");
      debugPrint("),\n");
    }
  }
}

void main() {
  print('Escolha uma opção:');
  print('1 - Gerar chaves em lote (exemplos)');
  print('2 - Gerar chave individual');
  print('Digite sua escolha (1 ou 2): ');
  
  final choice = stdin.readLineSync();
  
  switch (choice) {
    case '1':
      LicenseGenerator.generateBatchLicenses();
      break;
    case '2':
      LicenseGenerator.generateSingleLicense();
      break;
    default:
      print('Opção inválida!');
  }
  
  print('\nPressione Enter para sair...');
  stdin.readLineSync();
}
