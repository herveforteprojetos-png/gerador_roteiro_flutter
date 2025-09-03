import 'dart:math';

class NameGeneratorService {
  static final Set<String> _usedNames = <String>{};
  
  // Base de dados massiva de nomes por idioma e características
  static const Map<String, Map<String, Map<String, List<String>>>> _namesDatabase = {
    'pt': {
      'masculino': {
        'jovem': [
          'Rafael', 'Gabriel', 'Lucas', 'Matheus', 'Bruno', 'Daniel', 'Pedro', 'João',
          'Felipe', 'Guilherme', 'Thiago', 'André', 'Diego', 'Rodrigo', 'Marcelo',
          'Leonardo', 'Eduardo', 'Carlos', 'Fernando', 'Vinícius', 'Alexandre', 'Gustavo',
          'Henrique', 'Igor', 'Caio', 'Renato', 'Fábio', 'Márcio', 'Leandro', 'Sérgio',
          'Victor', 'Arthur', 'Enzo', 'Miguel', 'Davi', 'Lorenzo', 'Theo', 'Nicolas',
          'Samuel', 'Benjamin', 'Caleb', 'Elias', 'Noah', 'Isaac', 'Anthony', 'Mason'
        ],
        'maduro': [
          'Roberto', 'José', 'Antonio', 'Francisco', 'Manuel', 'João', 'Carlos', 'Luis',
          'Paulo', 'Miguel', 'Pedro', 'Ângelo', 'Alberto', 'Raul', 'Sergio', 'Marco',
          'Ricardo', 'Flávio', 'César', 'Júlio', 'Rogério', 'Mário', 'Wilson', 'Nelson',
          'Edson', 'Wagner', 'Luiz', 'Antônio', 'Geraldo', 'Orlando', 'Osvaldo', 'Reinaldo',
          'Waldir', 'Valdir', 'Ademir', 'Adir', 'Almir', 'Aparecido', 'Benedito', 'Cláudio'
        ],
        'idoso': [
          'João', 'José', 'Antônio', 'Francisco', 'Carlos', 'Paulo', 'Pedro', 'Lucas',
          'Luiz', 'Marcos', 'Luis', 'Miguel', 'Ângelo', 'Alberto', 'Sebastião', 'Joaquim',
          'Benedito', 'Severino', 'Raimundo', 'Domingos', 'Geraldo', 'Osvaldo', 'Vicente',
          'Manoel', 'Valdir', 'Waldir', 'Ademir', 'Aparecido', 'Djalma', 'Arnaldo',
          'Hermínio', 'Expedito', 'Celestino', 'Alcides', 'Evaristo', 'Humberto', 'Palmiro'
        ]
      },
      'feminino': {
        'jovem': [
          'Ana', 'Maria', 'Julia', 'Beatriz', 'Larissa', 'Camila', 'Amanda', 'Gabriela',
          'Isabella', 'Sophia', 'Alice', 'Manuela', 'Helena', 'Valentina', 'Luna', 'Lara',
          'Giovanna', 'Marina', 'Clara', 'Cecília', 'Luiza', 'Yasmin', 'Luana', 'Rafaela',
          'Fernanda', 'Mariana', 'Carolina', 'Isabela', 'Letícia', 'Natália', 'Bruna',
          'Vitória', 'Heloísa', 'Lívia', 'Melissa', 'Nicole', 'Rebeca', 'Aline', 'Priscila'
        ],
        'maduro': [
          'Maria', 'Ana', 'Francisca', 'Antônia', 'Adriana', 'Juliana', 'Márcia', 'Fernanda',
          'Patricia', 'Aline', 'Sandra', 'Renata', 'Cristiane', 'Simone', 'Daniela', 'Angela',
          'Débora', 'Luciana', 'Claudia', 'Eliane', 'Vanessa', 'Regina', 'Mônica', 'Silvia',
          'Sônia', 'Rita', 'Rosana', 'Vera', 'Lúcia', 'Magda', 'Solange', 'Célia', 'Marta',
          'Tânia', 'Rosângela', 'Cleide', 'Edna', 'Marlene', 'Neuza', 'Terezinha'
        ],
        'idoso': [
          'Maria', 'Ana', 'Francisca', 'Antônia', 'Rita', 'Rosa', 'Elizabeth', 'Helena',
          'Conceição', 'Aparecida', 'Raimunda', 'Luzia', 'Vera', 'Lúcia', 'Terezinha',
          'Benedita', 'Marlene', 'Neuza', 'Edna', 'Cleide', 'Célia', 'Marta', 'Sônia',
          'Magda', 'Solange', 'Rosana', 'Silvana', 'Ivone', 'Jurema', 'Dalva', 'Zilda',
          'Dirce', 'Norma', 'Ilda', 'Olga', 'Alice', 'Nair', 'Diva', 'Elza', 'Odete'
        ]
      }
    },
    'en': {
      'masculino': {
        'jovem': [
          'James', 'Michael', 'Robert', 'David', 'William', 'Richard', 'Joseph', 'Thomas',
          'Christopher', 'Charles', 'Daniel', 'Matthew', 'Anthony', 'Mark', 'Donald',
          'Steven', 'Paul', 'Andrew', 'Joshua', 'Kenneth', 'Kevin', 'Brian', 'George',
          'Timothy', 'Ronald', 'Jason', 'Edward', 'Jeffrey', 'Ryan', 'Jacob', 'Gary',
          'Nicholas', 'Eric', 'Jonathan', 'Stephen', 'Larry', 'Justin', 'Scott', 'Brandon',
          'Benjamin', 'Samuel', 'Frank', 'Gregory', 'Raymond', 'Alexander', 'Patrick'
        ],
        'maduro': [
          'Robert', 'John', 'Michael', 'David', 'William', 'Richard', 'Thomas', 'Charles',
          'Christopher', 'Daniel', 'Paul', 'Mark', 'Donald', 'George', 'Kenneth', 'Steven',
          'Edward', 'Brian', 'Ronald', 'Anthony', 'Kevin', 'Jason', 'Jeffrey', 'Matthew',
          'Gary', 'Timothy', 'Jose', 'Larry', 'Jeffrey', 'Frank', 'Scott', 'Eric'
        ],
        'idoso': [
          'Robert', 'John', 'James', 'Michael', 'William', 'David', 'Richard', 'Charles',
          'Joseph', 'Thomas', 'Christopher', 'Daniel', 'Paul', 'Mark', 'Donald', 'George',
          'Kenneth', 'Steven', 'Edward', 'Brian', 'Ronald', 'Anthony', 'Kevin', 'Harold',
          'Walter', 'Arthur', 'Albert', 'Eugene', 'Wayne', 'Ralph', 'Louis', 'Philip'
        ]
      },
      'feminino': {
        'jovem': [
          'Mary', 'Patricia', 'Jennifer', 'Linda', 'Elizabeth', 'Barbara', 'Susan', 'Jessica',
          'Sarah', 'Karen', 'Nancy', 'Lisa', 'Betty', 'Helen', 'Sandra', 'Donna', 'Carol',
          'Ruth', 'Sharon', 'Michelle', 'Laura', 'Sarah', 'Kimberly', 'Deborah', 'Dorothy',
          'Lisa', 'Nancy', 'Karen', 'Betty', 'Helen', 'Sandra', 'Donna', 'Carol', 'Ruth',
          'Sharon', 'Michelle', 'Laura', 'Sarah', 'Kimberly', 'Deborah', 'Dorothy', 'Amy'
        ],
        'maduro': [
          'Mary', 'Patricia', 'Jennifer', 'Linda', 'Elizabeth', 'Barbara', 'Susan', 'Jessica',
          'Karen', 'Nancy', 'Lisa', 'Betty', 'Helen', 'Sandra', 'Donna', 'Carol', 'Ruth',
          'Sharon', 'Michelle', 'Laura', 'Kimberly', 'Deborah', 'Dorothy', 'Amy', 'Angela'
        ],
        'idoso': [
          'Mary', 'Patricia', 'Linda', 'Barbara', 'Elizabeth', 'Jennifer', 'Maria', 'Susan',
          'Margaret', 'Dorothy', 'Lisa', 'Nancy', 'Karen', 'Betty', 'Helen', 'Sandra',
          'Donna', 'Carol', 'Ruth', 'Sharon', 'Michelle', 'Laura', 'Sarah', 'Kimberly',
          'Deborah', 'Dorothy', 'Amy', 'Angela', 'Brenda', 'Emma', 'Olivia', 'Cynthia'
        ]
      }
    }
  };

