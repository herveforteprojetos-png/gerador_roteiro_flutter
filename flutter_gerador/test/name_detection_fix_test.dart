import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gerador/data/services/gemini/validation/name_validator.dart';

void main() {
  group('🔍 Teste de Detecção de Nomes - Fix Capitalização', () {
    
    setUp(() {
      // Limpar cache antes de cada teste
      NameValidator.clearCache();
    });
    
    test('❌ NÃO deve detectar substantivos abstratos como nomes', () {
      final text = '''
      Iniciativa é importante. Quero fazer isso. Lembre de chamar.
      Oferta válida. Dias passam. Nenhum problema encontrado.
      Genuíno interesse. Proatividade conta. Liderança é essencial.
      Campanha começou. Foco no trabalho.
      ''';
      
      final names = NameValidator.extractNamesFromText(text);
      
      // NÃO deve detectar nenhuma dessas palavras
      expect(names.contains('Iniciativa'), false, reason: 'Iniciativa é substantivo abstrato');
      expect(names.contains('Quero'), false, reason: 'Quero é verbo');
      expect(names.contains('Lembre'), false, reason: 'Lembre é verbo');
      expect(names.contains('Oferta'), false, reason: 'Oferta é substantivo comum');
      expect(names.contains('Dias'), false, reason: 'Dias é substantivo comum');
      expect(names.contains('Nenhum'), false, reason: 'Nenhum é pronome');
      expect(names.contains('Genuíno'), false, reason: 'Genuíno é adjetivo');
      expect(names.contains('Proatividade'), false, reason: 'Proatividade é substantivo abstrato');
      expect(names.contains('Liderança'), false, reason: 'Liderança é substantivo abstrato');
      expect(names.contains('Campanha'), false, reason: 'Campanha é substantivo comum');
      expect(names.contains('Foco'), false, reason: 'Foco é substantivo comum');
    });
    
    test('❌ NÃO deve detectar instituições/locais como nomes', () {
      final text = '''
      A Escola Municipal foi inaugurada.
      O Hospital Central atende bem.
      A Prefeitura Municipal anunciou.
      Sonho Grande é o nome da escola.
      Grande sucesso no evento.
      Tão bonito o lugar.
      ''';
      
      final names = NameValidator.extractNamesFromText(text);
      
      print('🔍 Nomes detectados no texto de instituições: $names');
      
      expect(names.contains('Escola'), false, reason: 'Escola é instituição');
      expect(names.contains('Municipal'), false, reason: 'Municipal é qualificador');
      expect(names.contains('Escola Municipal'), false, reason: 'Escola Municipal é instituição');
      expect(names.contains('Hospital'), false, reason: 'Hospital é instituição');
      expect(names.contains('Central'), false, reason: 'Central é qualificador');
      expect(names.contains('Hospital Central'), false, reason: 'Hospital Central é instituição');
      expect(names.contains('Prefeitura'), false, reason: 'Prefeitura é instituição');
      expect(names.contains('Prefeitura Municipal'), false, reason: 'Prefeitura Municipal é instituição');
      expect(names.contains('Sonho'), false, reason: 'Sonho é substantivo comum');
      expect(names.contains('Grande'), false, reason: 'Grande é adjetivo');
      expect(names.contains('Sonho Grande'), false, reason: 'Sonho Grande pode ser nome de lugar');
      expect(names.contains('Tão'), false, reason: 'Tão é advérbio');
    });
    
    test('❌ NÃO deve detectar palavras no início de frases', () {
      final text = '''
      Para Lia foi importante. Moro em São Paulo.
      Nesses momentos difíceis. Após a reunião.
      Assim começou tudo. Faxineiros limparam. 
      Professores ensinaram. Agentes investigaram.
      ''';
      
      final names = NameValidator.extractNamesFromText(text);
      
      // Deve detectar apenas "Lia" (nome conhecido no meio da frase)
      expect(names.contains('Para'), false);
      expect(names.contains('Moro'), false);
      expect(names.contains('Nesses'), false);
      expect(names.contains('Após'), false);
      expect(names.contains('Assim'), false);
      expect(names.contains('Faxineiros'), false);
      expect(names.contains('Professores'), false);
      expect(names.contains('Agentes'), false);
    });
    
    test('✅ DEVE detectar nomes reais no meio de frases', () {
      final text1 = 'A reunião com Cecília foi produtiva.';
      final text2 = 'Carlos chegou cedo.';
      final text3 = 'Beatriz também veio.';
      final text4 = 'O presidente Costa falou sobre o projeto.';
      final text5 = 'Dona Elza ajudou muito.';
      
      final names1 = NameValidator.extractNamesFromText(text1);
      final names2 = NameValidator.extractNamesFromText(text2);
      final names3 = NameValidator.extractNamesFromText(text3);
      final names4 = NameValidator.extractNamesFromText(text4);
      final names5 = NameValidator.extractNamesFromText(text5);
      
      print('🔍 Text1 detectou: $names1');
      print('🔍 Text2 detectou: $names2');
      print('🔍 Text3 detectou: $names3');
      print('🔍 Text4 detectou: $names4');
      print('🔍 Text5 detectou: $names5');
      
      expect(names1.contains('Cecília'), true, reason: 'Cecília deveria ser detectado');
      expect(names2.contains('Carlos'), true, reason: 'Carlos deveria ser detectado');
      expect(names3.contains('Beatriz'), true, reason: 'Beatriz deveria ser detectado');
      expect(names4.contains('Costa'), true, reason: 'Costa deveria ser detectado');
      expect(names5.contains('Elza'), true, reason: 'Elza deveria ser detectado');
    });
    
    test('🧪 Teste individual looksLikePersonName', () {
      // Substantivos abstratos devem retornar FALSE
      expect(NameValidator.looksLikePersonName('Iniciativa'), false);
      expect(NameValidator.looksLikePersonName('Proatividade'), false);
      expect(NameValidator.looksLikePersonName('Liderança'), false);
      expect(NameValidator.looksLikePersonName('Campanha'), false);
      
      // Verbos/palavras comuns devem retornar FALSE
      expect(NameValidator.looksLikePersonName('Inicie'), false);
      expect(NameValidator.looksLikePersonName('Quero'), false);
      expect(NameValidator.looksLikePersonName('Lembre'), false);
      expect(NameValidator.looksLikePersonName('Oferta'), false);
      expect(NameValidator.looksLikePersonName('Foco'), false);
      
      // Nomes reais devem retornar TRUE
      expect(NameValidator.looksLikePersonName('Cecília'), true);
      expect(NameValidator.looksLikePersonName('Carlos'), true);
      expect(NameValidator.looksLikePersonName('Beatriz'), true);
      expect(NameValidator.looksLikePersonName('Costa'), true);
    });
    
    test('🔍 Debug: verificar sufixos abstratos', () {
      // Testar se sufixo -ade está funcionando
      final word1 = 'Iniciativa';
      final lower1 = word1.toLowerCase(); // "iniciativa"
      expect(lower1.endsWith('ade'), false, reason: 'iniciativa termina com "iva", não "ade"');
      expect(lower1.endsWith('iva'), true, reason: 'iniciativa termina com "iva"');
      
      // Proatividade
      final word2 = 'Proatividade';
      final lower2 = word2.toLowerCase(); // "proatividade"
      expect(lower2.endsWith('idade'), true, reason: 'proatividade termina com "idade"');
      
      // Liderança
      final word3 = 'Liderança';
      final lower3 = word3.toLowerCase(); // "liderança"
      expect(lower3.endsWith('ncia'), false, reason: 'liderança tem ç, não c');
      expect(lower3.endsWith('ança'), true, reason: 'liderança termina com "ança"');
    });
  });
}
