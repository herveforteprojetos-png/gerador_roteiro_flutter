enum LocalizationLevel {
  /// Conteúdo globalizado - evita gírias e referências específicas de localidade
  /// Ideal para tradução e públicos internacionais
  global,

  /// Conteúdo nacional - usa referências do país mas evita regionalismos extremos
  /// Bom para todo o território brasileiro
  national,

  /// Conteúdo regional - inclui gírias e referências locais específicas
  /// Melhor engajamento com público da região específica
  regional;

  String get displayName {
    switch (this) {
      case LocalizationLevel.global:
        return 'Global (Sem Regionalismos)';
      case LocalizationLevel.national:
        return 'Nacional (Referências do País)';
      case LocalizationLevel.regional:
        return 'Regional (Gírias Locais)';
    }
  }

  String get description {
    switch (this) {
      case LocalizationLevel.global:
        return 'Conteúdo universalizável, fácil de traduzir, sem gírias específicas';
      case LocalizationLevel.national:
        return 'Referências brasileiras gerais, compreensível em todo o país';
      case LocalizationLevel.regional:
        return 'Gírias e referências locais específicas para maior engajamento';
    }
  }

  String get geminiInstruction {
    switch (this) {
      case LocalizationLevel.global:
        return '''
IMPORTANTE - NÍVEL DE LOCALIZAÇÃO: GLOBAL (TRADUÇÃO INTERNACIONAL)
🌍 Este roteiro será TRADUZIDO para Polonês, Russo, Inglês, Alemão, Japonês, etc.

⚠️ PROIBIÇÕES ABSOLUTAS:

1️⃣ NOMES DE PERSONAGENS PRINCIPAIS:
❌ NUNCA USE nomes brasileiros/portugueses: João, Maria, José, Antônio, Francisco, Carlos, Ana, Pedro, Paulo, Fernanda, Carla, Estela, Helena, Roberto, Afonso
✅ SEMPRE USE nomes internacionais: Marco, Lucas, Sofia, Clara, Alex, Daniel, Anna, Paul, Elena, Lisa, Leo, Emma, Noah, Sarah, Michael
EXEMPLO: Protagonista "Elena" (não "Estela"), amiga "Lisa" (não "Carla")

2️⃣ NOMES SECUNDÁRIOS (advogados, médicos, funcionários):
❌ EVITE: Nonato, Magalhães, Túlia, Sebastião, Geraldo, Clóvis
✅ USE: Victor, Thomas, Laura, David, Oliver, Julia, Nathan

3️⃣ NEGÓCIOS/ESTABELECIMENTOS:
❌ PROIBIDO usar estrutura brasileira: "Delícias da Vovó", "Padaria do Seu João", "Solar Dourado", "Casa de Dona...", "Cantinho da..."
✅ OBRIGATÓRIO usar formato internacional: "[Nome] Bakery", "[Nome] Care Center", "[Nome] Residence", "The [Nome] Shop"
EXEMPLOS CORRETOS: "Anna's Bakery", "Golden Residence", "Hope Care Center"

4️⃣ COMIDAS/BEBIDAS:
❌ PROIBIDO mencionar pratos típicos: bolo de fubá, brigadeiro, farofa, pão de queijo, açaí, acarajé, tapioca, coxinha, pastel
✅ USE APENAS alimentos universais: pão, bolo (sem especificar tipo), café, chá, torta, biscoitos, doces, sopa, salada
DICA: "bolo caseiro" OK, "bolo de fubá" NÃO

5️⃣ TRATAMENTOS E FORMAS DE CHAMAR:
❌ NUNCA USE formas brasileiras: "dona Helena", "senhor Roberto", "seu Afonso", "Vovó/Vovô + nome", "titia", "Sogrinha", "tio"
✅ SEMPRE USE formas internacionais: "Sr./Sra. [Nome]", "Mr./Mrs. [Nome]", "Grandma/Grandpa [Nome]", ou apenas o nome direto
EXEMPLOS: "Grandma Elena" (não "Vovó Estela"), "Mr. Paul" (não "senhor Paulo"), "my son" (não "meu Filho" com maiúscula)

6️⃣ EXPRESSÕES/GÍRIAS BRASILEIRAS:
❌ PROIBIDO: "cara", "mano", "véi", "pé-rapado", "de graça", "sem graça", "beleza?", "tá ligado?", "fazer uma cena", "pedaço de papel"
✅ USE: "pessoa", "amigo", "pessoas simples", "gratuitamente", "constrangido/envergonhado", "certo?", "entende?", "criar um escândalo", "documento"

7️⃣ ATIVIDADES/CONTEXTOS CULTURAIS BR:
❌ EVITE tradições/termos BR: "almoço de domingo" (tradição forte BR), "hidroginástica" (termo BR), "churrasco de família"
✅ USE formas neutras: "reunião familiar", "exercícios aquáticos", "jantar em família"

8️⃣ MOEDA/VALORES:
❌ NUNCA mencionar: "real", "reais", "R\$"
✅ SEMPRE USE: "dinheiro", "valor", "quantia", "pagamento", "salário"

9️⃣ INSTITUIÇÕES BRASILEIRAS:
❌ PROIBIDO: SUS, INSS, Receita Federal, Polícia Federal, Detran, Procon
✅ USE genéricos: "sistema de saúde", "previdência social", "autoridades fiscais", "polícia", "departamento de trânsito", "defesa do consumidor"

🔟 GEOGRAFIA:
❌ NUNCA mencione: estados brasileiros, cidades, bairros, pontos turísticos, praias, monumentos
✅ APENAS termos genéricos: "a cidade", "o bairro", "a região", "o centro", "a área", "a praia"

📝 REGRA DE OURO - TESTE ANTES DE ESCREVER:
Antes de mencionar QUALQUER elemento (nome, comida, lugar, expressão), pergunte:
"Isso existe naturalmente em Polônia, Rússia, Japão, Alemanha, França?"
➡️ Se a resposta for NÃO = substitua por versão universal

🎯 META FINAL: História 100% traduzível para qualquer idioma sem precisar adaptar nomes, comidas, expressões ou referências culturais.
''';
      case LocalizationLevel.national:
        return '''
IMPORTANTE - NÍVEL DE LOCALIZAÇÃO: NACIONAL
- Use referências brasileiras gerais que todo brasileiro entenda
- Pode mencionar o país (Brasil) mas evite estados/cidades específicas
- Gírias nacionais são permitidas mas evite regionalismos extremos
- Referências culturais brasileiras são bem-vindas (como novela, futebol, etc.)
- Mantenha linguagem acessível para todo o território nacional
''';
      case LocalizationLevel.regional:
        return '''
IMPORTANTE - NÍVEL DE LOCALIZAÇÃO: REGIONAL
- Sinta-se livre para usar gírias e expressões locais específicas
- Pode mencionar localidades, bairros, pontos de referência específicos
- Use o sotaque e jeito de falar característico da região
- Inclua referências culturais e sociais locais
- Maximize o engajamento com o público regional específico
''';
    }
  }
}
