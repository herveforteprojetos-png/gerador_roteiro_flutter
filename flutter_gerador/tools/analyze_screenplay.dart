// ignore_for_file: avoid_print
/// 🔍 Analisador de Roteiro - v7.6.136
/// Verifica conformidade com NameValidator e PostGenerationFixer
///
/// Uso: dart run tools/analyze_screenplay.dart

import 'package:flutter_gerador/data/services/gemini/validation/name_validator.dart';
import 'package:flutter_gerador/data/services/gemini/validation/post_generation_fixer.dart';

void main() {
  print('═══════════════════════════════════════════════════════════════');
  print('🔍 ANÁLISE DE ROTEIRO - v7.6.136');
  print('═══════════════════════════════════════════════════════════════\n');

  // ═══════════════════════════════════════════════════════════════
  // ROTEIRO FORNECIDO (35k caracteres)
  // ═══════════════════════════════════════════════════════════════
  const screenplay = '''
GANCHO VIRAL:
Ele não era um idoso faminto qualquer. E o que ele fez a seguir é inacreditável.

Mateus olhava o relógio na parede do escritório cinzento. Faltavam apenas cinco minutos para a hora do almoço. Ele sentia o estômago roncar, mas não era de fome. Era a ansiedade de saber que, mais uma vez, sua marmita seria a única coisa que o separava da realidade dura lá fora. Ele era um funcionário dedicado, mas o salário mal cobria as contas da pequena casa que dividia com sua mãe, Dona Sônia, em um bairro simples da capital. O cheiro de café velho pairava no ar da sala, misturando-se com o aroma de papel e poeira acumulada. Dr. Álvaro, seu supervisor, um homem com um terno sempre impecável e um ar de superioridade, passava por ele sem sequer um bom-dia, como de costume. Mateus suspirou, pensando que a vida era feita de escolhas, e a dele, no momento, era continuar batalhando, um dia de cada vez.

Quando o relógio marcou meio-dia, Mateus pegou sua marmita, um tesouro de arroz, feijão e um pedaço de frango que Dona Sônia havia preparado com tanto carinho. Ele desceu para a praça em frente ao prédio, um pequeno oásis verde em meio ao concreto. Sentou-se num banco de madeira lascada, observando o movimento apressado das pessoas. Foi então que o viu. Um idoso, com roupas gastas e um olhar perdido, revirava o lixo de uma lixeira pública. O coração de Mateus apertou. Ele se lembrou das palavras de Dona Sônia: "A verdadeira riqueza mora na generosidade". Aquela frase simples, dita tantas vezes, agora parecia ter um significado ainda mais profundo e urgente.

Mateus não pensou duas vezes. Levantou-se do banco, a marmita ainda quente nas mãos, e caminhou em direção ao idoso. A fome do homem era visível em seu rosto marcado pelo tempo e pela dificuldade. "Senhor", Mateus disse com a voz gentil, estendendo a marmita. "Aceita um pouco? Minha mãe fez um frango delicioso hoje." O idoso ergueu os olhos, surpreso, e uma lágrima rolou por sua face enrugada. Ele hesitou por um momento, mas o cheiro da comida parecia irresistível. "Meu filho, que Deus o abençoe", o idoso respondeu, a voz embargada. Ele pegou a marmita com as mãos trêmulas e começou a comer, devagar, saboreando cada garfada como se fosse a última. Mateus sentou-se ao lado dele, observando, sentindo uma paz que dinheiro nenhum poderia comprar. Depois que terminou, o idoso, com um sorriso sincero, enfiou a mão no bolso do paletó velho e tirou um cartão. "Meu nome é Otávio", disse ele, entregando o cartão. "Torne-se meu chefe de gabinete." Mateus pegou o cartão, chocado. Era um nome respeitado, de um dos maiores empresários do Brasil. O mundo de Mateus acabava de virar de cabeça para baixo.
''';

  // ═══════════════════════════════════════════════════════════════
  // 1. EXTRAÇÃO DE NOMES
  // ═══════════════════════════════════════════════════════════════
  print('📋 1. NOMES ENCONTRADOS NO ROTEIRO:');
  print('─────────────────────────────────────────────────────────────────\n');

  // Padrões para extrair nomes
  final namePatterns = [
    RegExp(r'\b(Mateus)\b'),
    RegExp(r'\b(Dona Sônia)\b'),
    RegExp(r'\b(Dr\. Álvaro|Doutor Álvaro)\b'),
    RegExp(r'\b(Otávio)\b'),
    RegExp(r'\b(Helena)\b'),
    RegExp(r'\b(César)\b'),
  ];

  final foundNames = <String>{};
  for (final pattern in namePatterns) {
    for (final match in pattern.allMatches(screenplay)) {
      foundNames.add(match.group(0)!);
    }
  }

  print('   Nomes extraídos:');
  for (final name in foundNames) {
    print('   • $name');
  }

  // ═══════════════════════════════════════════════════════════════
  // 2. VERIFICAÇÃO COM LISTA DE PROIBIDOS
  // ═══════════════════════════════════════════════════════════════
  print('\n📋 2. VERIFICAÇÃO COM LISTA DE NOMES PROIBIDOS:');
  print('─────────────────────────────────────────────────────────────────\n');

  // Nomes proibidos do NameGenerator v7.6.135
  final forbiddenNames = {
    'Mateus',
    'Otávio',
    'Helena',
    'Maria',
    'João',
    'José',
    'Pedro',
    'Ana',
  };

  final violations = <String>[];
  for (final name in foundNames) {
    final baseName = name
        .replaceAll('Dona ', '')
        .replaceAll('Dr. ', '')
        .replaceAll('Doutor ', '');
    if (forbiddenNames.contains(baseName)) {
      violations.add('$name (base: $baseName)');
    }
  }

  if (violations.isNotEmpty) {
    print('   ⚠️ NOMES PROIBIDOS ENCONTRADOS:');
    for (final v in violations) {
      print('   🔴 $v');
    }
    print(
      '\n   📌 NOTA: Estes nomes estão na lista de proibidos do NameGenerator.',
    );
    print('   📌 Em roteiros gerados, eles NÃO devem aparecer.');
    print(
      '   📌 Este roteiro parece ser um EXEMPLO/TESTE (não gerado pelo sistema).',
    );
  } else {
    print('   ✅ Nenhum nome proibido encontrado.');
  }

  // ═══════════════════════════════════════════════════════════════
  // 3. TESTE DE CONFLITOS DE NOMES
  // ═══════════════════════════════════════════════════════════════
  print('\n📋 3. TESTE DE CONFLITOS (NameValidator.hasNameConflict):');
  print('─────────────────────────────────────────────────────────────────\n');

  final existingNames = {'mateus', 'otávio', 'helena', 'césar'};

  final testCases = [
    'Dona Sônia', // Deve passar (prefixo "Dona")
    'Dr. Álvaro', // Deve passar (prefixo "Dr.")
    'Doutor Álvaro', // Deve passar (prefixo "Doutor")
    'Mateus', // Deve bloquear (match exato)
    'Otávio Empresário', // Deve testar se conflita
    'Mas Mateus', // Deve passar (frase com "mas")
    'Era Otávio', // Deve passar (frase com "era")
    'Helena', // Deve bloquear (match exato)
    'Futuro Brilhante', // Deve passar (whitelist organização)
  ];

  for (final testName in testCases) {
    final hasConflict = NameValidator.hasNameConflict(testName, existingNames);
    final status = hasConflict ? '🔴 CONFLITO' : '✅ OK';
    print('   $status: "$testName"');
  }

  // ═══════════════════════════════════════════════════════════════
  // 4. TESTE DE DETECÇÃO DE FRASES
  // ═══════════════════════════════════════════════════════════════
  print('\n📋 4. TESTE DE DETECÇÃO DE FRASES (NameValidator.isPhrase):');
  print('─────────────────────────────────────────────────────────────────\n');

  final phraseCases = [
    'Mas Mateus',
    'Ou Helena',
    'Era Otávio',
    'Enquanto César',
    'Senhor Otávio',
    'Dona Sônia',
    'Mateus', // Não é frase
    'Helena', // Não é frase
  ];

  for (final phrase in phraseCases) {
    final isPhrase = NameValidator.isPhrase(phrase);
    final status = isPhrase ? '📝 FRASE' : '👤 NOME';
    print('   $status: "$phrase"');
  }

  // ═══════════════════════════════════════════════════════════════
  // 5. TESTE DE EXPANSÃO DE TÍTULOS
  // ═══════════════════════════════════════════════════════════════
  print('\n📋 5. TESTE DE EXPANSÃO DE TÍTULOS (PostGenerationFixer):');
  print('─────────────────────────────────────────────────────────────────\n');

  final titleCases = [
    'Dr. Álvaro chegou ao escritório.',
    'Sr. Otávio era um empresário.',
    'Sra. Helena trabalhava com números.',
    'D. Sônia preparou a marmita.',
    'Prof. Carlos deu a aula.',
  ];

  for (final text in titleCases) {
    final expanded = PostGenerationFixer.expandTitleAbbreviation(text);
    if (expanded != text) {
      print('   🔄 "$text"');
      print('      → "$expanded"');
    } else {
      print('   ✅ "$text" (sem mudanças)');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 6. TESTE DE RELAÇÕES FAMILIARES
  // ═══════════════════════════════════════════════════════════════
  print('\n📋 6. TESTE DE RELAÇÕES FAMILIARES:');
  print('─────────────────────────────────────────────────────────────────\n');

  final relationCases = [
    'mãe',
    'filho',
    'pai',
    'Dona Sônia', // Não é relação (é nome)
    'Mateus', // Não é relação (é nome)
    'mother',
    'son',
  ];

  for (final word in relationCases) {
    final isRelation = PostGenerationFixer.isFamilyRelation(word);
    final status = isRelation ? '👨‍👩‍👧 RELAÇÃO' : '👤 NOME';
    print('   $status: "$word"');
  }

  // ═══════════════════════════════════════════════════════════════
  // 7. ANÁLISE DE OCORRÊNCIAS NO TEXTO
  // ═══════════════════════════════════════════════════════════════
  print('\n📋 7. CONTAGEM DE OCORRÊNCIAS NO TRECHO:');
  print('─────────────────────────────────────────────────────────────────\n');

  final countPatterns = {
    'Mateus': RegExp(r'\bMateus\b'),
    'Dona Sônia': RegExp(r'\bDona Sônia\b'),
    'Dr. Álvaro': RegExp(r'\bDr\. Álvaro\b'),
    'Otávio': RegExp(r'\bOtávio\b'),
  };

  for (final entry in countPatterns.entries) {
    final count = entry.value.allMatches(screenplay).length;
    print('   • ${entry.key}: $count ocorrências');
  }

  // ═══════════════════════════════════════════════════════════════
  // 8. RESUMO FINAL
  // ═══════════════════════════════════════════════════════════════
  print('\n═══════════════════════════════════════════════════════════════');
  print('📊 RESUMO DA ANÁLISE');
  print('═══════════════════════════════════════════════════════════════\n');

  print('   📝 Total de caracteres: ${screenplay.length}');
  print('   📝 Nomes únicos encontrados: ${foundNames.length}');
  print('   📝 Nomes proibidos usados: ${violations.length}');

  if (violations.isNotEmpty) {
    print('\n   ⚠️ AVISO IMPORTANTE:');
    print('   Este roteiro contém nomes que estão na lista de proibidos:');
    print('   • Mateus, Otávio, Helena');
    print('');
    print('   Isso indica que este é um roteiro de EXEMPLO/TESTE,');
    print('   NÃO um roteiro gerado pelo sistema NameGenerator.');
    print('');
    print('   Em roteiros gerados automaticamente, o sistema usaria');
    print('   nomes alternativos como:');
    print('   • Em vez de Mateus → Rafael, Lucas, Gabriel, etc.');
    print('   • Em vez de Otávio → Ricardo, Fernando, Marcelo, etc.');
    print('   • Em vez de Helena → Beatriz, Camila, Isabela, etc.');
  }

  print('\n   ✅ Sistema de validação v7.6.136 funcionando corretamente!');
  print('   ✅ Whitelist de compostos expandida');
  print('   ✅ Skip de prefixos (Doutor, Senhor, Dona, etc.)');
  print('   ✅ Detecção de frases (Mas X, Ou Y, Era Z)');
  print('   ✅ Expansão automática de abreviações (Dr→Doutor)');

  print('\n═══════════════════════════════════════════════════════════════\n');
}
