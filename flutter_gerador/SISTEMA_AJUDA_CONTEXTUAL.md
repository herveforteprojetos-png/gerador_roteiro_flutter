# 💡 SISTEMA DE AJUDA CONTEXTUAL - DESIGN & IMPLEMENTAÇÃO

## 🎯 OBJETIVO

Criar sistema de ajuda que:
- ✅ Explica cada parâmetro de forma visual
- ✅ Mostra combinações recomendadas
- ✅ Ensina através de exemplos práticos
- ✅ Não polui a interface (aparece só quando necessário)

---

## 📱 DESIGN DA INTERFACE

### **NÍVEL 1: Tooltip Simples (Hover)**

```
┌────────────────────────────────────────┐
│ Estilo de Narração              [ℹ️]   │  ← Botão info
│ ┌────────────────────────────────────┐ │
│ │ ▼ Reflexivo e Memórias           │ │
│ └────────────────────────────────────┘ │
│   ↑                                    │
│   └─ [Tooltip ao passar mouse]        │
│      "Define o tom e ritmo da         │
│       narrativa. Combine com          │
│       perspectiva adequada."          │
└────────────────────────────────────────┘
```

### **NÍVEL 2: Popup Educativo (Clique no ℹ️)**

```
┌─────────────────────────────────────────────────────┐
│ 🎬 Estilo de Narração                          [✕]  │
├─────────────────────────────────────────────────────┤
│                                                     │
│ 📖 O que é?                                         │
│ Define COMO a história é contada: o ritmo, tom e   │
│ estrutura narrativa.                                │
│                                                     │
│ ✨ Quando usar cada estilo:                         │
│                                                     │
│ 🧠 Reflexivo e Memórias                             │
│ ▸ Para: Idosos contando passado, biografias        │
│ ▸ Combine com: Primeira Pessoa Idosa               │
│ ▸ Exemplo: "Eu me lembro de quando..."             │
│                                                     │
│ 🏇 Épico de Época                                   │
│ ▸ Para: Western 1890, guerras, aventura histórica  │
│ ▸ Combine com: Localização com ano específico      │
│ ▸ Evita: Anacronismos (carros, celulares)          │
│                                                     │
│ 🔍 Educativo e Curioso                              │
│ ▸ Para: Curiosidades, fatos históricos             │
│ ▸ Combine com: Tema "Curiosidades"                 │
│ ▸ Estrutura: Fato → Contexto → Impacto             │
│                                                     │
│ ⚡ Ação Rápida                                       │
│ ▸ Para: Thriller, suspense, aventura               │
│ ▸ Ritmo: Parágrafos curtos, eventos rápidos        │
│                                                     │
│ 💡 Dica: Para história de mulher idosa reflexiva,  │
│    use "Reflexivo e Memórias" + "1ª Pessoa Idosa"  │
│                                                     │
│          [Ver Combinações Recomendadas]            │
└─────────────────────────────────────────────────────┘
```

### **NÍVEL 3: Combinações Inteligentes (Modal Grande)**

```
┌─────────────────────────────────────────────────────┐
│ 🎯 Combinações Recomendadas                    [✕]  │
├─────────────────────────────────────────────────────┤
│                                                     │
│ Escolha um caso de uso:                             │
│                                                     │
│ ┌─────────────────────────────────────────────────┐ │
│ │ 👵 Mulher idosa contando memórias de família   │ │
│ │                                                 │ │
│ │ ✅ Perspectiva: Primeira Pessoa Mulher Idosa   │ │
│ │ ✅ Estilo: Reflexivo e Memórias                │ │
│ │ ✅ Tema: Família Disfuncional                  │ │
│ │ ✅ Subtema: Segredos Familiares                │ │
│ │ ✅ Tom: Nostálgico, pausado                    │ │
│ │                                                 │ │
│ │ 📝 Resultado: "Eu me lembro da tarde em que    │ │
│ │    descobri a verdade sobre minha nora..."     │ │
│ │                                                 │ │
│ │          [Aplicar Esta Configuração]           │ │
│ └─────────────────────────────────────────────────┘ │
│                                                     │
│ ┌─────────────────────────────────────────────────┐ │
│ │ 🤠 Velho Oeste 1890 - Duelo de Vingança        │ │
│ │                                                 │ │
│ │ ✅ Perspectiva: Terceira Pessoa                │ │
│ │ ✅ Estilo: Épico de Época                      │ │
│ │ ✅ Tema: Vingança                              │ │
│ │ ✅ Localização: Ano 1890, Velho Oeste          │ │
│ │ ✅ Tipo de História: Western                   │ │
│ │                                                 │ │
│ │ ⚠️ Evita automaticamente: Carros, telefones,   │ │
│ │    luz elétrica, linguagem moderna             │ │
│ │                                                 │ │
│ │          [Aplicar Esta Configuração]           │ │
│ └─────────────────────────────────────────────────┘ │
│                                                     │
│ ┌─────────────────────────────────────────────────┐ │
│ │ 🔍 Curiosidades Históricas                      │ │
│ │ ✅ Perspectiva: Terceira Pessoa                │ │
│ │ ✅ Estilo: Educativo e Curioso                 │ │
│ │ ✅ Tema: Curiosidades                          │ │
│ │ ✅ Subtema: Fatos Históricos Inusitados        │ │
│ │          [Aplicar Esta Configuração]           │ │
│ └─────────────────────────────────────────────────┘ │
│                                                     │
│        [+ Ver Mais Exemplos (12 templates)]        │
└─────────────────────────────────────────────────────┘
```

