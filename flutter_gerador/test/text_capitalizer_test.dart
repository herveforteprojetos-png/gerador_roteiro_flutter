/// 🧪 Testes do TextCapitalizer v7.6.136
/// 
/// Testa a nova lógica: Gemini envia minúsculo + NOMES MAIÚSCULOS
/// Esta classe normaliza para exibição ao usuário

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gerador/data/utils/text_capitalizer.dart';

void main() {
  group('🔤 TextCapitalizer v7.6.136', () {
    // ═══════════════════════════════════════════════════════════════════════
    // 🎯 normalizeGeminiOutput - Método Principal
    // ═══════════════════════════════════════════════════════════════════════
    
    group('normalizeGeminiOutput', () {
      test('converte NOME MAIÚSCULO para Title Case', () {
        const input = 'MATEUS olhava o relógio.';
        const expected = 'Mateus olhava o relógio.';
        expect(TextCapitalizer.normalizeGeminiOutput(input), expected);
      });

      test('converte múltiplos nomes', () {
        const input = 'MATEUS falou com HELENA sobre CÉSAR.';
        const expected = 'Mateus falou com Helena sobre César.';
        expect(TextCapitalizer.normalizeGeminiOutput(input), expected);
      });

      test('capitaliza início de frases', () {
        const input = 'MATEUS olhava. ele sorriu. então foi embora.';
        const expected = 'Mateus olhava. Ele sorriu. Então foi embora.';
        expect(TextCapitalizer.normalizeGeminiOutput(input), expected);
      });

      test('capitaliza após pontuação ! e ?', () {
        const input = 'MATEUS gritou! ela correu? sim, correu.';
        const expected = 'Mateus gritou! Ela correu? Sim, correu.';
        expect(TextCapitalizer.normalizeGeminiOutput(input), expected);
      });

      test('capitaliza após newline', () {
        const input = 'MATEUS falou.\nela ouviu.\nentão sorriu.';
        const expected = 'Mateus falou.\nEla ouviu.\nEntão sorriu.';
        expect(TextCapitalizer.normalizeGeminiOutput(input), expected);
      });

      test('preserva nomes com acentos', () {
        const input = 'CÉSAR e ÁLVARO conversavam com INÊS.';
        const expected = 'César e Álvaro conversavam com Inês.';
        expect(TextCapitalizer.normalizeGeminiOutput(input), expected);
      });

      test('extrai nomes para set externo', () {
        const input = 'MATEUS falou com HELENA.';
        final names = <String>{};
        TextCapitalizer.normalizeGeminiOutput(input, extractedNames: names);
        expect(names, containsAll(['MATEUS', 'HELENA']));
      });

      test('ignora texto vazio', () {
        expect(TextCapitalizer.normalizeGeminiOutput(''), '');
      });

      test('nome no início de frase (já maiúsculo)', () {
        const input = 'OTÁVIO entrou na sala. ele sentou.';
        const expected = 'Otávio entrou na sala. Ele sentou.';
        expect(TextCapitalizer.normalizeGeminiOutput(input), expected);
      });
    });

    // ═══════════════════════════════════════════════════════════════════════
    // 🔍 extractUppercaseNames - Extração de Nomes
    // ═══════════════════════════════════════════════════════════════════════
    
    group('extractUppercaseNames', () {
      test('detecta nomes TODO MAIÚSCULOS', () {
        const text = 'MATEUS olhava HELENA na sala.';
        final names = TextCapitalizer.extractUppercaseNames(text);
        expect(names, containsAll(['MATEUS', 'HELENA']));
      });

      test('ignora palavras de 1 letra', () {
        const text = 'A MATEUS deu o livro.';
        final names = TextCapitalizer.extractUppercaseNames(text);
        expect(names, contains('MATEUS'));
        expect(names, isNot(contains('A')));
      });

      test('ignora palavras comuns maiúsculas', () {
        const text = 'EU falei MAS ele não ouviu.';
        final names = TextCapitalizer.extractUppercaseNames(text);
        expect(names, isEmpty);
      });

      test('detecta nomes com acentos', () {
        const text = 'CÉSAR falou com ÁLVARO e INÊS.';
        final names = TextCapitalizer.extractUppercaseNames(text);
        expect(names, containsAll(['CÉSAR', 'ÁLVARO', 'INÊS']));
      });

      test('ignora palavras mistas (não todo maiúsculo)', () {
        const text = 'Mateus olhava Helena.';
        final names = TextCapitalizer.extractUppercaseNames(text);
        expect(names, isEmpty);
      });

      test('detecta nomes curtos válidos (2+ letras)', () {
        const text = 'LU e ANA conversavam.';
        final names = TextCapitalizer.extractUppercaseNames(text);
        expect(names, containsAll(['LU', 'ANA']));
      });
    });

    // ═══════════════════════════════════════════════════════════════════════
    // 📊 isGeminiFormat - Validação de Formato
    // ═══════════════════════════════════════════════════════════════════════
    
    group('isGeminiFormat', () {
      test('detecta formato Gemini válido', () {
        const text = 'MATEUS olhava o relógio. ele sorriu para HELENA.';
        expect(TextCapitalizer.isGeminiFormat(text), isTrue);
      });

      test('rejeita texto todo maiúsculo', () {
        const text = 'MATEUS OLHAVA O RELÓGIO. ELE SORRIU.';
        expect(TextCapitalizer.isGeminiFormat(text), isFalse);
      });

      test('rejeita texto tradicional (Title Case)', () {
        const text = 'Mateus olhava o relógio. Ele sorriu para Helena.';
        // Não tem palavras MAIÚSCULAS, então não é formato Gemini
        expect(TextCapitalizer.isGeminiFormat(text), isFalse);
      });

      test('rejeita texto vazio', () {
        expect(TextCapitalizer.isGeminiFormat(''), isFalse);
      });

      test('aceita proporção correta (>70% minúsculas)', () {
        const text = 'MATEUS olhava o relógio na parede do escritório cinzento.';
        expect(TextCapitalizer.isGeminiFormat(text), isTrue);
      });
    });

    // ═══════════════════════════════════════════════════════════════════════
    // 🔧 analyzeText - Análise de Debug
    // ═══════════════════════════════════════════════════════════════════════
    
    group('analyzeText', () {
      test('retorna análise completa', () {
        const text = 'MATEUS olhava HELENA. ele sorriu.';
        final analysis = TextCapitalizer.analyzeText(text);
        
        expect(analysis['isGeminiFormat'], isTrue);
        expect(analysis['detectedNames'], containsAll(['MATEUS', 'HELENA']));
        expect(analysis['nameCount'], 2);
        expect(analysis['originalLength'], text.length);
        expect(analysis['normalizedSample'], isA<String>());
      });
    });

    // ═══════════════════════════════════════════════════════════════════════
    // 📝 Casos de Uso Reais
    // ═══════════════════════════════════════════════════════════════════════
    
    group('Casos Reais', () {
      test('parágrafo completo do roteiro', () {
        const input = '''MATEUS olhava o relógio na parede do escritório cinzento. faltavam apenas cinco minutos para a hora do almoço. ele suspirou, desviando os olhos do monitor do computador. na mesa ao lado, OTÁVIO digitava freneticamente, alheio ao mundo.''';
        
        final result = TextCapitalizer.normalizeGeminiOutput(input);
        
        // Verifica conversão de nomes
        expect(result, contains('Mateus'));
        expect(result, contains('Otávio'));
        expect(result, isNot(contains('MATEUS')));
        expect(result, isNot(contains('OTÁVIO')));
        
        // Verifica capitalização de início de frase
        expect(result, contains('Faltavam'));
        expect(result, contains('Ele'));
        expect(result, contains('Na'));
      });

      test('diálogo com múltiplos personagens', () {
        const input = '''MATEUS perguntou para HELENA se ela tinha visto CÉSAR. HELENA respondeu que CÉSAR tinha ido embora mais cedo.''';
        
        final result = TextCapitalizer.normalizeGeminiOutput(input);
        
        expect(result, contains('Mateus'));
        expect(result, contains('Helena'));
        expect(result, contains('César'));
        expect(result.split('César').length - 1, 2); // César aparece 2x
      });

      test('título de personagem (Doutor)', () {
        // Gemini pode enviar DOUTOR ÁLVARO como dois nomes
        const input = 'DOUTOR ÁLVARO entrou na sala.';
        final result = TextCapitalizer.normalizeGeminiOutput(input);
        
        expect(result, contains('Doutor'));
        expect(result, contains('Álvaro'));
      });

      test('nome composto', () {
        const input = 'MARIA HELENA conversava com PEDRO HENRIQUE.';
        final result = TextCapitalizer.normalizeGeminiOutput(input);
        
        expect(result, equals('Maria Helena conversava com Pedro Henrique.'));
      });
    });
  });
}
