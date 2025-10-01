import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/workspace_sessions_provider.dart';
import '../../providers/script_generation_multi_provider.dart';
import '../../../core/theme/app_colors.dart';
import 'package:flutter_gerador/core/utils/color_extensions.dart';

class WorkspaceStatusIndicator extends ConsumerWidget {
  final String sessionId;
  
  const WorkspaceStatusIndicator({
    super.key,
    required this.sessionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(workspaceSessionsProvider);
    final generationState = ref.watch(scriptGenerationMultiProvider);
    
    final session = sessionState.sessions.firstWhere(
      (s) => s.id == sessionId,
      orElse: () => throw Exception('Session not found'),
    );
    
    final isGenerating = generationState.isGenerating(sessionId);
    final hasResult = generationState.getResult(sessionId) != null;
    final hasError = generationState.getError(sessionId) != null;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
  color: _getStatusColor(isGenerating, hasResult, hasError).o(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(isGenerating, hasResult, hasError).o(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isGenerating) ...[
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor(isGenerating, hasResult, hasError)),
              ),
            ),
          ] else ...[
            Icon(
              _getStatusIcon(isGenerating, hasResult, hasError),
              size: 12,
              color: _getStatusColor(isGenerating, hasResult, hasError),
            ),
          ],
          const SizedBox(width: 4),
          Text(
            _getStatusText(isGenerating, hasResult, hasError),
            style: TextStyle(
              color: _getStatusColor(isGenerating, hasResult, hasError),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(bool isGenerating, bool hasResult, bool hasError) {
    if (isGenerating) return AppColors.fireOrange;
    if (hasError) return Colors.red;
    if (hasResult) return Colors.green;
    return Colors.grey;
  }

  IconData _getStatusIcon(bool isGenerating, bool hasResult, bool hasError) {
    if (hasError) return Icons.error_outline;
    if (hasResult) return Icons.check_circle_outline;
    return Icons.circle_outlined;
  }

  String _getStatusText(bool isGenerating, bool hasResult, bool hasError) {
    if (isGenerating) return 'Gerando...';
    if (hasError) return 'Erro';
    if (hasResult) return 'Concluído';
    return 'Pronto';
  }
}