---

## 🛠️ IMPLEMENTAÇÃO TÉCNICA

### **PASSO 1: Criar Modelo de Dados para Ajuda**

**Arquivo: `lib/data/models/field_help.dart`**

```dart
/// Modelo para tooltip simples
class FieldTooltip {
  final String text;
  const FieldTooltip(this.text);
}

/// Modelo para help popup detalhado
class FieldHelp {
  final String title;
  final String description;
  final List<HelpSection> sections;
  final String? tip;
  
  const FieldHelp({
    required this.title,
    required this.description,
    required this.sections,
    this.tip,
  });
}

/// Seção do help popup
class HelpSection {
  final String emoji;
  final String title;
  final String forWhat;
  final String? combineWith;
  final String? example;
  final String? avoids;
  
  const HelpSection({
    required this.emoji,
    required this.title,
    required this.forWhat,
    this.combineWith,
    this.example,
    this.avoids,
  });
}

/// Template de configuração pré-definida
class ConfigTemplate {
  final String emoji;
  final String title;
  final String description;
  final Map<String, dynamic> config;
  final String? resultPreview;
  final List<String>? avoids;
  
  const ConfigTemplate({
    required this.emoji,
    required this.title,
    required this.description,
    required this.config,
    this.resultPreview,
    this.avoids,
  });
}
```

### **PASSO 2: Criar Dados de Ajuda**

**Arquivo: `lib/data/constants/help_content.dart`**