  // Nomes específicos para Western
  static const Map<String, Map<String, List<String>>> _westernNames = {
    'masculino': {
      'todos': [
        'Jedediah', 'Ezekiel', 'Josiah', 'Caleb', 'Silas', 'Amos', 'Obadiah', 'Thaddeus',
        'Bartholomew', 'Zebedee', 'Malachi', 'Gideon', 'Solomon', 'Abraham', 'Isaac',
        'Wyatt', 'Clint', 'Colt', 'Buck', 'Tex', 'Jake', 'Luke', 'Cole', 'Wade', 'Rex',
        'Hank', 'Clay', 'Beau', 'Jeb', 'Zeke', 'Ike', 'Duke', 'Cash', 'Dash', 'Knox'
      ]
    },
    'feminino': {
      'todos': [
        'Clementine', 'Evangeline', 'Prudence', 'Temperance', 'Charity', 'Faith', 'Hope',
        'Grace', 'Mercy', 'Patience', 'Constance', 'Felicity', 'Serenity', 'Trinity',
        'Belle', 'Rose', 'Sage', 'Pearl', 'Ruby', 'Opal', 'Jade', 'Star', 'Dawn',
        'Luna', 'Iris', 'Hazel', 'Fern', 'Lily', 'Daisy', 'Violet', 'Magnolia'
      ]
    }
  };

