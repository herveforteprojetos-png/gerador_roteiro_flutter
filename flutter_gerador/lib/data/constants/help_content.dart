import '../models/field_help.dart';

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
    'genre': FieldTooltip(
      'Categoria específica que influencia elementos e atmosfera da história.',
    ),
    'startWithTitle': FieldTooltip(
      'Inicia o roteiro usando exatamente a frase do título como gancho de abertura.',
    ),
    'videoFormat': FieldTooltip(
      'Otimiza extensão para diferentes formatos de vídeo no YouTube.',
    ),
  };
  
  // ==================== HELP POPUPS DETALHADOS ====================
  
  static final narrativeStyleHelp = FieldHelp(
    title: '🎬 Estilo de Narração',
    description: 'Define COMO a história é contada: o ritmo, tom e estrutura narrativa.',
    tip: 'Para história de mulher idosa reflexiva, use "Reflexivo e Memórias" + "1ª Pessoa Idosa"',
    sections: [
      HelpSection(
        emoji: '🎭',
        title: 'Livre (Ficção Tradicional)',
        forWhat: 'Histórias gerais, deixa IA decidir baseado no tema',
        combineWith: 'Qualquer tema e perspectiva',
        example: '"Maria vendeu a casa sem olhar para trás..."',
      ),
      HelpSection(
        emoji: '🧠',
        title: 'Reflexivo e Memórias',
        forWhat: 'Idosos contando passado, biografias, memórias pessoais',
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
        example: '"Você sabia que durante a Segunda Guerra Mundial..."',
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
  
  static final genreHelp = FieldHelp(
    title: '🎬 Tipo de História',
    description: 'Define a categoria e atmosfera específica da narrativa, influenciando elementos, vocabulário e tom.',
    tip: 'Combine com temas compatíveis. Ex: Western + tema Vingança',
    sections: [
      HelpSection(
        emoji: '🤠',
        title: 'Western',
        forWhat: 'Velho Oeste, duelos, saloons, justiceiros',
        combineWith: 'Estilo "Épico de Época" + localização com ano (1850-1900)',
        example: '"O sol escaldante castigava Red Rock. Jake ajustou o revólver..."',
      ),
      HelpSection(
        emoji: '💼',
        title: 'Business',
        forWhat: 'Mundo corporativo, negócios, poder empresarial',
        combineWith: 'Tema "Poder e Corrupção" ou "Ascensão e Queda"',
        example: '"A sala de reuniões estava tensa. O CEO sabia que alguém havia traído..."',
      ),
      HelpSection(
        emoji: '📖',
        title: 'Normal',
        forWhat: 'Histórias gerais sem categoria específica',
        combineWith: 'Qualquer tema',
      ),
    ],
  );
  
  static final localizationLevelHelp = FieldHelp(
    title: '🌍 Nível de Regionalismo',
    description: 'Define se a história usa referências culturais específicas do Brasil ou mantém linguagem universal.',
    tip: 'Use "Nacional" para histórias brasileiras com sabor local. Use "Global" para alcance internacional.',
    sections: [
      HelpSection(
        emoji: '🇧🇷',
        title: 'Nacional (Brasil)',
        forWhat: 'Histórias com identidade brasileira forte',
        combineWith: 'Localizações brasileiras (São Paulo, Nordeste, etc.)',
        example: 'Nomes: João, Maria, Antônio. Comidas: feijoada, brigadeiro',
      ),
      HelpSection(
        emoji: '🌎',
        title: 'Global (Universal)',
        forWhat: 'Histórias sem regionalismos, para público internacional',
        combineWith: 'Qualquer localização',
        example: 'Nomes: Alex, Sarah, Michael. Comidas genéricas.',
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