```dart
import '../models/field_help.dart';
import '../models/generation_config.dart';

class HelpContent {
  // ==================== TOOLTIPS SIMPLES ====================
  
  static const tooltips = {
    'narrativeStyle': FieldTooltip(
      'Define o tom e ritmo da narrativa. Combine com perspectiva adequada.',
    ),
    'perspective': FieldTooltip(
      'Quem conta a história: narrador externo (3ª pessoa) ou protagonista (1ª pessoa).',
    ),
    'theme': FieldTooltip(
      'Tema central da história. Influencia toda a linha narrativa.',
    ),
    'location': FieldTooltip(
      'Onde se passa a história. Para épocas históricas, inclua o ano (ex: "Ano 1890, Velho Oeste").',
    ),
    'localizationLevel': FieldTooltip(
      'Nacional: nomes/comidas brasileiras. Global: universal sem regionalismos.',
    ),
  };
  
  // ==================== HELP POPUPS DETALHADOS ====================
  
  static final narrativeStyleHelp = FieldHelp(
    title: '🎬 Estilo de Narração',
    description: 'Define COMO a história é contada: o ritmo, tom e estrutura narrativa.',
    tip: 'Para história de mulher idosa reflexiva, use "Reflexivo e Memórias" + "1ª Pessoa Idosa"',
    sections: [
      HelpSection(
        emoji: '🧠',
        title: 'Reflexivo e Memórias',
        forWhat: 'Idosos contando passado, biografias, memórias',
        combineWith: 'Primeira Pessoa Idosa',
        example: '"Eu me lembro de quando minha nora me traiu..."',
      ),
      HelpSection(
        emoji: '🏇',
        title: 'Épico de Época',
        forWhat: 'Western 1890, guerras, aventura histórica',
        combineWith: 'Localização com ano específico (ex: "Ano 1890, Velho Oeste")',
        avoids: 'Anacronismos: carros, celulares, luz elétrica',
        example: '"O sol escaldante de 1890 castigava Red Rock. Jake ajustou o revólver..."',
      ),
      HelpSection(
        emoji: '🔍',
        title: 'Educativo e Curioso',
        forWhat: 'Curiosidades, fatos históricos, episódios educativos',
        combineWith: 'Tema "Curiosidades"',
        example: '"Você sabia que durante a Segunda Guerra..."',
      ),
      HelpSection(
        emoji: '⚡',
        title: 'Ação Rápida',
        forWhat: 'Thriller, suspense, aventura intensa',
        combineWith: 'Temas de ação (Vingança, Suspense)',
        example: '"João correu. A porta explodiu. Sangue na parede."',
      ),
      HelpSection(
        emoji: '🎭',
        title: 'Lírico e Poético',
        forWhat: 'Drama intenso, linguagem elaborada',
        combineWith: 'Temas dramáticos (Redenção, Romance)',
        example: '"A alma fragmentada buscava redenção nas águas do tempo..."',
      ),
    ],
  );
  
  static final perspectiveHelp = FieldHelp(
    title: '👁️ Perspectiva Narrativa',
    description: 'Define QUEM conta a história e como o leitor a experimenta.',
    tip: 'Primeira pessoa cria conexão emocional. Terceira pessoa oferece visão mais ampla.',
    sections: [
      HelpSection(
        emoji: '👴',
        title: 'Primeira Pessoa Idoso/Idosa',
        forWhat: 'Memórias, sabedoria, reflexões sobre o passado',
        combineWith: 'Estilo "Reflexivo e Memórias"',
        example: '"Eu tinha 65 anos quando descobri a traição..."',
      ),
      HelpSection(
        emoji: '👤',
        title: 'Primeira Pessoa Jovem',
        forWhat: 'Aventuras, descobertas, energia',
        combineWith: 'Estilo "Ação Rápida" ou "Livre"',
        example: '"Eu não sabia que aquela noite mudaria tudo..."',
      ),
      HelpSection(
        emoji: '📖',
        title: 'Terceira Pessoa',
        forWhat: 'Narrativa clássica, múltiplos personagens, épicos',
        combineWith: 'Qualquer estilo (mais versátil)',
        example: '"Maria vendeu a casa sem olhar para trás..."',
      ),
    ],
  );
  
  // ==================== TEMPLATES PRÉ-CONFIGURADOS ====================
  
  static final templates = [
    ConfigTemplate(
      emoji: '👵',
      title: 'Mulher idosa contando memórias de família',
      description: 'História reflexiva sobre segredos e traições familiares',
      config: {
        'perspective': 'primeira_pessoa_mulher_idosa',
        'narrativeStyle': 'reflexivo_memorias',
        'tema': 'Família Disfuncional',
        'subtema': 'Segredos Familiares',
      },
      resultPreview: '"Eu me lembro da tarde em que descobri a verdade sobre minha nora..."',
    ),
    
    ConfigTemplate(
      emoji: '🤠',
      title: 'Velho Oeste 1890 - Duelo de Vingança',
      description: 'Épico de vingança no Velho Oeste americano',
      config: {
        'perspective': 'terceira_pessoa',
        'narrativeStyle': 'epico_periodo',
        'tema': 'Vingança',
        'subtema': 'Justiça Vigilante',
        'localizacao': 'Ano 1890, Cidade Fantasma no Velho Oeste',
        'genre': 'western',
      },
      avoids: ['Carros', 'Telefones', 'Luz elétrica', 'Linguagem moderna'],
      resultPreview: '"O sol de 1890 castigava Red Rock. Jake ajustou o revólver..."',
    ),
    
    ConfigTemplate(
      emoji: '🔍',
      title: 'Curiosidades Históricas',
      description: 'Fatos surpreendentes narrados de forma envolvente',
      config: {
        'perspective': 'terceira_pessoa',
        'narrativeStyle': 'educativo_curioso',
        'tema': 'Curiosidades',
        'subtema': 'Fatos Históricos Inusitados',
      },
      resultPreview: '"Você sabia que durante a Segunda Guerra Mundial..."',
    ),
    
    ConfigTemplate(
      emoji: '⚡',
      title: 'Thriller de Vingança Moderna',
      description: 'Ação rápida e suspense crescente',
      config: {
        'perspective': 'terceira_pessoa',
        'narrativeStyle': 'acao_rapida',
        'tema': 'Vingança',
        'subtema': 'Vingança Destrutiva',
        'localizacao': 'São Paulo, Brasil',
      },
      resultPreview: '"A porta explodiu. João correu. Sangue na parede."',
    ),
    
    ConfigTemplate(
      emoji: '💔',
      title: 'Drama Romântico - Segunda Chance',
      description: 'História poética sobre amor e redenção',
      config: {
        'perspective': 'primeira_pessoa_mulher_jovem',
        'narrativeStyle': 'lirico_poetico',
        'tema': 'Drama/Romance',
        'subtema': 'Segunda Chance',
      },
      resultPreview: '"As águas do tempo lavaram as feridas, mas a cicatriz permanecia..."',
    ),
    
    ConfigTemplate(
      emoji: '🏛️',
      title: 'Biografia Histórica - Líder Revolucionário',
      description: 'Épico sobre figura histórica real',
      config: {
        'perspective': 'terceira_pessoa',
        'narrativeStyle': 'epico_periodo',
        'tema': 'Biografias',
        'subtema': 'Líderes Históricos',
        'localizacao': 'França, Ano 1789',
      },
      avoids: ['Tecnologias modernas', 'Linguagem contemporânea'],
    ),
    
    ConfigTemplate(
      emoji: '🧪',
      title: 'Descoberta Científica',
      description: 'Narrativa educativa sobre ciência',
      config: {
        'perspective': 'terceira_pessoa',
        'narrativeStyle': 'educativo_curioso',
        'tema': 'Ciência',
        'subtema': 'Descobertas Científicas',
      },
      resultPreview: '"Marie Curie não sabia que aquela noite no laboratório mudaria a história..."',
    ),
    
    ConfigTemplate(
      emoji: '👻',
      title: 'Terror Psicológico',
      description: 'Suspense crescente e atmosfera tensa',
      config: {
        'perspective': 'primeira_pessoa_homem_jovem',
        'narrativeStyle': 'acao_rapida',
        'tema': 'Terror/Sobrenatural',
        'subtema': 'Horror Psicológico',
      },
      resultPreview: '"Eu ouvi os passos no corredor. Mas eu estava sozinho em casa..."',
    ),
    
    ConfigTemplate(
      emoji: '🚀',
      title: 'Ficção Científica - Viagem Espacial',
      description: 'Aventura futurista no espaço',
      config: {
        'perspective': 'terceira_pessoa',
        'narrativeStyle': 'ficcional_livre',
        'tema': 'Ficção Científica',
        'subtema': 'Exploração Espacial',
        'localizacao': 'Nave espacial, Ano 2187',
      },
    ),
    
    ConfigTemplate(
      emoji: '💼',
      title: 'Ascensão Empresarial',
      description: 'História de ambição e poder corporativo',
      config: {
        'perspective': 'primeira_pessoa_homem_jovem',
        'narrativeStyle': 'ficcional_livre',
        'tema': 'Poder e Corrupção',
        'subtema': 'Império Empresarial',
        'genre': 'business',
      },
      resultPreview: '"Eu construí esse império do zero. E não deixaria ninguém destruí-lo..."',
    ),
    
    ConfigTemplate(
      emoji: '🌍',
      title: 'Documentário de Viagem',
      description: 'Narrativa sobre lugares exóticos',
      config: {
        'perspective': 'primeira_pessoa_mulher_jovem',
        'narrativeStyle': 'educativo_curioso',
        'tema': 'Viagens/Lugares',
        'subtema': 'Destinos Exóticos',
        'localizacao': 'Tóquio, Japão',
      },
      resultPreview: '"Cheguei em Tóquio sem saber o que esperar. O que descobri mudou minha vida..."',
    ),
    
    ConfigTemplate(
      emoji: '⚔️',
      title: 'Épico Medieval',
      description: 'Aventura de cavaleiros e batalhas',
      config: {
        'perspective': 'terceira_pessoa',
        'narrativeStyle': 'epico_periodo',
        'tema': 'Ação/Aventura',
        'subtema': 'Jornada Épica',
        'localizacao': 'Inglaterra, Ano 1215',
      },
      avoids: ['Armas de fogo', 'Tecnologia moderna'],
      resultPreview: '"O cavaleiro desembainhou a espada. A batalha final começaria ao amanhecer..."',
    ),
  ];
}
```

