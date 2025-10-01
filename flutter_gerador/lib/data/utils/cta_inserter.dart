import '../models/cta_config.dart';

/// Utility class for inserting CTAs into generated scripts
class CtaInserter {
  /// Insert CTAs into script content at appropriate positions
  static String insertCtasIntoScript({
    required String scriptContent,
    required List<CtaItem> ctas,
  }) {
    if (ctas.isEmpty || scriptContent.isEmpty) return scriptContent;
    
    // Split script into paragraphs
    final paragraphs = _splitIntoParagraphs(scriptContent);
    if (paragraphs.length < 2) return scriptContent; // Too short for CTAs
    
    // Sort CTAs by position for proper insertion order
    final sortedCtas = _sortCtasByPosition(ctas, paragraphs.length);
    
    // Insert CTAs
    String result = scriptContent;
    int insertionOffset = 0;
    
    for (final cta in sortedCtas) {
      final insertionPoint = _calculateInsertionPoint(
        cta,
        paragraphs,
        scriptContent,
        insertionOffset,
      );
      
      if (insertionPoint >= 0) {
        final ctaText = _formatCtaForInsertion(cta.content);
        result = _insertAtPosition(result, ctaText, insertionPoint + insertionOffset);
        insertionOffset += ctaText.length;
      }
    }
    
    return result;
  }

  /// Split script content into logical paragraphs
  static List<String> _splitIntoParagraphs(String content) {
    return content
        .split(RegExp(r'\n\s*\n'))
        .where((p) => p.trim().isNotEmpty)
        .toList();
  }

  /// Sort CTAs by their intended position in the script
  static List<CtaItem> _sortCtasByPosition(List<CtaItem> ctas, int paragraphCount) {
    final sortedCtas = List<CtaItem>.from(ctas);
    
    sortedCtas.sort((a, b) {
      final posA = _getPositionPercentage(a, paragraphCount);
      final posB = _getPositionPercentage(b, paragraphCount);
      return posA.compareTo(posB);
    });
    
    return sortedCtas;
  }

  /// Get position percentage for a CTA
  static double _getPositionPercentage(CtaItem cta, int paragraphCount) {
    switch (cta.position) {
      case CtaPosition.beginning:
        return 15.0; // After introduction (around 15%)
      case CtaPosition.middle:
        return 45.0; // Middle of story (around 45%)
      case CtaPosition.end:
        return 85.0; // Before conclusion (around 85%)
      case CtaPosition.custom:
        return (cta.customPositionPercentage ?? 50).toDouble();
    }
  }

  /// Calculate the exact insertion point in the original text
  static int _calculateInsertionPoint(
    CtaItem cta,
    List<String> paragraphs,
    String originalContent,
    int currentOffset,
  ) {
    final targetPercentage = _getPositionPercentage(cta, paragraphs.length);
    
    // Calculate target paragraph index
    final targetParagraphIndex = ((paragraphs.length - 1) * targetPercentage / 100).round();
    final safeIndex = targetParagraphIndex.clamp(0, paragraphs.length - 1);
    
    // Find the end of the target paragraph in the original content
    int position = 0;
    int currentParagraphIndex = 0;
    
    final lines = originalContent.split('\n');
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      
      if (line.trim().isEmpty) {
        // Empty line - potential paragraph boundary
        if (currentParagraphIndex == safeIndex) {
          // Insert after this paragraph
          return position + line.length + 1; // +1 for the newline
        }
        
        // Check if we've reached the end of a paragraph
        if (i > 0 && lines[i - 1].trim().isNotEmpty) {
          currentParagraphIndex++;
        }
      }
      
      position += line.length + 1; // +1 for newline character
    }
    
    // Fallback: insert at the end
    return originalContent.length;
  }

  /// Format CTA content for insertion into script
  static String _formatCtaForInsertion(String ctaContent) {
    if (ctaContent.trim().isEmpty) return '';
    
    return '\n\n[CTA] $ctaContent\n\n';
  }

  /// Insert text at specific position
  static String _insertAtPosition(String original, String toInsert, int position) {
    if (position <= 0) return toInsert + original;
    if (position >= original.length) return original + toInsert;
    
    return original.substring(0, position) + toInsert + original.substring(position);
  }

  /// Preview CTA positions without actually inserting them
  static List<CtaPreview> previewCtaPositions({
    required String scriptContent,
    required List<CtaItem> ctas,
  }) {
    if (ctas.isEmpty || scriptContent.isEmpty) return [];
    
    final paragraphs = _splitIntoParagraphs(scriptContent);
    final previews = <CtaPreview>[];
    
    for (final cta in ctas) {
      final targetPercentage = _getPositionPercentage(cta, paragraphs.length);
      final targetParagraphIndex = ((paragraphs.length - 1) * targetPercentage / 100).round();
      final safeIndex = targetParagraphIndex.clamp(0, paragraphs.length - 1);
      
      previews.add(CtaPreview(
        cta: cta,
        paragraphIndex: safeIndex,
        positionPercentage: targetPercentage,
        nearbyText: safeIndex < paragraphs.length 
            ? paragraphs[safeIndex].substring(0, 100) + '...'
            : 'Final do roteiro',
      ));
    }
    
    return previews;
  }

  /// Remove all CTAs from script content
  static String removeCtasFromScript(String scriptContent) {
    return scriptContent.replaceAll(RegExp(r'\n\n\[CTA\][^\n]*\n\n'), '\n\n');
  }

  /// Extract CTA markers from script (for editing)
  static List<String> extractCtasFromScript(String scriptContent) {
    final ctaPattern = RegExp(r'\[CTA\]\s*(.+?)(?=\n|\[CTA\]|$)', multiLine: true);
    final matches = ctaPattern.allMatches(scriptContent);
    
    return matches.map((match) => match.group(1)?.trim() ?? '').toList();
  }

  /// Validate CTA positioning to avoid conflicts
  static List<String> validateCtaPositioning(List<CtaItem> ctas) {
    final warnings = <String>[];
    final positions = <double>[];
    
    for (final cta in ctas) {
      final position = _getPositionPercentage(cta, 100); // Use 100 as base for percentage
      
      // Check for overlapping positions (within 10% range)
      for (final existingPosition in positions) {
        if ((position - existingPosition).abs() < 10) {
          warnings.add('CTAs "${cta.title}" podem estar muito próximos (posição ${position.toInt()}%)');
        }
      }
      
      positions.add(position);
    }
    
    // Check for logical order
    if (positions.length > 1) {
      final sortedPositions = List<double>.from(positions)..sort();
      if (!_isListEqual(positions, sortedPositions)) {
        warnings.add('A ordem dos CTAs pode confundir o fluxo do roteiro');
      }
    }
    
    return warnings;
  }

  static bool _isListEqual(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Preview information for CTA positioning
class CtaPreview {
  final CtaItem cta;
  final int paragraphIndex;
  final double positionPercentage;
  final String nearbyText;

  const CtaPreview({
    required this.cta,
    required this.paragraphIndex,
    required this.positionPercentage,
    required this.nearbyText,
  });
}