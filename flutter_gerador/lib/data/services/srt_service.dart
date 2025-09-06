import 'dart:math';

class SrtService {
  /// Gera legendas SRT a partir de um texto
  static String generateSrt(String text, {
    int wordsPerMinute = 120, // Reduzido para CapCut
    int maxCharactersPerSubtitle = 500, // Configuração CapCut
    int maxLinesPerSubtitle = 3, // Permitir 3 linhas
    double minDisplayTime = 2.0, // Mínimo para CapCut
    double maxDisplayTime = 8.0, // Máximo para CapCut
    double gapBetweenSubtitles = 1.0, // Intervalo CapCut
    int minWordsPerBlock = 30, // Mínimo de palavras por bloco
    int maxWordsPerBlock = 100, // Máximo de palavras por bloco
    double blockDurationSeconds = 30.0, // Duração por bloco (segundos)
    double intervalBetweenBlocks = 20.0, // Intervalo entre blocos (segundos)
  }) {
    if (text.trim().isEmpty) return '';

    // 1. LIMPEZA E PREPARAÇÃO DO TEXTO
    String cleanedText = _cleanText(text);
    
    // 2. DIVISÃO EM SEGMENTOS PARA CAPCUT
    List<String> segments = _createCapCutSegments(
      cleanedText, 
      minWordsPerBlock,
      maxWordsPerBlock,
      maxCharactersPerSubtitle, 
      maxLinesPerSubtitle
    );
    
    // 3. CÁLCULO DE TEMPOS PARA CAPCUT
    List<SrtSegment> timedSegments = _calculateCapCutTimings(
      segments,
      blockDurationSeconds,
      intervalBetweenBlocks,
    );
    
    // 4. GERAÇÃO DO ARQUIVO SRT
    return _generateSrtContent(timedSegments);
  }

  /// Limpa o texto removendo formatações desnecessárias
  static String _cleanText(String text) {
    return text
        .replaceAll(RegExp(r'\n+'), ' ') // Remove quebras de linha
        .replaceAll(RegExp(r'\s+'), ' ') // Remove espaços extras
        .replaceAll(RegExp(r'[*_#]+'), '') // Remove marcadores de markdown
        .trim();
  }

  /// Cria segmentos de texto respeitando limites de caracteres e linhas
  static List<String> _createSegments(String text, int maxChars, int maxLines) {
    List<String> words = text.split(' ');
    List<String> segments = [];
    String currentSegment = '';
    
    for (String word in words) {
      String testSegment = currentSegment.isEmpty ? word : '$currentSegment $word';
      
      // Verifica se excede o limite de caracteres
      if (testSegment.length > maxChars) {
        if (currentSegment.isNotEmpty) {
          // Verifica se pode quebrar em linhas
          String optimizedSegment = _optimizeSegmentBreaks(currentSegment, maxChars, maxLines);
          segments.add(optimizedSegment);
          currentSegment = word;
        } else {
          // Palavra muito longa, força a quebra
          segments.add(word);
          currentSegment = '';
        }
      } else {
        currentSegment = testSegment;
      }
    }
    
    if (currentSegment.isNotEmpty) {
      String optimizedSegment = _optimizeSegmentBreaks(currentSegment, maxChars, maxLines);
      segments.add(optimizedSegment);
    }
    
    return segments;
  }

  /// Otimiza quebras de linha dentro de um segmento
  static String _optimizeSegmentBreaks(String segment, int maxChars, int maxLines) {
    if (segment.length <= maxChars ~/ maxLines) {
      return segment; // Cabe em uma linha
    }
    
    List<String> words = segment.split(' ');
    List<String> lines = [];
    String currentLine = '';
    
    for (String word in words) {
      String testLine = currentLine.isEmpty ? word : '$currentLine $word';
      
      if (testLine.length > maxChars ~/ maxLines && currentLine.isNotEmpty) {
        lines.add(currentLine);
        currentLine = word;
        
        if (lines.length >= maxLines) break;
      } else {
        currentLine = testLine;
      }
    }
    
    if (currentLine.isNotEmpty && lines.length < maxLines) {
      lines.add(currentLine);
    }
    
    return lines.join('\n');
  }

  /// Calcula os tempos de início e fim para cada segmento
  static List<SrtSegment> _calculateTimings(
    List<String> segments,
    int wordsPerMinute,
    double minDisplayTime,
    double maxDisplayTime,
    double gapBetweenSubtitles,
  ) {
    List<SrtSegment> timedSegments = [];
    double currentTime = 0.0;
    
    for (int i = 0; i < segments.length; i++) {
      String segment = segments[i];
      
      // Calcula duração baseada no número de palavras
      int wordCount = segment.split(' ').length;
      double readingTime = (wordCount / wordsPerMinute) * 60; // em segundos
      
      // Aplica limites mínimos e máximos
      double duration = readingTime.clamp(minDisplayTime, maxDisplayTime);
      
      // Ajusta para legendas muito curtas
      if (segment.length < 20) {
        duration = max(duration, minDisplayTime);
      }
      
      SrtSegment timedSegment = SrtSegment(
        index: i + 1,
        startTime: currentTime,
        endTime: currentTime + duration,
        text: segment,
      );
      
      timedSegments.add(timedSegment);
      currentTime += duration + gapBetweenSubtitles;
    }
    
    return timedSegments;
  }