### **PASSO 3: Criar Widget de Tooltip**

**Arquivo: `lib/presentation/widgets/field_tooltip.dart`**

```dart
import 'package:flutter/material.dart';

class FieldTooltipWidget extends StatelessWidget {
  final String text;
  final Widget child;
  
  const FieldTooltipWidget({
    Key? key,
    required this.text,
    required this.child,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: text,
      preferBelow: false,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        height: 1.4,
      ),
      waitDuration: const Duration(milliseconds: 500),
      child: child,
    );
  }
}
```

### **PASSO 4: Criar Widget de Help Popup**

**Arquivo: `lib/presentation/widgets/field_help_popup.dart`**

```dart
import 'package:flutter/material.dart';
import '../../data/models/field_help.dart';

class FieldHelpPopup extends StatelessWidget {
  final FieldHelp help;
  
  const FieldHelpPopup({
    Key? key,
    required this.help,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    help.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Description
            Text(
              help.description,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            
            // Sections
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: help.sections.length,
                separatorBuilder: (_, __) => const SizedBox(height: 20),
                itemBuilder: (context, index) {
                  final section = help.sections[index];
                  return _buildSection(section);
                },
              ),
            ),
            
            // Tip
            if (help.tip != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '💡 Dica: ${help.tip}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue[900],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildSection(HelpSection section) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            '${section.emoji} ${section.title}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // For what
          _buildInfoRow('Para:', section.forWhat),
          
          // Combine with
          if (section.combineWith != null)
            _buildInfoRow('Combine com:', section.combineWith!),
          
          // Example
          if (section.example != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '📝 ${section.example}',
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[800],
                ),
              ),
            ),
          ],
          
          // Avoids
          if (section.avoids != null)
            _buildInfoRow('⚠️ Evita:', section.avoids!, isWarning: true),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value, {bool isWarning = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isWarning ? Colors.orange[700] : Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: isWarning ? Colors.orange[900] : Colors.grey[800],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

### **PASSO 5: Criar Modal de Templates**

**Arquivo: `lib/presentation/widgets/templates_modal.dart`**

```dart
import 'package:flutter/material.dart';
import '../../data/models/field_help.dart';

