// 🏗️ v7.6.67: Módulo extraído de gemini_service.dart
// Sistema de Perspectiva Narrativa e Multiplicadores de Idioma
// Parte da arquitetura SOLID - Single Responsibility Principle

library perspective_builder;

import 'package:flutter_gerador/data/models/script_config.dart';

/// 🎭 Classe para geração de instruções de perspectiva e ajustes de idioma
class PerspectiveBuilder {
  /// Retorna label amigável para a perspectiva
  static String perspectiveLabel(String perspective) {
    final perspectiveLower = perspective.toLowerCase();

    // 🔧 FIX: Detectar primeira pessoa em qualquer formato
    if (perspectiveLower.contains('primeira_pessoa') ||
        perspectiveLower == 'first') {
      if (perspectiveLower.contains('mulher_idosa')) {
        return 'Primeira pessoa - Mulher Idosa (50+)';
      }
      if (perspectiveLower.contains('mulher_madura')) {
        return 'Primeira pessoa - Mulher Madura (35-50)';
      }
      if (perspectiveLower.contains('mulher_jovem')) {
        return 'Primeira pessoa - Mulher Jovem (20-35)';
      }
      if (perspectiveLower.contains('homem_idoso')) {
        return 'Primeira pessoa - Homem Idoso (50+)';
      }
      if (perspectiveLower.contains('homem_maduro')) {
        return 'Primeira pessoa - Homem Maduro (35-50)';
      }
      if (perspectiveLower.contains('homem_jovem')) {
        return 'Primeira pessoa - Homem Jovem (20-35)';
      }
      return 'Primeira pessoa';
    }

    // Terceira pessoa (padrão)
    return 'Terceira pessoa';
  }