  /// Cria segmentos de texto otimizados para CapCut
  static List<String> _createCapCutSegments(
    String text, 
    int minWordsPerBlock,
    int maxWordsPerBlock,
    int maxCharactersPerSubtitle, 
    int maxLinesPerSubtitle
  ) {
    List<String> words = text.split(RegExp(r'\s+'));
    List<String> segments = [];
    String currentSegment = '';
    int currentWordCount = 0;
    
    for (String word in words) {
      String potentialSegment = currentSegment.isEmpty 
          ? word 
          : '$currentSegment $word';
      
      // Verificar se adicionar esta palavra violaria alguma regra
      bool wouldExceedChars = potentialSegment.length > maxCharactersPerSubtitle;
      bool wouldExceedWords = currentWordCount >= maxWordsPerBlock;
      bool reachedMinWords = currentWordCount >= minWordsPerBlock;
      
      // Se violaria as regras e já temos o mínimo, criar novo segmento
      if ((wouldExceedChars || wouldExceedWords) && reachedMinWords) {
        if (currentSegment.isNotEmpty) {
          segments.add(currentSegment.trim());
        }
        currentSegment = word;
        currentWordCount = 1;
      } else {
        currentSegment = potentialSegment;
        currentWordCount++;
      }
    }
    
    // Adicionar último segmento se não estiver vazio
    if (currentSegment.isNotEmpty) {
      segments.add(currentSegment.trim());
    }
    
    return segments;
  }

  /// Calcula timings específicos para CapCut com blocos e intervalos
  static List<SrtSegment> _calculateCapCutTimings(
    List<String> segments,
    double blockDurationSeconds,
    double intervalBetweenBlocks,
  ) {
    List<SrtSegment> timedSegments = [];
    double currentTime = 0.0;
    
    for (int i = 0; i < segments.length; i++) {
      String segment = segments[i];
      
      // Tempo de início do segmento
      double startTime = currentTime;
      
      // Tempo de fim: início + duração do bloco
      double endTime = startTime + blockDurationSeconds;
      
      timedSegments.add(SrtSegment(
        index: i + 1,
        startTime: startTime,
        endTime: endTime,
        text: segment,
      ));
      
      // Próximo segmento começa após o intervalo
      currentTime = endTime + intervalBetweenBlocks;
    }
    
    return timedSegments;
  }

  /// Gera o conteúdo final do arquivo SRT
  static String _generateSrtContent(List<SrtSegment> segments) {
    StringBuffer srtContent = StringBuffer();
    
    for (SrtSegment segment in segments) {
      srtContent.writeln(segment.index);
      srtContent.writeln('${_formatTime(segment.startTime)} --> ${_formatTime(segment.endTime)}');
      srtContent.writeln(segment.text);
      srtContent.writeln();
    }
    
    return srtContent.toString().trim();
  }

  /// Formata o tempo no padrão SRT (HH:MM:SS,mmm)
  static String _formatTime(double seconds) {
    int totalMilliseconds = (seconds * 1000).round();
    int hours = totalMilliseconds ~/ 3600000;
    int minutes = (totalMilliseconds % 3600000) ~/ 60000;
    int secs = (totalMilliseconds % 60000) ~/ 1000;
    int milliseconds = totalMilliseconds % 1000;
    
    return '${hours.toString().padLeft(2, '0')}:'
           '${minutes.toString().padLeft(2, '0')}:'
           '${secs.toString().padLeft(2, '0')},'
           '${milliseconds.toString().padLeft(3, '0')}';
  }

  /// Valida e ajusta parâmetros de configuração
  static Map<String, dynamic> validateConfig({
    int? wordsPerMinute,
    int? maxCharactersPerSubtitle,
    int? maxLinesPerSubtitle,
    double? minDisplayTime,
    double? maxDisplayTime,
    double? gapBetweenSubtitles,
  }) {
    return {
      'wordsPerMinute': (wordsPerMinute ?? 160).clamp(100, 300),
      'maxCharactersPerSubtitle': (maxCharactersPerSubtitle ?? 80).clamp(40, 120),
      'maxLinesPerSubtitle': (maxLinesPerSubtitle ?? 2).clamp(1, 3),
      'minDisplayTime': (minDisplayTime ?? 1.5).clamp(0.5, 5.0),
      'maxDisplayTime': (maxDisplayTime ?? 7.0).clamp(3.0, 15.0),
      'gapBetweenSubtitles': (gapBetweenSubtitles ?? 0.3).clamp(0.0, 2.0),
    };
  }
}

/// Classe para representar um segmento de legenda
class SrtSegment {
  final int index;
  final double startTime;
  final double endTime;
  final String text;

  SrtSegment({
    required this.index,
    required this.startTime,
    required this.endTime,
    required this.text,
  });

  @override
  String toString() {
    return 'SrtSegment(index: $index, start: $startTime, end: $endTime, text: $text)';
  }
}
