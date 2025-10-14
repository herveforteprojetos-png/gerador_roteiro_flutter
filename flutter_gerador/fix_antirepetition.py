# -*- coding: utf-8 -*-
import codecs

with codecs.open('lib/data/services/gemini_service.dart', 'r', encoding='utf-8-sig') as f:
    lines = f.readlines()

# Encontrar a linha 339 e substituir as próximas 4 linhas
new_code = [
    "        // 🚀 VALIDAÇÃO ANTI-REPETIÇÃO LEVE: Sistema baseado em hash (NÃO TRAVA!)\n",
    "        if (added.trim().isNotEmpty && acc.length > 500) {\n",
    "          final hasRepetition = _hasRepeatedPhrasesLight(added);\n",
    "          \n",
    "          if (hasRepetition) {\n",
    "            if (kDebugMode) {\n",
    "              debugPrint('❌ BLOCO $block REJEITADO: Frases repetidas detectadas!');\n",
    "              debugPrint('   📊 Tamanho do bloco: ${_countWords(added)} palavras');\n",
    "              debugPrint('   🔄 Regenerando com aviso explícito contra repetição...');\n",
    "            }\n",
    "            \n",
    "            // Regenerar com flag de repetição\n",
    "            final regenerated = await _retryOnRateLimit(() => _generateBlockContent(\n",
    "              acc, \n",
    "              targetForBlock, \n",
    "              phase, \n",
    "              config, \n",
    "              persistentTracker, \n",
    "              block,\n",
    "              avoidRepetition: true,\n",
    "            ));\n",
    "            \n",
    "            // Verificar novamente\n",
    "            final stillRepeated = _hasRepeatedPhrasesLight(regenerated);\n",
    "            \n",
    "            if (stillRepeated) {\n",
    "              if (kDebugMode) {\n",
    "                debugPrint('⚠️ REGENERAÇÃO AINDA TEM REPETIÇÃO: Usando bloco original');\n",
    "              }\n",
    "              acc += added; // Usar original (melhor que bloquear geração)\n",
    "            } else {\n",
    "              if (kDebugMode) {\n",
    "                debugPrint('✅ REGENERAÇÃO BEM-SUCEDIDA: Bloco único gerado!');\n",
    "              }\n",
    "              acc += regenerated;\n",
    "            }\n",
    "          } else {\n",
    "            acc += added; // Bloco OK, usar diretamente\n",
    "          }\n",
    "        } else {\n",
    "          acc += added;\n",
    "        }\n",
    "        \n",
]

# Procurar a linha que contém "DESABILITADO _isTooSimilar"
for i, line in enumerate(lines):
    if "DESABILITADO _isTooSimilar" in line:
        # Substituir as próximas 4 linhas
        lines[i:i+4] = new_code
        break

with codecs.open('lib/data/services/gemini_service.dart', 'w', encoding='utf-8-sig') as f:
    f.writelines(lines)

print("✅ Arquivo atualizado com sucesso!")