  /// 🎯 Gera instrução de perspectiva com contexto do protagonista
  static String getPerspectiveInstruction(
    String perspective,
    ScriptConfig config,
  ) {
    final protagonistInfo = config.protagonistName.trim().isNotEmpty
        ? ' O protagonista é "${config.protagonistName}".'
        : '';

    // 🔧 FIX: Aceitar valores reais da interface (primeira_pessoa_*, terceira_pessoa)
    final perspectiveLower = perspective.toLowerCase();

    // Detectar primeira pessoa (qualquer variação)
    if (perspectiveLower.contains('primeira_pessoa') ||
        perspectiveLower == 'first') {
      // Definir pronomes baseado no tipo de primeira pessoa
      String pronomes = 'EU, MEU, MINHA, COMIGO';
      String exemplos =
          '"EU vendi a casa...", "MEU coração batia forte...", "COMIGO ela nunca foi honesta..."';
      String nomeInstrucao = '';

      if (perspectiveLower.contains('mulher')) {
        exemplos =
            '"EU vendi a casa...", "MINHA nora me traiu...", "COMIGO ela nunca foi honesta..."';

        // 🎯 DETECTAR FAIXA ETÁRIA E ADICIONAR INSTRUÇÕES ESPECÍFICAS
        String idadeInstrucao = _getIdadeInstrucaoFeminina(perspectiveLower);

        nomeInstrucao = _getNomeInstrucaoFeminina(idadeInstrucao);
      } else if (perspectiveLower.contains('homem')) {
        exemplos =
            '"EU construí esse negócio...", "MEU filho me abandonou...", "COMIGO ele sempre foi desleal..."';

        // 🎯 DETECTAR FAIXA ETÁRIA E ADICIONAR INSTRUÇÕES ESPECÍFICAS
        String idadeInstrucao = _getIdadeInstrucaoMasculina(perspectiveLower);

        nomeInstrucao = _getNomeInstrucaoMasculina(idadeInstrucao);
      }

      return '''PERSPECTIVA NARRATIVA: PRIMEIRA PESSOA$protagonistInfo
$nomeInstrucao
⚠️ CRÍTICO: O PROTAGONISTA conta SUA PRÓPRIA HISTÓRIA usando "$pronomes".
🚫 PROIBIDO usar "ELE", "ELA", "DELE", "DELA" para o protagonista!
✅ CORRETO: $exemplos
O protagonista é o narrador. Ele/Ela está contando os eventos da SUA perspectiva em primeira pessoa.''';
    }

    // Terceira pessoa (padrão)
    return '''PERSPECTIVA NARRATIVA: TERCEIRA PESSOA$protagonistInfo
⚠️ IMPORTANTE: Um NARRADOR EXTERNO conta a história do protagonista usando "ELE", "ELA", "DELE", "DELA".
Exemplo: "ELA vendeu a casa...", "O coração DELE batia forte...", "COM ELA, ninguém foi honesto...".
O narrador observa e conta, mas NÃO é o protagonista.''';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INSTRUÇÕES DE IDADE POR GÊNERO
  // ═══════════════════════════════════════════════════════════════════════════

  static String _getIdadeInstrucaoFeminina(String perspectiveLower) {
    if (perspectiveLower.contains('jovem')) {
      return '''
╔══════════════════════════════════════════════════════════════════════════════╗
║ 🎯 FAIXA ETÁRIA OBRIGATÓRIA: MULHER JOVEM (20-35 ANOS)                       ║
╚══════════════════════════════════════════════════════════════════════════════╝

✅ IDADE CORRETA: Entre 20 e 35 anos
✅ PERFIL: Mulher adulta jovem, início/meio da carreira, possivelmente casada/solteira, energética
✅ CONTEXTO: Pode ter filhos pequenos, focada em crescimento profissional/pessoal
✅ VOCABULÁRIO: Moderno, atual, referências contemporâneas

❌ PROIBIDO: Mencionar aposentadoria, netos, memórias de décadas atrás
╔══════════════════════════════════════════════════════════════════════════════╝
''';
    } else if (perspectiveLower.contains('madura')) {
      return '''
╔══════════════════════════════════════════════════════════════════════════════╗
║ 🎯 FAIXA ETÁRIA OBRIGATÓRIA: MULHER MADURA (35-50 ANOS)                      ║
╚══════════════════════════════════════════════════════════════════════════════╝

✅ IDADE CORRETA: Entre 35 e 50 anos
✅ PERFIL: Mulher experiente, consolidada profissionalmente, possivelmente com filhos adolescentes
✅ CONTEXTO: Pode ter divórcio, segundo casamento, filhos crescidos, auge da carreira
✅ VOCABULÁRIO: Equilibrado, maduro, experiente mas ainda contemporâneo

❌ PROIBIDO: Mencionar aposentadoria, netos adultos, velhice
╔══════════════════════════════════════════════════════════════════════════════╝
''';
    } else if (perspectiveLower.contains('idosa')) {
      return '''
╔══════════════════════════════════════════════════════════════════════════════╗
║ 🎯 FAIXA ETÁRIA OBRIGATÓRIA: MULHER IDOSA (50+ ANOS)                         ║
╚══════════════════════════════════════════════════════════════════════════════╝

✅ IDADE CORRETA: Acima de 50 anos
✅ PERFIL: Mulher com muita experiência de vida, possivelmente aposentada ou perto
✅ CONTEXTO: Pode ter netos, viuvez, legado familiar, reflexões sobre a vida
✅ VOCABULÁRIO: Sábio, reflexivo, com histórias de décadas atrás

❌ PROIBIDO: Agir como jovem, usar gírias recentes inadequadas à idade
╔══════════════════════════════════════════════════════════════════════════════╝
''';
    }
    return '';
  }

  static String _getIdadeInstrucaoMasculina(String perspectiveLower) {
    if (perspectiveLower.contains('jovem')) {
      return '''
╔══════════════════════════════════════════════════════════════════════════════╗
║ 🎯 FAIXA ETÁRIA OBRIGATÓRIA: HOMEM JOVEM (20-35 ANOS)                        ║
╚══════════════════════════════════════════════════════════════════════════════╝

✅ IDADE CORRETA: Entre 20 e 35 anos
✅ PERFIL: Homem adulto jovem, início/meio da carreira, possivelmente casado/solteiro, energético
✅ CONTEXTO: Pode ter filhos pequenos, focado em crescimento profissional/pessoal
✅ VOCABULÁRIO: Moderno, atual, referências contemporâneas

❌ PROIBIDO: Mencionar aposentadoria, netos, memórias de décadas atrás
╔══════════════════════════════════════════════════════════════════════════════╝
''';
    } else if (perspectiveLower.contains('maduro')) {
      return '''
╔══════════════════════════════════════════════════════════════════════════════╗
║ 🎯 FAIXA ETÁRIA OBRIGATÓRIA: HOMEM MADURO (35-50 ANOS)                       ║
╚══════════════════════════════════════════════════════════════════════════════╝

✅ IDADE CORRETA: Entre 35 e 50 anos
✅ PERFIL: Homem experiente, consolidado profissionalmente, possivelmente com filhos adolescentes
✅ CONTEXTO: Pode ter divórcio, segundo casamento, filhos crescidos, auge da carreira
✅ VOCABULÁRIO: Equilibrado, maduro, experiente mas ainda contemporâneo

❌ PROIBIDO: Mencionar aposentadoria, netos adultos, velhice
╔══════════════════════════════════════════════════════════════════════════════╝
''';
    } else if (perspectiveLower.contains('idoso')) {
      return '''
╔══════════════════════════════════════════════════════════════════════════════╗
║ 🎯 FAIXA ETÁRIA OBRIGATÓRIA: HOMEM IDOSO (50+ ANOS)                          ║
╚══════════════════════════════════════════════════════════════════════════════╝

✅ IDADE CORRETA: Acima de 50 anos
✅ PERFIL: Homem com muita experiência de vida, possivelmente aposentado ou perto
✅ CONTEXTO: Pode ter netos, viuvez, legado familiar, reflexões sobre a vida
✅ VOCABULÁRIO: Sábio, reflexivo, com histórias de décadas atrás

❌ PROIBIDO: Agir como jovem, usar gírias recentes inadequadas à idade
╔══════════════════════════════════════════════════════════════════════════════╝
''';
    }
    return '';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INSTRUÇÕES DE NOME POR GÊNERO
  // ═══════════════════════════════════════════════════════════════════════════

  static String _getNomeInstrucaoFeminina(String idadeInstrucao) {
    return '''
+------------------------------------------------------------------------------+
│ 🚨🚨🚨 GÊNERO OBRIGATÓRIO: FEMININO (MULHER) - CONFIGURAÇÃO DO USUÁRIO 🚨🚨🚨 │
+------------------------------------------------------------------------------+

🚨🚨🚨 REGRA ABSOLUTA - NÃO NEGOCIÁVEL 🚨🚨🚨

O USUÁRIO CONFIGUROU EXPLICITAMENTE: "Primeira Pessoa MULHER"
VOCÊ DEVE, OBRIGATORIAMENTE, GERAR UM PROTAGONISTA FEMININO!

📋 VALIDAÇÃO ANTES DE ESCREVER A PRIMEIRA FRASE:
✓ "O protagonista que vou criar é MULHER?" 
   → Se SIM = Prossiga
   → Se NÃO = PARE! Você está DESOBEDECENDO a configuração do usuário!

╔══════════════════════════════════════════════════════════════════════════════╝

🎯 REGRAS DE NOMES:

1️⃣ SE O TÍTULO MENCIONAR UM NOME ESPECÍFICO (ex: "Você é Maria?"):
   → USE ESTE NOME para a protagonista
   → Exemplo: Se título diz "Maria", protagonista é "Maria"

2️⃣ SE O TÍTULO NÃO MENCIONAR NENHUM NOME (ex: "Un milliardaire m'a donné..."):
   → VOCÊ DEVE CRIAR um nome FEMININO apropriado para o idioma
   
   📝 Nomes femininos por idioma:
   • Français: Sophie, Marie, Amélie, Claire, Camille, Emma, Louise, Chloé
   • Português: Maria, Ana, Sofia, Helena, Clara, Beatriz, Julia, Laura
   • English: Emma, Sarah, Jennifer, Emily, Jessica, Ashley, Michelle, Amanda
   • Español: María, Carmen, Laura, Ana, Isabel, Rosa, Elena, Sofia
   • 한국어 (Korean): Kim Ji-young, Park Soo-yeon, Lee Min-ji, Choi Hye-jin, Jung Yoo-na
     ⚠️ COREANO: SEMPRE use SOBRENOME + NOME (ex: "Kim Ji-young", NÃO "Ji-young")
   
   ❌ PROIBIDO: João, Pedro, Carlos, Michael, Roberto, Pierre, Jean, Marc
   ❌ JAMAIS use nomes MASCULINOS quando o narrador é MULHER!

$idadeInstrucao

🚨 SE VOCÊ CRIAR UM PROTAGONISTA MASCULINO, O ROTEIRO SERÁ REJEITADO!
╔══════════════════════════════════════════════════════════════════════════════╝

''';
  }

  static String _getNomeInstrucaoMasculina(String idadeInstrucao) {
    return '''
+------------------------------------------------------------------------------+
│ 🚨🚨🚨 GÊNERO OBRIGATÓRIO: MASCULINO (HOMEM) - CONFIGURAÇÃO DO USUÁRIO 🚨🚨🚨 │
+------------------------------------------------------------------------------+

🚨🚨🚨 REGRA ABSOLUTA - NÃO NEGOCIÁVEL 🚨🚨🚨

O USUÁRIO CONFIGUROU EXPLICITAMENTE: "Primeira Pessoa HOMEM"
VOCÊ DEVE, OBRIGATORIAMENTE, GERAR UM PROTAGONISTA MASCULINO!

📋 VALIDAÇÃO ANTES DE ESCREVER A PRIMEIRA FRASE:
✓ "O protagonista que vou criar é HOMEM?" 
   → Se SIM = Prossiga
   → Se NÃO = PARE! Você está DESOBEDECENDO a configuração do usuário!

╔══════════════════════════════════════════════════════════════════════════════╝

🎯 REGRAS DE NOMES:

1️⃣ SE O TÍTULO MENCIONAR UM NOME ESPECÍFICO (ex: "Você é Michael?"):
   → USE ESTE NOME para o protagonista
   → Exemplo: Se título diz "Michael", protagonista é "Michael"

2️⃣ SE O TÍTULO NÃO MENCIONAR NENHUM NOME (ex: "Un milliardaire m'a donné..."):
   → VOCÊ DEVE CRIAR um nome MASCULINO apropriado para o idioma
   
   📝 Nomes masculinos por idioma:
   • Français: Pierre, Jean, Marc, Luc, Antoine, Thomas, Nicolas, Julien
   • Português: João, Pedro, Carlos, Roberto, Alberto, Paulo, Fernando, Ricardo
   • English: John, Michael, David, James, Robert, William, Richard, Thomas
   • Español: Juan, Pedro, Carlos, José, Luis, Miguel, Antonio, Francisco
   • 한국어 (Korean): Kim Seon-woo, Park Jae-hyun, Lee Min-ho, Choi Dong-wook, Jung Tae-hyun
     ⚠️ COREANO: SEMPRE use SOBRENOME + NOME (ex: "Kim Seon-woo", NÃO "Seon-woo")
   
   ❌ PROIBIDO: Maria, Ana, Sofia, Sophie, Mônica, Clara, Helena, Emma
   ❌ JAMAIS use nomes FEMININOS quando o narrador é HOMEM!

$idadeInstrucao

🚨 SE VOCÊ CRIAR UM PROTAGONISTA FEMININO, O ROTEIRO SERÁ REJEITADO!
╔══════════════════════════════════════════════════════════════════════════════╝

''';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MULTIPLICADORES DE VERBOSIDADE POR IDIOMA
  // ═══════════════════════════════════════════════════════════════════════════

  /// 🌍 Retorna multiplicador de verbosidade baseado no idioma
  /// Baseado em análise de quantas palavras cada idioma precisa para expressar a mesma ideia
  /// Português = 1.0 (baseline) funciona perfeitamente
  static double getLanguageVerbosityMultiplier(String language) {
    final normalized = language.toLowerCase().trim();

    // 🇪🇸 ESPANHOL: Tende a ser ~15-20% mais verboso que português
    if (normalized.contains('espanhol') ||
        normalized.contains('spanish') ||
        normalized.contains('español') ||
        normalized == 'es' ||
        normalized == 'es-mx') {
      return 0.85; // Pedir 15% menos para compensar
    }

    // 🇺🇸 INGLÊS: Tende a ser ~15-20% mais CONCISO que português
    // RAZÃO: Inglês usa menos palavras para expressar mesma ideia
    // EXEMPLO: "Eu estava pensando nisso" = 4 palavras → "I was thinking" = 3 palavras
    // SOLUÇÃO: Pedir um pouco MAIS palavras para compensar a concisão
    // 🔧 AJUSTE: Reduzido de 1.18x → 1.05x (estava gerando +21% a mais)
    if (normalized.contains('inglês') ||
        normalized.contains('ingles') ||
        normalized.contains('english') ||
        normalized == 'en' ||
        normalized == 'en-us') {
      return 1.05; // Pedir 5% MAIS para compensar concisão
    }

    // 🇫🇷 FRANCÊS: Tende a ser ~10-15% mais verboso que português
    if (normalized.contains('franc') ||
        normalized.contains('french') ||
        normalized == 'fr') {
      return 0.90; // Pedir 10% menos para compensar
    }

    // 🇮🇹 ITALIANO: Tende a ser ~10% mais verboso que português
    if (normalized.contains('italia') ||
        normalized.contains('italian') ||
        normalized == 'it') {
      return 0.92; // Pedir 8% menos para compensar
    }

    // 🇩🇪 ALEMÃO: Similar ao português (palavras compostas compensam artigos)
    if (normalized.contains('alem') ||
        normalized.contains('german') ||
        normalized == 'de') {
      return 1.0; // Sem ajuste
    }

    // 🇷🇺 RUSSO: Muito conciso (sem artigos, casos gramaticais)
    if (normalized.contains('russo') ||
        normalized.contains('russian') ||
        normalized == 'ru') {
      return 1.15; // Pedir 15% mais para compensar
    }

    // 🇵🇱 POLONÊS: Ligeiramente mais conciso que português
    if (normalized.contains('polon') ||
        normalized.contains('polish') ||
        normalized == 'pl') {
      return 1.05; // Pedir 5% mais para compensar
    }

    // 🇹🇷 TURCO: Muito conciso (aglutinação de palavras)
    if (normalized.contains('turco') ||
        normalized.contains('turk') ||
        normalized == 'tr') {
      return 1.20; // Pedir 20% mais para compensar
    }

    // 🇧🇬 BÚLGARO: Similar ao russo, conciso
    if (normalized.contains('búlgar') ||
        normalized.contains('bulgar') ||
        normalized == 'bg') {
      return 1.12; // Pedir 12% mais para compensar
    }

    // 🇭🇷 CROATA: Ligeiramente mais conciso
    if (normalized.contains('croat') ||
        normalized.contains('hrvat') ||
        normalized == 'hr') {
      return 1.08; // Pedir 8% mais para compensar
    }

    // 🇷🇴 ROMENO: Similar ao português (língua latina)
    if (normalized.contains('romen') ||
        normalized.contains('roman') ||
        normalized == 'ro') {
      return 1.0; // Sem ajuste
    }

    // 🇰🇷 COREANO: Muito conciso (aglutinação) + Modelo tende a ser preguiçoso
    // ANÁLISE: Pedindo 1.0x, ele entrega ~70% da meta.
    // SOLUÇÃO: Pedir 1.55x (55% a mais) para forçar expansão ou atingir o teto natural.
    if (normalized.contains('coreano') ||
        normalized.contains('korean') ||
        normalized.contains('한국어') ||
        normalized == 'ko') {
      return 1.55;
    }

    // 🇧🇷 PORTUGUÊS ou OUTROS: Baseline perfeito
    return 1.0;
  }
}
