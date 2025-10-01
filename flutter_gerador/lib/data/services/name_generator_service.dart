import 'dart:math';

class NameGeneratorService {
  static final Set<String> _usedNames = <String>{};
  static final Map<String, DateTime> _recentlyUsedNames = <String, DateTime>{};
  static const Duration _quarantineDuration = Duration(minutes: 30); // Quarentena de 30 minutos
  
  // Base de dados massiva de nomes por idioma e características - EXPANDIDA PARA 12 IDIOMAS
  static const Map<String, Map<String, Map<String, List<String>>>> _namesDatabase = {
    'pt': {
      'masculino': {
        'jovem': [
          'Rafael', 'Gabriel', 'Lucas', 'Matheus', 'Bruno', 'Daniel', 'Pedro', 'João',
          'Felipe', 'Guilherme', 'Thiago', 'André', 'Diego', 'Rodrigo', 'Marcelo',
          'Leonardo', 'Eduardo', 'Carlos', 'Fernando', 'Vinícius', 'Alexandre', 'Gustavo',
          'Henrique', 'Igor', 'Caio', 'Renato', 'Fábio', 'Márcio', 'Leandro', 'Sérgio',
          'Victor', 'Arthur', 'Enzo', 'Miguel', 'Davi', 'Lorenzo', 'Theo', 'Nicolas',
          'Samuel', 'Benjamin', 'Caleb', 'Elias', 'Noah', 'Isaac', 'Anthony', 'Mason',
          // NOMES ADICIONAIS BRASILEIROS JOVENS
          'Giovani', 'Otávio', 'Cauã', 'Kaique', 'Kayque', 'Kauê', 'Bryan', 'Ryan',
          'Luan', 'Juan', 'Ian', 'Yuri', 'Kevin', 'Nathan', 'Vitor', 'Heitor',
          'Murilo', 'Renan', 'Wallace', 'Wesley', 'William', 'Ygor', 'Luca', 'Noah',
          'Emanuel', 'Benício', 'Joaquim', 'Vicente', 'Valentim', 'Bento', 'Ravi', 'Davi',
          'Bernardo', 'Pietro', 'Lorenzo', 'Théo', 'Martin', 'Tomás', 'Anthony', 'Oliver',
          'Asafe', 'Calebe', 'Enrico', 'Giovanni', 'Léo', 'Lucca', 'Matteo', 'Gael'
        ],
        'maduro': [
          'Roberto', 'José', 'Antonio', 'Francisco', 'Manuel', 'João', 'Carlos', 'Luis',
          'Paulo', 'Miguel', 'Pedro', 'Ângelo', 'Alberto', 'Raul', 'Sergio', 'Marco',
          'Ricardo', 'Flávio', 'César', 'Júlio', 'Rogério', 'Mário', 'Wilson', 'Nelson',
          'Edson', 'Wagner', 'Luiz', 'Antônio', 'Geraldo', 'Orlando', 'Osvaldo', 'Reinaldo',
          'Waldir', 'Valdir', 'Ademir', 'Adir', 'Almir', 'Aparecido', 'Benedito', 'Cláudio',
          // NOMES ADICIONAIS BRASILEIROS MADUROS
          'Ailton', 'Altair', 'Amauri', 'Antônio Carlos', 'Armando', 'Arnaldo', 'Artur',
          'Augusto', 'Bento', 'Braz', 'Caetano', 'Celso', 'Cleber', 'Cristiano', 'Dario',
          'Décio', 'Dirceu', 'Donizete', 'Dorival', 'Edgard', 'Edmundo', 'Evandro', 'Everton',
          'Fausto', 'Fernando Carlos', 'Gilberto', 'Glauco', 'Hamilton', 'Hélio', 'Humberto',
          'Ivan', 'Jair', 'Jefferson', 'Jonas', 'Jorge', 'Josué', 'Laércio', 'Lázaro',
          'Leandro', 'Luciano', 'Luís Carlos', 'Marcelo', 'Marcos', 'Mauro', 'Milson', 'Nilson'
        ],
        'idoso': [
          'João', 'José', 'Antônio', 'Francisco', 'Carlos', 'Paulo', 'Pedro', 'Lucas',
          'Luiz', 'Marcos', 'Luis', 'Miguel', 'Ângelo', 'Alberto', 'Sebastião', 'Joaquim',
          'Benedito', 'Severino', 'Raimundo', 'Domingos', 'Geraldo', 'Osvaldo', 'Vicente',
          'Manoel', 'Valdir', 'Waldir', 'Ademir', 'Aparecido', 'Djalma', 'Arnaldo',
          'Hermínio', 'Expedito', 'Celestino', 'Alcides', 'Evaristo', 'Humberto', 'Palmiro',
          // NOMES ADICIONAIS BRASILEIROS IDOSOS
          'Abílio', 'Adão', 'Adolfo', 'Afonso', 'Agostinho', 'Aldo', 'Alvaro', 'Amadeu',
          'Amândio', 'Américo', 'Aníbal', 'Aristides', 'Armando', 'Arturo', 'Atílio',
          'Avelino', 'Belmiro', 'Bertoldo', 'Camilo', 'Cândido', 'Clementino', 'Constâncio',
          'Cristóvão', 'Custódio', 'Delfim', 'Diamantino', 'Eládio', 'Elói', 'Emílio',
          'Estevão', 'Eugênio', 'Eusébio', 'Fabrício', 'Felisberto', 'Florêncio', 'Fortunato',
          'Galdino', 'Gaspar', 'Genésio', 'Gonçalo', 'Gregório', 'Heráclito', 'Hilário'
        ]
      },
      'feminino': {
        'jovem': [
          'Ana', 'Maria', 'Julia', 'Beatriz', 'Larissa', 'Camila', 'Amanda', 'Gabriela',
          'Isabella', 'Sophia', 'Alice', 'Manuela', 'Helena', 'Valentina', 'Luna', 'Lara',
          'Giovanna', 'Marina', 'Clara', 'Cecília', 'Luiza', 'Yasmin', 'Luana', 'Rafaela',
          'Fernanda', 'Mariana', 'Carolina', 'Isabela', 'Letícia', 'Natália', 'Bruna',
          'Vitória', 'Heloísa', 'Lívia', 'Melissa', 'Nicole', 'Rebeca', 'Aline', 'Priscila',
          // NOMES ADICIONAIS BRASILEIROS JOVENS FEMININOS
          'Bianca', 'Carla', 'Débora', 'Eduarda', 'Flávia', 'Gisele', 'Ingrid', 'Jéssica',
          'Karla', 'Laís', 'Milena', 'Nayara', 'Olivia', 'Patrícia', 'Raquel', 'Sabrina',
          'Taís', 'Úrsula', 'Valéria', 'Wendel', 'Ximena', 'Yara', 'Zélia', 'Agatha',
          'Brenda', 'Catarina', 'Dandara', 'Elisa', 'Fabiana', 'Graziela', 'Isadora', 'Jade',
          'Karine', 'Lorena', 'Mayara', 'Nina', 'Otávia', 'Pietra', 'Quintana', 'Roberta',
          'Samara', 'Thaís', 'Valentina', 'Wanda', 'Yolanda', 'Zara', 'Emanuelle', 'Isis'
        ],
        'maduro': [
          'Maria', 'Ana', 'Francisca', 'Antônia', 'Adriana', 'Juliana', 'Márcia', 'Fernanda',
          'Patricia', 'Aline', 'Sandra', 'Renata', 'Cristiane', 'Simone', 'Daniela', 'Angela',
          'Débora', 'Luciana', 'Claudia', 'Eliane', 'Vanessa', 'Regina', 'Mônica', 'Silvia',
          'Sônia', 'Rita', 'Rosana', 'Vera', 'Lúcia', 'Magda', 'Solange', 'Célia', 'Marta',
          'Tânia', 'Rosângela', 'Cleide', 'Edna', 'Marlene', 'Neuza', 'Terezinha',
          // NOMES ADICIONAIS BRASILEIROS MADUROS FEMININOS
          'Alzira', 'Benedita', 'Carmem', 'Dalva', 'Elvira', 'Fátima', 'Glória', 'Helena',
          'Iara', 'Joana', 'Kátia', 'Lurdes', 'Marilene', 'Nair', 'Odete', 'Palmira',
          'Quitéria', 'Rosa', 'Sueli', 'Tarcila', 'Valdete', 'Wilma', 'Yolanda', 'Zuleika',
          'Antonieta', 'Bernadete', 'Cristina', 'Dora', 'Estela', 'Flávia', 'Graça', 'Hortência',
          'Ivone', 'Juracy', 'Kelly', 'Lourdes', 'Marlusa', 'Nilda', 'Olga', 'Penha',
          'Raquel', 'Sebastiana', 'Teresa', 'Valderez', 'Wanessa', 'Yvone', 'Zenaide'
        ],
        'idoso': [
          'Maria', 'Ana', 'Francisca', 'Antônia', 'Rita', 'Rosa', 'Elizabeth', 'Helena',
          'Conceição', 'Aparecida', 'Raimunda', 'Luzia', 'Vera', 'Lúcia', 'Terezinha',
          'Benedita', 'Marlene', 'Neuza', 'Edna', 'Cleide', 'Célia', 'Marta', 'Sônia',
          'Magda', 'Solange', 'Rosana', 'Silvana', 'Ivone', 'Jurema', 'Dalva', 'Zilda',
          'Dirce', 'Norma', 'Ilda', 'Olga', 'Alice', 'Nair', 'Diva', 'Elza', 'Odete',
          // NOMES ADICIONAIS BRASILEIROS IDOSOS FEMININOS
          'Adelaide', 'Beatriz', 'Carlota', 'Deolinda', 'Esmeralda', 'Filomena', 'Guilhermina',
          'Hermínia', 'Idalina', 'Joventina', 'Laudelina', 'Miguelina', 'Nazaré', 'Otília',
          'Palmira', 'Quitéria', 'Raimunda', 'Sebastiana', 'Teodora', 'Urbana', 'Vicência',
          'Walquíria', 'Ximena', 'Yolanda', 'Zulmira', 'Albertina', 'Benvinda', 'Corina',
          'Domingas', 'Esperança', 'Firmina', 'Generosa', 'Honorina', 'Inocência', 'Josefina',
          'Laurinda', 'Maximina', 'Norberta', 'Olegária', 'Perpétua', 'Quintiliana'
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
    },
    'es': {
      'masculino': {
        'jovem': [
          'Carlos', 'José', 'Luis', 'Miguel', 'Juan', 'Antonio', 'Francisco', 'Manuel',
          'Diego', 'Rafael', 'Daniel', 'Alejandro', 'David', 'Gabriel', 'Jorge',
          'Fernando', 'Sergio', 'Ricardo', 'Eduardo', 'Roberto', 'Mario', 'Pedro',
          'Andrés', 'Javier', 'Oscar', 'Emilio', 'Pablo', 'Raúl', 'Gonzalo', 'Mateo'
        ],
        'maduro': [
          'Antonio', 'José', 'Manuel', 'Francisco', 'Juan', 'David', 'Carlos', 'Miguel',
          'Luis', 'Rafael', 'Daniel', 'Alejandro', 'Fernando', 'Jorge', 'Sergio',
          'Ricardo', 'Eduardo', 'Roberto', 'Mario', 'Pedro', 'Andrés', 'Javier',
          'Oscar', 'Emilio', 'Pablo', 'Raúl', 'Gonzalo', 'Mateo', 'Álvaro', 'Ignacio'
        ],
        'idoso': [
          'José', 'Antonio', 'Manuel', 'Francisco', 'Juan', 'Luis', 'Carlos', 'Miguel',
          'Rafael', 'Pedro', 'Ángel', 'Jesús', 'Marcos', 'Joaquín', 'Salvador',
          'Ramón', 'Vicente', 'Domingo', 'Pascual', 'Esteban', 'Lorenzo', 'Tomás'
        ]
      },
      'feminino': {
        'jovem': [
          'María', 'Carmen', 'Josefa', 'Isabel', 'Ana', 'Dolores', 'Pilar', 'Teresa',
          'Rosa', 'Mercedes', 'Francisca', 'Concepción', 'Antonia', 'Esperanza',
          'Sofía', 'Lucía', 'Elena', 'Paula', 'Clara', 'Julia', 'Adriana', 'Valeria',
          'Natalia', 'Andrea', 'Camila', 'Isabella', 'Victoria', 'Alejandra'
        ],
        'maduro': [
          'María', 'Carmen', 'Josefa', 'Isabel', 'Ana', 'Dolores', 'Pilar', 'Teresa',
          'Rosa', 'Mercedes', 'Francisca', 'Concepción', 'Antonia', 'Esperanza',
          'Ángeles', 'Encarnación', 'Remedios', 'Amparo', 'Soledad', 'Gloria'
        ],
        'idoso': [
          'María', 'Carmen', 'Josefa', 'Isabel', 'Ana', 'Dolores', 'Pilar', 'Teresa',
          'Rosa', 'Mercedes', 'Francisca', 'Concepción', 'Antonia', 'Esperanza',
          'Ángeles', 'Encarnación', 'Remedios', 'Amparo', 'Soledad', 'Gloria',
          'Asunción', 'Purificación', 'Inmaculada', 'Milagros', 'Virtudes'
        ]
      }
    },
    'fr': {
      'masculino': {
        'jovem': [
          'Jean', 'Pierre', 'Michel', 'André', 'Philippe', 'Alain', 'Bernard', 'Robert',
          'Jacques', 'Daniel', 'Henri', 'François', 'Christian', 'Claude', 'Pascal',
          'Louis', 'Marcel', 'Paul', 'René', 'Roger', 'Antoine', 'Nicolas', 'Laurent',
          'Julien', 'Maxime', 'Alexandre', 'Thomas', 'Kevin', 'Florian', 'Romain'
        ],
        'maduro': [
          'Jean', 'Pierre', 'Michel', 'André', 'Philippe', 'Alain', 'Bernard', 'Robert',
          'Jacques', 'Daniel', 'Henri', 'François', 'Christian', 'Claude', 'Pascal',
          'Louis', 'Marcel', 'Paul', 'René', 'Roger', 'Gérard', 'Yves', 'Serge'
        ],
        'idoso': [
          'Jean', 'Pierre', 'Michel', 'André', 'Philippe', 'Bernard', 'Robert', 'Jacques',
          'Daniel', 'Henri', 'François', 'Louis', 'Marcel', 'Paul', 'René', 'Roger',
          'Gérard', 'Yves', 'Serge', 'Maurice', 'Raymond', 'Lucien', 'Albert', 'Émile'
        ]
      },
      'feminino': {
        'jovem': [
          'Marie', 'Monique', 'Françoise', 'Catherine', 'Christine', 'Sylvie', 'Isabelle',
          'Martine', 'Nathalie', 'Brigitte', 'Dominique', 'Véronique', 'Chantal',
          'Sophie', 'Julie', 'Émilie', 'Manon', 'Léa', 'Clara', 'Camille', 'Emma',
          'Sarah', 'Inès', 'Jade', 'Lola', 'Zoé', 'Chloé', 'Océane', 'Pauline'
        ],
        'maduro': [
          'Marie', 'Monique', 'Françoise', 'Catherine', 'Christine', 'Sylvie', 'Isabelle',
          'Martine', 'Nathalie', 'Brigitte', 'Dominique', 'Véronique', 'Chantal',
          'Michèle', 'Annie', 'Jacqueline', 'Nicole', 'Éliane', 'Denise', 'Colette'
        ],
        'idoso': [
          'Marie', 'Jeanne', 'Marguerite', 'Germaine', 'Yvonne', 'Madeleine', 'Suzanne',
          'Marcelle', 'Louise', 'Andrée', 'Simone', 'Denise', 'Colette', 'Henriette',
          'Paulette', 'Georgette', 'Odette', 'Lucienne', 'Raymonde', 'Juliette'
        ]
      }
    },
    'it': {
      'masculino': {
        'jovem': [
          'Giuseppe', 'Antonio', 'Giovanni', 'Mario', 'Francesco', 'Angelo', 'Vincenzo',
          'Pietro', 'Salvatore', 'Carlo', 'Franco', 'Domenico', 'Bruno', 'Paolo',
          'Michele', 'Giorgio', 'Luigi', 'Roberto', 'Sergio', 'Marco', 'Andrea',
          'Matteo', 'Alessandro', 'Lorenzo', 'Davide', 'Federico', 'Simone', 'Luca'
        ],
        'maduro': [
          'Giuseppe', 'Antonio', 'Giovanni', 'Mario', 'Francesco', 'Angelo', 'Vincenzo',
          'Pietro', 'Salvatore', 'Carlo', 'Franco', 'Domenico', 'Bruno', 'Paolo',
          'Michele', 'Giorgio', 'Luigi', 'Roberto', 'Sergio', 'Marco', 'Gino', 'Aldo'
        ],
        'idoso': [
          'Giuseppe', 'Antonio', 'Giovanni', 'Mario', 'Francesco', 'Angelo', 'Vincenzo',
          'Pietro', 'Salvatore', 'Carlo', 'Franco', 'Domenico', 'Bruno', 'Paolo',
          'Michele', 'Giorgio', 'Luigi', 'Umberto', 'Enzo', 'Rino', 'Silvio', 'Guido'
        ]
      },
      'feminino': {
        'jovem': [
          'Maria', 'Anna', 'Giuseppina', 'Rosa', 'Angela', 'Giovanna', 'Teresa',
          'Lucia', 'Carmela', 'Caterina', 'Francesca', 'Rita', 'Antonia', 'Elisabetta',
          'Giulia', 'Chiara', 'Alessandra', 'Francesca', 'Valentina', 'Federica',
          'Martina', 'Sara', 'Ilaria', 'Giorgia', 'Elisa', 'Silvia', 'Paola'
        ],
        'maduro': [
          'Maria', 'Anna', 'Giuseppina', 'Rosa', 'Angela', 'Giovanna', 'Teresa',
          'Lucia', 'Carmela', 'Caterina', 'Francesca', 'Rita', 'Antonia', 'Elisabetta',
          'Grazia', 'Concetta', 'Vincenza', 'Rosaria', 'Assunta', 'Pasqualina'
        ],
        'idoso': [
          'Maria', 'Anna', 'Giuseppina', 'Rosa', 'Angela', 'Giovanna', 'Teresa',
          'Lucia', 'Carmela', 'Caterina', 'Francesca', 'Rita', 'Antonia', 'Elisabetta',
          'Grazia', 'Concetta', 'Vincenza', 'Rosaria', 'Assunta', 'Pasqualina',
          'Filomena', 'Addolorata', 'Immacolata', 'Nunzia', 'Pierina'
        ]
      }
    },
    'de': {
      'masculino': {
        'jovem': [
          'Peter', 'Hans', 'Wolfgang', 'Klaus', 'Jürgen', 'Dieter', 'Günter', 'Horst',
          'Helmut', 'Gerhard', 'Rainer', 'Werner', 'Bernd', 'Frank', 'Uwe', 'Thomas',
          'Andreas', 'Michael', 'Stefan', 'Christian', 'Alexander', 'Daniel', 'Martin',
          'Sebastian', 'Florian', 'Tobias', 'Jan', 'Matthias', 'Benjamin', 'Maximilian'
        ],
        'maduro': [
          'Peter', 'Hans', 'Wolfgang', 'Klaus', 'Jürgen', 'Dieter', 'Günter', 'Horst',
          'Helmut', 'Gerhard', 'Rainer', 'Werner', 'Bernd', 'Frank', 'Uwe', 'Thomas',
          'Andreas', 'Michael', 'Stefan', 'Manfred', 'Heinz', 'Joachim', 'Reinhard'
        ],
        'idoso': [
          'Peter', 'Hans', 'Wolfgang', 'Klaus', 'Jürgen', 'Dieter', 'Günter', 'Horst',
          'Helmut', 'Gerhard', 'Heinrich', 'Wilhelm', 'Karl', 'Friedrich', 'Hermann',
          'Adolf', 'Walter', 'Rudolf', 'Otto', 'Ernst', 'Paul', 'Georg', 'Franz'
        ]
      },
      'feminino': {
        'jovem': [
          'Ursula', 'Ingrid', 'Christa', 'Gisela', 'Monika', 'Barbara', 'Petra',
          'Sabine', 'Birgit', 'Gabriele', 'Andrea', 'Susanne', 'Karin', 'Martina',
          'Nicole', 'Stefanie', 'Claudia', 'Julia', 'Katharina', 'Sandra', 'Anna',
          'Laura', 'Sarah', 'Lisa', 'Jennifer', 'Vanessa', 'Christina', 'Jessica'
        ],
        'maduro': [
          'Ursula', 'Ingrid', 'Christa', 'Gisela', 'Monika', 'Barbara', 'Petra',
          'Sabine', 'Birgit', 'Gabriele', 'Andrea', 'Susanne', 'Karin', 'Martina',
          'Renate', 'Inge', 'Hildegard', 'Margret', 'Helga', 'Rosemarie', 'Waltraud'
        ],
        'idoso': [
          'Ursula', 'Ingrid', 'Christa', 'Gisela', 'Monika', 'Margarete', 'Gertrud',
          'Elisabeth', 'Hildegard', 'Irmgard', 'Elfriede', 'Lieselotte', 'Annemarie',
          'Waltraud', 'Brunhilde', 'Ingeborg', 'Hannelore', 'Gerda', 'Edith', 'Käthe'
        ]
      }
    },
    'ru': { // RUSSO - NOMES AUTÊNTICOS RUSSOS
      'masculino': {
        'jovem': [
          'Aleksandr', 'Dmitri', 'Sergei', 'Andrei', 'Aleksei', 'Pavel', 'Ivan', 'Mikhail',
          'Nikolai', 'Vladimir', 'Viktor', 'Oleg', 'Yuri', 'Maxim', 'Denis', 'Roman',
          'Kirill', 'Anton', 'Artem', 'Nikita', 'Daniil', 'Ilya', 'Ruslan', 'Stanislav',
          'Vadim', 'Konstantin', 'Evgeni', 'Anatoli', 'Grigori', 'Leonid', 'Boris', 'Fyodor',
          'Gleb', 'Makar', 'Timur', 'Yaroslav', 'Bogdan', 'Egor', 'Lev', 'Mark',
          'Stepan', 'Zakhar', 'David', 'Arsen', 'Demian', 'Platon', 'Savva', 'Tikhon'
        ],
        'maduro': [
          'Aleksandr', 'Vladimir', 'Sergei', 'Dmitri', 'Andrei', 'Nikolai', 'Mikhail', 'Viktor',
          'Yuri', 'Aleksei', 'Pavel', 'Ivan', 'Oleg', 'Boris', 'Anatoli', 'Evgeni',
          'Konstantin', 'Leonid', 'Grigori', 'Stanislav', 'Fyodor', 'Vadim', 'Roman', 'Denis',
          'Maksim', 'Kirill', 'Anton', 'Valeri', 'Gennadi', 'Arkadi', 'Ruslan', 'Vitali',
          'Ilya', 'Nikita', 'Artem', 'Daniil', 'Timofei', 'Matvei', 'Semyon', 'Rostislav'
        ],
        'idoso': [
          'Ivan', 'Aleksandr', 'Vladimir', 'Nikolai', 'Sergei', 'Mikhail', 'Dmitri', 'Boris',
          'Pavel', 'Fyodor', 'Aleksei', 'Viktor', 'Anatoli', 'Yuri', 'Evgeni', 'Leonid',
          'Konstantin', 'Grigori', 'Oleg', 'Stanislav', 'Vadim', 'Arkadi', 'Gennadi', 'Valeri',
          'Iosif', 'Stepan', 'Vasili', 'Pyotr', 'Georgi', 'Lev', 'Makar', 'Nikanor',
          'Panteleimon', 'Serafim', 'Tikhon', 'Zakhar', 'Efim', 'Kliment', 'Modest', 'Nazar'
        ]
      },
      'feminino': {
        'jovem': [
          'Anna', 'Maria', 'Elena', 'Ekaterina', 'Natasha', 'Irina', 'Svetlana', 'Olga',
          'Tatiana', 'Galina', 'Lyudmila', 'Larisa', 'Valentina', 'Nina', 'Vera', 'Nadezhda',
          'Anastasia', 'Daria', 'Polina', 'Ksenia', 'Yulia', 'Alina', 'Viktoria', 'Elizaveta',
          'Sofia', 'Varvara', 'Milana', 'Arina', 'Kira', 'Diana', 'Adelina', 'Angelina',
          'Veronika', 'Zlata', 'Eva', 'Karina', 'Lada', 'Margarita', 'Sabrina', 'Tamara',
          'Ulyana', 'Violetta', 'Yana', 'Zoya', 'Alyona', 'Bogdana', 'Emilia', 'Kristina'
        ],
        'maduro': [
          'Elena', 'Natasha', 'Irina', 'Svetlana', 'Olga', 'Anna', 'Tatiana', 'Galina',
          'Lyudmila', 'Maria', 'Larisa', 'Valentina', 'Nina', 'Vera', 'Nadezhda', 'Raisa',
          'Lyubov', 'Tamara', 'Zoya', 'Alla', 'Rimma', 'Inna', 'Zinaida', 'Albina',
          'Marina', 'Natalya', 'Yelena', 'Mariya', 'Lyudmila', 'Svetlana', 'Irina', 'Olga',
          'Ekaterina', 'Anastasia', 'Daria', 'Polina', 'Ksenia', 'Yulia', 'Viktoria', 'Sofia'
        ],
        'idoso': [
          'Anna', 'Maria', 'Elena', 'Ekaterina', 'Valentina', 'Galina', 'Nina', 'Vera',
          'Nadezhda', 'Lyudmila', 'Tatiana', 'Svetlana', 'Olga', 'Irina', 'Raisa', 'Lyubov',
          'Tamara', 'Zoya', 'Alla', 'Rimma', 'Inna', 'Zinaida', 'Klavdia', 'Pelageya',
          'Antonida', 'Efrosinia', 'Feodosia', 'Agafya', 'Avdotya', 'Domna', 'Fekla', 'Grusha',
          'Mavra', 'Praskovya', 'Stepanida', 'Ulita', 'Yevdokia', 'Agasha', 'Darya', 'Marfa'
        ]
      }
    },
    'ja': { // JAPONÊS - NOMES AUTÊNTICOS JAPONESES
      'masculino': {
        'jovem': [
          'Hiroshi', 'Takeshi', 'Akira', 'Masato', 'Kazuki', 'Yuki', 'Sota', 'Daiki',
          'Kenta', 'Ryo', 'Shun', 'Hayato', 'Yuto', 'Haruto', 'Ren', 'Kaito',
          'Toma', 'Sora', 'Yamato', 'Riku', 'Taiga', 'Yuma', 'Hinata', 'Minato',
          'Asahi', 'Aoi', 'Itsuki', 'Rui', 'Leo', 'Kai', 'Jin', 'Haru',
          'Tatsuya', 'Naoki', 'Shinji', 'Kenji', 'Tomoya', 'Daisuke', 'Ryota', 'Shota',
          'Kosuke', 'Yusuke', 'Masaki', 'Takuya', 'Satoshi', 'Ryuji', 'Taiki', 'Koki'
        ],
        'maduro': [
          'Hiroshi', 'Takeshi', 'Akira', 'Satoshi', 'Kenji', 'Masato', 'Naoki', 'Shinji',
          'Tatsuya', 'Kazuya', 'Tomoya', 'Daisuke', 'Ryota', 'Shota', 'Kosuke', 'Yusuke',
          'Masaki', 'Takuya', 'Ryuji', 'Taiki', 'Koki', 'Makoto', 'Junichi', 'Koichi',
          'Nobuyuki', 'Hideki', 'Yoshiaki', 'Kazuhiko', 'Masahiro', 'Toshiaki', 'Yukio', 'Minoru',
          'Osamu', 'Isamu', 'Susumu', 'Mamoru', 'Tsutomu', 'Hajime', 'Kaoru', 'Akio'
        ],
        'idoso': [
          'Hiroshi', 'Takeshi', 'Akira', 'Satoshi', 'Kenji', 'Taro', 'Jiro', 'Saburo',
          'Ichiro', 'Goro', 'Rokuro', 'Shichiro', 'Hachiro', 'Kichiro', 'Torao', 'Kumao',
          'Tetsuo', 'Haruo', 'Nobuo', 'Tadao', 'Yoshio', 'Kazuo', 'Takao', 'Hideo',
          'Masao', 'Teruo', 'Yukio', 'Akio', 'Mikio', 'Tokio', 'Shigeo', 'Tadashi',
          'Kiyoshi', 'Isao', 'Minoru', 'Osamu', 'Susumu', 'Mamoru', 'Tsutomu', 'Hajime'
        ]
      },
      'feminino': {
        'jovem': [
          'Yuki', 'Ai', 'Emi', 'Yui', 'Rei', 'Mio', 'Rio', 'Aoi', 'Saki', 'Mana',
          'Hana', 'Yuna', 'Risa', 'Kana', 'Sara', 'Mika', 'Rika', 'Nana', 'Maya', 'Aya',
          'Yura', 'Miyu', 'Akane', 'Momoka', 'Kokoro', 'Himari', 'Ichika', 'Koharu', 'Honoka', 'Sakura',
          'Misaki', 'Haruka', 'Ayaka', 'Sayaka', 'Mizuki', 'Asuka', 'Kiyomi', 'Mayumi', 'Naomi', 'Satomi',
          'Tomomi', 'Megumi', 'Yumiko', 'Akiko', 'Noriko', 'Hiroko', 'Keiko', 'Mariko'
        ],
        'maduro': [
          'Yuki', 'Ai', 'Emi', 'Yui', 'Misaki', 'Haruka', 'Ayaka', 'Sayaka', 'Mizuki', 'Asuka',
          'Kiyomi', 'Mayumi', 'Naomi', 'Satomi', 'Tomomi', 'Megumi', 'Yumiko', 'Akiko', 'Noriko', 'Hiroko',
          'Keiko', 'Mariko', 'Kumiko', 'Sachiko', 'Michiko', 'Kazuko', 'Masako', 'Takako', 'Hanako', 'Emiko',
          'Junko', 'Kyoko', 'Ryoko', 'Shoko', 'Yoko', 'Akemi', 'Kazumi', 'Hitomi', 'Izumi', 'Nozomi'
        ],
        'idoso': [
          'Hanako', 'Emiko', 'Junko', 'Kyoko', 'Ryoko', 'Shoko', 'Yoko', 'Michiko', 'Sachiko', 'Kazuko',
          'Masako', 'Takako', 'Kumiko', 'Akemi', 'Kazumi', 'Teruko', 'Yoshiko', 'Kimiko', 'Fumiko', 'Sumiko',
          'Haruko', 'Masako', 'Sadako', 'Tamako', 'Yasuko', 'Chiyoko', 'Fusako', 'Hatsuko', 'Itsuko', 'Katsuko',
          'Matsuko', 'Nobuko', 'Ruriko', 'Setsuko', 'Tsuruko', 'Umeko', 'Wakako', 'Yamako', 'Yukiko', 'Zusuko'
        ]
      }
    },
    'ar': { // ÁRABE - NOMES AUTÊNTICOS ÁRABES
      'masculino': {
        'jovem': [
          'Mohamed', 'Ahmed', 'Mahmoud', 'Mustafa', 'Youssef', 'Khaled', 'Amr', 'Tamer',
          'Omar', 'Karim', 'Hassan', 'Ali', 'Adel', 'Ashraf', 'Essam', 'Hany',
          'Ibrahim', 'Sherif', 'Wael', 'Waleed', 'Ayman', 'Hatem', 'Sameh', 'Tarek',
          'Basel', 'Fadi', 'Ghassan', 'Hasan', 'Issam', 'Jamal', 'Laith', 'Mazen',
          'Nabil', 'Qasim', 'Rami', 'Samir', 'Tariq', 'Usama', 'Walid', 'Yasin',
          'Zaid', 'Adham', 'Bilal', 'Diyaa', 'Farid', 'Hadi', 'Imad', 'Jihad'
        ],
        'maduro': [
          'Mohamed', 'Ahmed', 'Mahmoud', 'Mustafa', 'Ali', 'Hassan', 'Ibrahim', 'Omar',
          'Youssef', 'Khaled', 'Karim', 'Adel', 'Ashraf', 'Essam', 'Hany', 'Sherif',
          'Wael', 'Waleed', 'Ayman', 'Hatem', 'Sameh', 'Tarek', 'Amr', 'Tamer', 'Jamal',
          'Nabil', 'Samir', 'Tariq', 'Walid', 'Basel', 'Fadi', 'Ghassan', 'Issam', 'Mazen',
          'Qasim', 'Rami', 'Usama', 'Yasin', 'Zaid', 'Farid', 'Hadi', 'Imad', 'Jihad'
        ],
        'idoso': [
          'Mohamed', 'Ahmed', 'Mahmoud', 'Ali', 'Hassan', 'Ibrahim', 'Mustafa', 'Omar',
          'Abdullah', 'Abdul Rahman', 'Abdul Aziz', 'Abdul Majid', 'Farouk', 'Fouad', 'Gamal', 'Hamed',
          'Ismail', 'Lotfy', 'Magdy', 'Nasser', 'Rashad', 'Salah', 'Sayed', 'Zaki',
          'Anwar', 'Farid', 'Helmy', 'Kamal', 'Mokhtar', 'Nabeel', 'Ramzy', 'Safwat',
          'Tahsin', 'Wagdy', 'Yehia', 'Zeinab', 'Adly', 'Bahgat', 'Darwish', 'Ezzat'
        ]
      },
      'feminino': {
        'jovem': [
          'Fatima', 'Aisha', 'Maryam', 'Khadija', 'Zahra', 'Sara', 'Nour', 'Layla',
          'Amina', 'Yasmin', 'Dina', 'Rana', 'Reem', 'Lina', 'Maya', 'Nada',
          'Salma', 'Hala', 'Aya', 'Mariam', 'Rania', 'Dalia', 'Lara', 'Jana',
          'Noha', 'Rahma', 'Sama', 'Tala', 'Ward', 'Yara', 'Zeina', 'Alaa',
          'Bushra', 'Ghada', 'Heba', 'Iman', 'Jihan', 'Lobna', 'Maha', 'Nahla',
          'Rasha', 'Sahar', 'Taghrid', 'Widad', 'Zeinab', 'Abeer', 'Farah', 'Hadeel'
        ],
        'maduro': [
          'Fatima', 'Aisha', 'Maryam', 'Khadija', 'Amina', 'Zahra', 'Sara', 'Nour',
          'Layla', 'Yasmin', 'Dina', 'Rana', 'Reem', 'Lina', 'Salma', 'Hala',
          'Aya', 'Mariam', 'Rania', 'Dalia', 'Noha', 'Bushra', 'Ghada', 'Heba',
          'Iman', 'Jihan', 'Lobna', 'Maha', 'Nahla', 'Rasha', 'Sahar', 'Taghrid',
          'Widad', 'Zeinab', 'Abeer', 'Farah', 'Hadeel', 'Inaam', 'Karima', 'Laila'
        ],
        'idoso': [
          'Fatima', 'Aisha', 'Khadija', 'Maryam', 'Amina', 'Zahra', 'Zeinab', 'Saida',
          'Halima', 'Karima', 'Laila', 'Naima', 'Rabab', 'Samira', 'Thuraya', 'Wafaa',
          'Aziza', 'Bahija', 'Dawlat', 'Faiza', 'Haniya', 'Ihsan', 'Jameela', 'Latifa',
          'Mounira', 'Nabila', 'Raghda', 'Sakeena', 'Tahani', 'Warda', 'Yasmina', 'Zohra',
          'Aida', 'Badriya', 'Dalal', 'Emad', 'Fawzia', 'Galila', 'Hayat', 'Ikram'
        ]
      }
    },
    'zh': { // CHINÊS - NOMES AUTÊNTICOS CHINESES
      'masculino': {
        'jovem': [
          'Wei', 'Ming', 'Jun', 'Hao', 'Lei', 'Peng', 'Qiang', 'Gang',
          'Bin', 'Yong', 'Feng', 'Jiong', 'Long', 'Tao', 'Rui', 'Kai',
          'Xin', 'Chen', 'Yang', 'Lin', 'Dong', 'Hui', 'Jie', 'Chao',
          'Bo', 'Fei', 'Hang', 'Kun', 'Liang', 'Meng', 'Nan', 'Qi',
          'Shan', 'Ting', 'Xiang', 'Yu', 'Ze', 'An', 'Bao', 'Cong',
          'Da', 'En', 'Fa', 'Guang', 'He', 'Jian', 'Kang', 'Li'
        ],
        'maduro': [
          'Wei', 'Ming', 'Jun', 'Hao', 'Lei', 'Peng', 'Qiang', 'Gang',
          'Bin', 'Yong', 'Feng', 'Tao', 'Kai', 'Xin', 'Chen', 'Yang',
          'Lin', 'Dong', 'Hui', 'Jie', 'Chao', 'Bo', 'Liang', 'Kun',
          'Meng', 'Qi', 'Shan', 'Xiang', 'Yu', 'Ze', 'Jian', 'Kang',
          'Li', 'Qing', 'Ren', 'Shen', 'Tian', 'Wu', 'Xiao', 'Yue'
        ],
        'idoso': [
          'Wei', 'Ming', 'Jun', 'Lei', 'Qiang', 'Gang', 'Yong', 'Feng',
          'Jian', 'Qing', 'Ren', 'Shen', 'Tian', 'Wu', 'Xiao', 'Yue',
          'Zheng', 'Chang', 'Cheng', 'De', 'Fu', 'Gui', 'Hong', 'Jing',
          'Lao', 'Mao', 'Ping', 'Qin', 'Rong', 'Sheng', 'Wang', 'Wen',
          'Xian', 'Yan', 'Yao', 'Zhen', 'Zhong', 'Ai', 'Bei', 'Ci'
        ]
      },
      'feminino': {
        'jovem': [
          'Li', 'Mei', 'Xiu', 'Hua', 'Yun', 'Jing', 'Min', 'Yan',
          'Fang', 'Ying', 'Juan', 'Na', 'Xia', 'Hong', 'Ping', 'Qin',
          'Yu', 'Lan', 'Rui', 'Shan', 'Ting', 'Xin', 'Yue', 'Zi',
          'An', 'Bei', 'Cai', 'Dan', 'E', 'Fen', 'Gui', 'Hui',
          'Jin', 'Ke', 'Lu', 'Miao', 'Ning', 'Ou', 'Pei', 'Qiu',
          'Ru', 'Si', 'Tong', 'Wan', 'Xi', 'Ya', 'Zhu', 'Ai'
        ],
        'maduro': [
          'Li', 'Mei', 'Xiu', 'Hua', 'Yun', 'Jing', 'Min', 'Yan',
          'Fang', 'Ying', 'Juan', 'Na', 'Xia', 'Hong', 'Ping', 'Qin',
          'Yu', 'Lan', 'Rui', 'Shan', 'Ting', 'Xin', 'Yue', 'Zi',
          'Feng', 'Gui', 'Hui', 'Jin', 'Lu', 'Ning', 'Pei', 'Qiu',
          'Ru', 'Tong', 'Wan', 'Xi', 'Ya', 'Zhu', 'Chun', 'Cui'
        ],
        'idoso': [
          'Li', 'Mei', 'Xiu', 'Hua', 'Yun', 'Jing', 'Fang', 'Ying',
          'Juan', 'Hong', 'Ping', 'Qin', 'Yu', 'Lan', 'Feng', 'Gui',
          'Hui', 'Jin', 'Lu', 'Ning', 'Chun', 'Cui', 'Die', 'Er',
          'Gan', 'He', 'Ji', 'Kuan', 'Lian', 'Mian', 'Nuan', 'Ou',
          'Pan', 'Quan', 'Rou', 'Shu', 'Tian', 'Wen', 'Xiang', 'Yin'
        ]
      }
    },
    'ko': { // COREANO - NOMES AUTÊNTICOS COREANOS
      'masculino': {
        'jovem': [
          'Min-jun', 'Seo-jun', 'Do-yoon', 'Si-woo', 'Ha-jun', 'Ju-won', 'Gun-woo', 'Woo-jin',
          'Jun-seo', 'Ye-jun', 'Joo-won', 'Do-hyun', 'Ji-ho', 'Su-ho', 'Yu-jun', 'Min-ho',
          'Hyun-woo', 'Seung-woo', 'Ji-hoon', 'Jun-ho', 'Dong-hyun', 'Min-woo', 'Tae-hyun', 'Seung-min',
          'Jin-woo', 'Hyun-jin', 'Jae-min', 'Seong-min', 'Woo-seok', 'Jun-woo', 'Tae-min', 'Hyeon-jun',
          'Sang-woo', 'Jae-sung', 'Kyung-ho', 'Dong-wook', 'Chang-min', 'Joon-gi', 'Seung-ho', 'Min-gyu',
          'Tae-woo', 'Jung-ho', 'Byung-hun', 'Seok-jin', 'Won-bin', 'Hyun-bin', 'Ji-sung', 'Gong-yoo'
        ],
        'maduro': [
          'Min-jun', 'Seo-jun', 'Do-hyun', 'Ji-ho', 'Su-ho', 'Min-ho', 'Hyun-woo', 'Seung-woo',
          'Ji-hoon', 'Jun-ho', 'Dong-hyun', 'Min-woo', 'Tae-hyun', 'Jin-woo', 'Jae-min', 'Seong-min',
          'Woo-seok', 'Tae-min', 'Sang-woo', 'Jae-sung', 'Kyung-ho', 'Dong-wook', 'Chang-min', 'Seung-ho',
          'Min-gyu', 'Tae-woo', 'Jung-ho', 'Byung-hun', 'Seok-jin', 'Won-bin', 'Hyun-bin', 'Ji-sung',
          'Jae-hyun', 'Sung-kyu', 'Yong-hwa', 'Ki-tae', 'Jae-wook', 'Sang-hyun', 'Hee-chul', 'Dong-hae'
        ],
        'idoso': [
          'Young-soo', 'Kyung-soo', 'Jae-ho', 'Sung-ho', 'Jong-soo', 'Dong-soo', 'Myung-ho', 'Chul-soo',
          'Kwang-soo', 'Seung-ho', 'Jin-ho', 'Woo-sik', 'Jae-sung', 'Sang-woo', 'Jung-ho', 'Byung-hun',
          'Ki-duk', 'Seong-il', 'Jang-ho', 'Man-sik', 'Deok-su', 'Bong-sik', 'Ok-taek', 'Sun-kyun',
          'Hak-do', 'Yeon-seok', 'Seung-ryong', 'In-ho', 'Dong-il', 'Yoo-hwan', 'Sung-woong', 'Kwang-il',
          'Jin-goo', 'Yeon-ho', 'Do-won', 'Jae-rim', 'Min-sik', 'Kang-ho', 'Byung-mo', 'Jung-woo'
        ]
      },
      'feminino': {
        'jovem': [
          'Seo-yeon', 'Min-seo', 'Ji-woo', 'Ha-eun', 'So-yeon', 'Ye-eun', 'Chae-won', 'Ji-yeon',
          'Yu-jin', 'Soo-bin', 'Ga-eun', 'Ye-jin', 'Da-eun', 'Min-ju', 'Se-eun', 'Hyo-jung',
          'Eun-young', 'Ji-hyun', 'Soo-young', 'Yoon-ah', 'Tae-yeon', 'Jessica', 'Sunny', 'Tiffany',
          'Hye-yeon', 'Soo-jin', 'Yu-ri', 'Seo-hyun', 'IU', 'Suzy', 'Krystal', 'Luna',
          'So-jin', 'Hyo-min', 'Eun-jung', 'Qri', 'Bo-ram', 'So-yeon', 'Hyo-lyn', 'Bora',
          'Dara', 'CL', 'Minzy', 'Sandara', 'Gain', 'Narsha', 'Jea', 'Miryo'
        ],
        'maduro': [
          'Seo-yeon', 'Min-seo', 'Ji-woo', 'So-yeon', 'Ji-yeon', 'Yu-jin', 'Ye-jin', 'Min-ju',
          'Hyo-jung', 'Eun-young', 'Ji-hyun', 'Soo-young', 'Yoon-ah', 'Tae-yeon', 'Hye-yeon', 'Soo-jin',
          'Yu-ri', 'Seo-hyun', 'So-jin', 'Hyo-min', 'Eun-jung', 'Bo-ram', 'Hyo-lyn', 'Bora',
          'Jin-kyung', 'Hye-jin', 'Sun-young', 'Mi-ran', 'Jung-eun', 'Hee-kyung', 'Young-ae', 'Kyung-mi',
          'Soo-kyung', 'Jung-ah', 'Hyo-jin', 'Mi-kyung', 'Sun-ja', 'Young-ja', 'Kyung-ja', 'Sook-ja'
        ],
        'idoso': [
          'Young-ae', 'Kyung-mi', 'Soo-kyung', 'Jung-ah', 'Mi-kyung', 'Sun-ja', 'Young-ja', 'Kyung-ja',
          'Sook-ja', 'Ok-ja', 'Soon-ja', 'Jung-ja', 'Myung-ja', 'Hee-ja', 'Soo-ja', 'In-ja',
          'Moon-ja', 'Dong-ja', 'Bok-ja', 'Keum-ja', 'Chun-ja', 'Mal-ja', 'Sun-ok', 'Young-ok',
          'Kyung-ok', 'Soo-ok', 'Jung-ok', 'Myung-ok', 'Hee-ok', 'In-ok', 'Moon-ok', 'Dong-ok',
          'Bok-soon', 'Keum-soon', 'Chun-soon', 'Mal-soon', 'Sun-hee', 'Young-hee', 'Kyung-hee', 'Soo-hee'
        ]
      }
    },
    'hi': { // HINDI/INDIANO - NOMES AUTÊNTICOS INDIANOS
      'masculino': {
        'jovem': [
          'Arjun', 'Aarav', 'Vivaan', 'Aditya', 'Vihaan', 'Sai', 'Krishna', 'Aryan',
          'Dev', 'Daksh', 'Kiaan', 'Arnav', 'Ved', 'Ekaksh', 'Yug', 'Agastya',
          'Kabir', 'Karthik', 'Nikhil', 'Rohit', 'Varun', 'Akash', 'Ravi', 'Suresh',
          'Mohan', 'Gopal', 'Hari', 'Shyam', 'Kiran', 'Deepak', 'Manoj', 'Sanjay',
          'Vikram', 'Ajay', 'Rahul', 'Amit', 'Ankit', 'Ashish', 'Pradeep', 'Santosh',
          'Ramesh', 'Sunil', 'Anil', 'Vinod', 'Rajesh', 'Mahesh', 'Dinesh', 'Mukesh'
        ],
        'maduro': [
          'Arjun', 'Aditya', 'Krishna', 'Aryan', 'Dev', 'Arnav', 'Kabir', 'Karthik',
          'Nikhil', 'Rohit', 'Varun', 'Akash', 'Ravi', 'Suresh', 'Mohan', 'Gopal',
          'Hari', 'Shyam', 'Kiran', 'Deepak', 'Manoj', 'Sanjay', 'Vikram', 'Ajay',
          'Rahul', 'Amit', 'Ankit', 'Ashish', 'Pradeep', 'Santosh', 'Ramesh', 'Sunil',
          'Anil', 'Vinod', 'Rajesh', 'Mahesh', 'Dinesh', 'Mukesh', 'Pramod', 'Subhash'
        ],
        'idoso': [
          'Ram', 'Shyam', 'Hari', 'Gopal', 'Mohan', 'Suresh', 'Ramesh', 'Mahesh',
          'Rajesh', 'Dinesh', 'Mukesh', 'Sunil', 'Anil', 'Vinod', 'Pramod', 'Subhash',
          'Ganga', 'Daya', 'Bhagwan', 'Ishwar', 'Narayan', 'Govind', 'Mukund', 'Anand',
          'Shankar', 'Raghunath', 'Damodar', 'Madhav', 'Keshav', 'Janardan', 'Vishnu', 'Shiva',
          'Brahma', 'Indra', 'Varuna', 'Agni', 'Vayu', 'Prithvi', 'Chandra', 'Surya'
        ]
      },
      'feminino': {
        'jovem': [
          'Ananya', 'Diya', 'Aadhya', 'Saanvi', 'Avni', 'Arya', 'Myra', 'Sara',
          'Aditi', 'Riya', 'Kavya', 'Ishika', 'Priya', 'Aisha', 'Kiara', 'Tara',
          'Nisha', 'Pooja', 'Sneha', 'Meera', 'Sita', 'Gita', 'Rita', 'Sunita',
          'Anita', 'Savita', 'Kavita', 'Lalita', 'Mamta', 'Shanta', 'Kanta', 'Sushma',
          'Rekha', 'Lata', 'Asha', 'Usha', 'Radha', 'Kamala', 'Vimala', 'Nirmala',
          'Shyama', 'Rama', 'Ganga', 'Yamuna', 'Saraswati', 'Lakshmi', 'Parvati', 'Durga'
        ],
        'maduro': [
          'Ananya', 'Aditi', 'Riya', 'Kavya', 'Ishika', 'Priya', 'Aisha', 'Tara',
          'Nisha', 'Pooja', 'Sneha', 'Meera', 'Sita', 'Gita', 'Rita', 'Sunita',
          'Anita', 'Savita', 'Kavita', 'Lalita', 'Mamta', 'Shanta', 'Kanta', 'Sushma',
          'Rekha', 'Lata', 'Asha', 'Usha', 'Radha', 'Kamala', 'Vimala', 'Nirmala',
          'Pushpa', 'Kumari', 'Shanti', 'Shakti', 'Bhakti', 'Mukti', 'Preeti', 'Geeta'
        ],
        'idoso': [
          'Sita', 'Gita', 'Rita', 'Sunita', 'Anita', 'Savita', 'Kavita', 'Lalita',
          'Radha', 'Kamala', 'Vimala', 'Nirmala', 'Pushpa', 'Shanti', 'Shakti', 'Bhakti',
          'Devi', 'Mata', 'Amba', 'Uma', 'Gauri', 'Kali', 'Chandi', 'Bhagwati',
          'Janaki', 'Maithili', 'Vaidehi', 'Bhoomija', 'Prithvi', 'Avani', 'Dharti', 'Vasundhara',
          'Ganga', 'Yamuna', 'Saraswati', 'Godavari', 'Narmada', 'Kaveri', 'Sindhu', 'Tapi'
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

    // Remover nomes já usados NA HISTÓRIA ATUAL
    availableNames.removeWhere((name) => _usedNames.contains(name));
    
    // CORREÇÃO CRÍTICA: Também remover nomes em quarentena (histórias recentes)
    final now = DateTime.now();
    availableNames.removeWhere((name) {
      if (_recentlyUsedNames.containsKey(name)) {
        final timeSinceUse = now.difference(_recentlyUsedNames[name]!);
        return timeSinceUse < _quarantineDuration; // Ainda em quarentena
      }
      return false;
    });

    // Se esgotou os nomes, usar estratégias de recuperação
    if (availableNames.isEmpty) {
      print('⚠️ NOMES ESGOTADOS! Tentando recuperar...');
      
      // ESTRATÉGIA 1: Liberar nomes da quarentena mais antigos (mais de 15 minutos)
      final halfQuarantineTime = Duration(minutes: 15);
      final namesToFree = <String>[];
      
      _recentlyUsedNames.forEach((name, timestamp) {
        if (now.difference(timestamp) > halfQuarantineTime) {
          namesToFree.add(name);
        }
      });
      
      if (namesToFree.isNotEmpty) {
        print('🔓 LIBERANDO ${namesToFree.length} NOMES DA QUARENTENA: ${namesToFree.join(', ')}');
        for (final name in namesToFree) {
          _recentlyUsedNames.remove(name);
        }
        
        // Recarregar lista com nomes liberados
        if (genre == 'western' && _westernNames.containsKey(gender)) {
          availableNames = List.from(_westernNames[gender]!['todos']!);
        } else if (_namesDatabase.containsKey(language) &&
                   _namesDatabase[language]!.containsKey(gender) &&
                   _namesDatabase[language]![gender]!.containsKey(ageGroup)) {
          availableNames = List.from(_namesDatabase[language]![gender]![ageGroup]!);
        }
        
        // Remover apenas nomes da história atual e quarentena restante
        availableNames.removeWhere((name) => _usedNames.contains(name));
        availableNames.removeWhere((name) {
          if (_recentlyUsedNames.containsKey(name)) {
            final timeSinceUse = now.difference(_recentlyUsedNames[name]!);
            return timeSinceUse < _quarantineDuration;
          }
          return false;
        });
      }
      
      // ESTRATÉGIA 2: Se ainda não há nomes, usar fallback expandido
      if (availableNames.isEmpty) {
        print('🚨 USANDO FALLBACK DE EMERGÊNCIA');
        if (gender == 'masculino') {
          availableNames = ['Alexandre', 'Bernardo', 'Cássio', 'Dênis', 'Evandro', 'Fábio', 'Gustavo', 'Henrique'];
        } else {
          availableNames = ['Adriana', 'Bianca', 'Carla', 'Denise', 'Eliana', 'Fátima', 'Graça', 'Heloísa'];
        }
        // Remover ainda os já usados
        availableNames.removeWhere((name) => _usedNames.contains(name) || _recentlyUsedNames.containsKey(name));
      }
    }

    // Escolher nome aleatório dos disponíveis
    final random = Random();
    final selectedName = availableNames[random.nextInt(availableNames.length)];
    
    // Marcar como usado na história atual
    _usedNames.add(selectedName);
    
    print('✅ NOME SELECIONADO: $selectedName (${availableNames.length} disponíveis)');
    
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
    // CORREÇÃO: Em vez de reset total, mover nomes para quarentena
    final now = DateTime.now();
    
    // Mover nomes atuais para quarentena com timestamp
    for (final name in _usedNames) {
      _recentlyUsedNames[name] = now;
    }
    
    // Limpar lista de nomes da história atual
    _usedNames.clear();
    
    // Limpar quarentena de nomes antigos (mais de 30 minutos)
    _recentlyUsedNames.removeWhere((name, timestamp) {
      return now.difference(timestamp) > _quarantineDuration;
    });
    
    print('🎭 NOMES EM QUARENTENA: ${_recentlyUsedNames.length}');
    print('🎭 NOMES QUARENTENA: ${_recentlyUsedNames.keys.join(', ')}');
  }

  static int getUsedNamesCount() {
    return _usedNames.length;
  }
  
  static int getQuarantinedNamesCount() {
    final now = DateTime.now();
    return _recentlyUsedNames.values.where((timestamp) {
      return now.difference(timestamp) < _quarantineDuration;
    }).length;
  }
  
  static List<String> getQuarantinedNames() {
    final now = DateTime.now();
    return _recentlyUsedNames.entries.where((entry) {
      return now.difference(entry.value) < _quarantineDuration;
    }).map((entry) => entry.key).toList();
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