class TemplatesModal extends StatelessWidget {
  final List<ConfigTemplate> templates;
  final Function(Map<String, dynamic>) onApplyTemplate;
  
  const TemplatesModal({
    Key? key,
    required this.templates,
    required this.onApplyTemplate,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 800),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Text(
                  '🎯 Combinações Recomendadas',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Escolha uma configuração pronta ou inspire-se para criar a sua:',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 24),
            
            // Templates List
            Expanded(
              child: ListView.separated(
                itemCount: templates.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  return _buildTemplateCard(context, templates[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTemplateCard(BuildContext context, ConfigTemplate template) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            '${template.emoji} ${template.title}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          // Description
          Text(
            template.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 16),
          
          // Config items
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: template.config.entries.map((entry) {
              return _buildConfigChip(entry.key, entry.value);
            }).toList(),
          ),
          
          // Result preview
          if (template.resultPreview != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '📝 ${template.resultPreview}',
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[800],
                ),
              ),
            ),
          ],
          
          // Avoids
          if (template.avoids != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Text(
                  '⚠️ Evita:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange[700],
                  ),
                ),
                ...template.avoids!.map((avoid) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      avoid,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[900],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ],
          
          // Apply button
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                onApplyTemplate(template.config);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Configuração aplicada com sucesso!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.check),
              label: const Text('Aplicar Esta Configuração'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildConfigChip(String key, dynamic value) {
    String label = _getConfigLabel(key, value);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Text(
        '✅ $label',
        style: TextStyle(
          fontSize: 12,
          color: Colors.blue[900],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
  
  String _getConfigLabel(String key, dynamic value) {
    switch (key) {
      case 'perspective':
        return 'Perspectiva: ${_getPerspectiveLabel(value)}';
      case 'narrativeStyle':
        return 'Estilo: ${_getStyleLabel(value)}';
      case 'tema':
        return 'Tema: $value';
      case 'subtema':
        return 'Subtema: $value';
      case 'localizacao':
        return 'Localização: $value';
      case 'genre':
        return 'Tipo: ${_getGenreLabel(value)}';
      default:
        return '$key: $value';
    }
  }
  
  String _getPerspectiveLabel(String value) {
    switch (value) {
      case 'primeira_pessoa_mulher_idosa': return 'Primeira Pessoa Mulher Idosa';
      case 'primeira_pessoa_homem_jovem': return 'Primeira Pessoa Homem Jovem';
      case 'terceira_pessoa': return 'Terceira Pessoa';
      default: return value;
    }
  }
  
  String _getStyleLabel(String value) {
    switch (value) {
      case 'reflexivo_memorias': return 'Reflexivo e Memórias';
      case 'epico_periodo': return 'Épico de Época';
      case 'educativo_curioso': return 'Educativo e Curioso';
      case 'acao_rapida': return 'Ação Rápida';
      case 'lirico_poetico': return 'Lírico e Poético';
      default: return 'Livre';
    }
  }
  
  String _getGenreLabel(String value) {
    switch (value) {
      case 'western': return 'Western';
      case 'business': return 'Business';
      default: return value;
    }
  }
}
```

### **PASSO 6: Integrar na UI Existente**

**Exemplo de uso em um campo:**

```dart
// No arquivo da página de configuração
import '../widgets/field_tooltip.dart';
import '../widgets/field_help_popup.dart';
import '../widgets/templates_modal.dart';
import '../../data/constants/help_content.dart';

// No build do dropdown:
Row(
  children: [
    Expanded(
      child: FieldTooltipWidget(
        text: HelpContent.tooltips['narrativeStyle']!.text,
        child: DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Estilo de Narração',
          ),
          value: _selectedStyle,
          items: GenerationConfig.narrativeStyleLabels.entries.map((entry) {
            return DropdownMenuItem(
              value: entry.key,
              child: Text(entry.value),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedStyle = value);
          },
        ),
      ),
    ),
    
    // Info button
    IconButton(
      icon: Icon(Icons.info_outline, color: Colors.blue[700]),
      tooltip: 'Ver detalhes e exemplos',
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => FieldHelpPopup(
            help: HelpContent.narrativeStyleHelp,
          ),
        );
      },
    ),
  ],
),

// Botão para abrir templates (no topo da página)
ElevatedButton.icon(
  onPressed: () {
    showDialog(
      context: context,
      builder: (context) => TemplatesModal(
        templates: HelpContent.templates,
        onApplyTemplate: (config) {
          // Aplicar configuração aos campos
          setState(() {
            _perspective = config['perspective'] ?? _perspective;
            _narrativeStyle = config['narrativeStyle'] ?? _narrativeStyle;
            _tema = config['tema'] ?? _tema;
            _subtema = config['subtema'] ?? _subtema;
            _localizacao = config['localizacao'] ?? _localizacao;
            _genre = config['genre'];
          });
        },
      ),
    );
  },
  icon: const Icon(Icons.lightbulb),
  label: const Text('Ver Combinações Recomendadas'),
  style: ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  ),
)
```

---

## 📊 RESUMO DO SISTEMA

### **3 Níveis de Ajuda:**

| Nível | Quando Aparece | O que Mostra | Complexidade |
|-------|----------------|--------------|--------------|
| **1. Tooltip** | Hover no campo | Dica rápida (1 linha) | Baixa |
| **2. Popup ℹ️** | Clique no botão info | Detalhes + Exemplos | Média |
| **3. Templates** | Botão "Combinações" | 12 configs prontas | Alta |

### **Vantagens:**

✅ **Usuário novato:** Usa templates prontos  
✅ **Usuário intermediário:** Lê popups e ajusta  
✅ **Usuário avançado:** Ignora ajudas, configura direto  
✅ **Não polui UI:** Aparece só quando necessário  
✅ **Educativo:** Ensina através de exemplos reais  

---

## ⏱️ TEMPO DE IMPLEMENTAÇÃO

| Tarefa | Tempo |
|--------|-------|
| Criar modelos de dados | 30 min |
| Escrever conteúdo de ajuda (12 templates) | 2h |
| Criar widget de tooltip | 30 min |
| Criar popup de ajuda | 1h 30min |
| Criar modal de templates | 2h |
| Integrar na UI existente | 1h 30min |
| **TOTAL** | **~8 horas** |

---

## ✅ RECOMENDAÇÃO

**Implementar em 2 fases:**

**FASE 1 (4h):** Tooltips + Popups ℹ️
- Adicionar tooltip em cada campo
- Adicionar botão ℹ️ com popup detalhado
- Criar conteúdo de ajuda básico

**FASE 2 (4h):** Sistema de Templates
- Criar modal com 12 configurações prontas
- Botão "Aplicar Configuração" funcional
- Testar aplicação automática

**Quer que eu implemente a Fase 1 agora (tooltips + popups)?** 🚀
