/// 🧪 Demo da função lowercaseExceptNames
/// Teste simples para validar comportamento em cenário real
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gerador/data/services/gemini/validation/post_generation_fixer.dart';

void main() {
  test('Demo: normalização de casing em roteiro real', () {
    // Simula texto gerado pelo Gemini com capitalização inconsistente
    const geminiOutput = '''
Para Mariana. O Presidente Costa Falou Com Ela.
Depois, Mariana Foi Até A Escola Municipal.
Lá, Encontrou Dona Helena E Doutor Álvaro.
''';

    // Nomes conhecidos do roteiro (registrados pelo sistema)
    final knownCharacters = {
      'Mariana',
      'Costa', 
      'Helena',
      'Álvaro',
    };

    // Aplicar normalização
    final normalized = PostGenerationFixer.lowercaseExceptNames(
      geminiOutput,
      knownNames: knownCharacters,
    );

    print('\n📝 TEXTO ORIGINAL (Gemini):');
    print(geminiOutput);
    print('\n✅ TEXTO NORMALIZADO:');
    print(normalized);

    // Validações
    expect(normalized, contains('para Mariana')); // 'para' em lowercase
    expect(normalized, contains('Mariana')); // Nome preservado
    expect(normalized, contains('presidente Costa')); // 'presidente' lowercase, 'Costa' preservado
    expect(normalized, contains('escola municipal')); // Tudo lowercase (não são nomes)
    expect(normalized, contains('Helena')); // Nome preservado
    expect(normalized, contains('Álvaro')); // Nome com acento preservado
    
    // Palavras comuns devem estar em lowercase
    expect(normalized, isNot(contains('Presidente'))); // Não é nome
    expect(normalized, isNot(contains('Escola'))); // Não é nome
    expect(normalized, isNot(contains('Municipal'))); // Não é nome
    expect(normalized, isNot(contains('Doutor'))); // Não é nome (a menos que seja parte do nome)
  });

  test('Demo: exemplo do requisito original', () {
    const input = 'Para Mariana. O Presidente Costa.';
    
    print('\n📌 EXEMPLO DO REQUISITO:');
    print('Input: "$input"');
    
    // Sem nomes conhecidos
    final withoutNames = PostGenerationFixer.lowercaseExceptNames(input);
    print('Sem nomes conhecidos: "$withoutNames"');
    expect(withoutNames, 'para mariana. o presidente costa.');
    
    // Com nomes conhecidos
    final withNames = PostGenerationFixer.lowercaseExceptNames(
      input,
      knownNames: {'Mariana', 'Costa'},
    );
    print('Com Mariana e Costa conhecidos: "$withNames"');
    expect(withNames, 'para Mariana. o presidente Costa.');
  });

  test('Demo: log de output para inspeção visual', () {
    final testCases = [
      {
        'input': 'MARIANA DISSE PARA COSTA QUE HELENA ESTAVA LÁ.',
        'names': {'Mariana', 'Costa', 'Helena'},
      },
      {
        'input': 'na escola, Pedro encontrou Ana e Maria.',
        'names': {'Pedro', 'Ana', 'Maria'},
      },
      {
        'input': 'O Dr. Álvaro e a Dra. Cecília conversaram.',
        'names': {'Álvaro', 'Cecília'},
      },
    ];

    print('\n🔍 LOG DE OUTPUTS:\n');
    for (final testCase in testCases) {
      final input = testCase['input'] as String;
      final names = testCase['names'] as Set<String>;
      
      final output = PostGenerationFixer.lowercaseExceptNames(
        input,
        knownNames: names,
      );
      
      print('INPUT:  $input');
      print('NAMES:  ${names.join(', ')}');
      print('OUTPUT: $output');
      print('─' * 60);
    }

    expect(true, isTrue); // Teste sempre passa, só para ver logs
  });
}