  static String generateName({
    required String gender, // 'masculino' ou 'feminino'
    required String ageGroup, // 'jovem', 'maduro', 'idoso'
    required String language, // 'pt', 'en', 'es', etc.
    String? genre, // 'western', 'business', 'family'
  }) {
    List<String> availableNames = [];

    // Se for western, usar nomes temáticos
    if (genre == 'western' && _westernNames.containsKey(gender)) {
      availableNames = List.from(_westernNames[gender]!['todos']!);
    } 
    // Senão, usar banco normal por idioma
    else if (_namesDatabase.containsKey(language) &&
             _namesDatabase[language]!.containsKey(gender) &&
             _namesDatabase[language]![gender]!.containsKey(ageGroup)) {
      availableNames = List.from(_namesDatabase[language]![gender]![ageGroup]!);
    }
    
    // Fallback para português se idioma não encontrado
    if (availableNames.isEmpty && language != 'pt') {
      if (_namesDatabase['pt']!.containsKey(gender) &&
          _namesDatabase['pt']![gender]!.containsKey(ageGroup)) {
        availableNames = List.from(_namesDatabase['pt']![gender]![ageGroup]!);
      }
    }

    // Fallback final
    if (availableNames.isEmpty) {
      availableNames = ['João', 'Maria', 'Pedro', 'Ana'];
    }

    // Remover nomes já usados
    availableNames.removeWhere((name) => _usedNames.contains(name));

    // Se esgotou os nomes, resetar o conjunto
    if (availableNames.isEmpty) {
      _usedNames.clear();
      // Recarregar nomes disponíveis
      if (genre == 'western' && _westernNames.containsKey(gender)) {
        availableNames = List.from(_westernNames[gender]!['todos']!);
      } else if (_namesDatabase.containsKey(language) &&
                 _namesDatabase[language]!.containsKey(gender) &&
                 _namesDatabase[language]![gender]!.containsKey(ageGroup)) {
        availableNames = List.from(_namesDatabase[language]![gender]![ageGroup]!);
      }
    }

    // Escolher nome aleatório
    final random = Random();
    final selectedName = availableNames[random.nextInt(availableNames.length)];
    
    // Marcar como usado
    _usedNames.add(selectedName);
    
    return selectedName;
  }

  static List<String> generateMultipleNames({
    required int count,
    required String gender,
    required String ageGroup,
    required String language,
    String? genre,
  }) {
    final names = <String>[];
    for (int i = 0; i < count; i++) {
      names.add(generateName(
        gender: gender,
        ageGroup: ageGroup,
        language: language,
        genre: genre,
      ));
    }
    return names;
  }

  static void resetUsedNames() {
    _usedNames.clear();
  }

  static int getUsedNamesCount() {
    return _usedNames.length;
  }

  static List<String> getAvailableLanguages() {
    return _namesDatabase.keys.toList();
  }

  static Map<String, int> getNameStats(String language) {
    if (!_namesDatabase.containsKey(language)) return {};
    
    final stats = <String, int>{};
    final langData = _namesDatabase[language]!;
    
    for (final gender in langData.keys) {
      for (final ageGroup in langData[gender]!.keys) {
        final key = '${gender}_$ageGroup';
        stats[key] = langData[gender]![ageGroup]!.length;
      }
    }
    
    return stats;
  }
}
