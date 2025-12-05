import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/generation_progress.dart';
import '../../../core/theme/app_colors.dart';

class ModernGenerationProgressView extends ConsumerWidget {
  final GenerationProgress progress;
  final VoidCallback onCancel;

  const ModernGenerationProgressView({
    super.key,
    required this.progress,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🚀 OTIMIZAÇÃO CRÍTICA: StatelessWidget é MUITO mais leve que StatefulWidget
    // Sem estado = sem lifecycle = sem rebuilds desnecessários
    // 🚀 OTIMIZAÇÃO CRÍTICA: RepaintBoundary isola rebuilds
    // Evita que toda a árvore seja repintada a cada atualização
    return RepaintBoundary(
      child: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Título simples
                Text(
                  'Gerando Roteiro',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // Progress circle simples
                RepaintBoundary(child: _buildSimpleProgressCircle()),

                const SizedBox(height: 40),

                // Console simples
                RepaintBoundary(child: _buildSimpleConsole()),

                const SizedBox(height: 30),

                // Botão cancelar
                _buildCancelButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Progress circle simples e funcional
  Widget _buildSimpleProgressCircle() {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[900],
              border: Border.all(color: Colors.grey[700]!, width: 2),
            ),
          ),

          // Progress indicator
          SizedBox(
            width: 100,
            height: 100,
            child: CircularProgressIndicator(
              value: progress.percentage,
              strokeWidth: 4,
              backgroundColor: Colors.grey[800],
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.fireOrange),
              strokeCap: StrokeCap.round,
            ),
          ),

          // Center content
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(progress.percentage * 100).toInt()}%',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Bloco ${progress.currentBlock}/${progress.totalBlocks}',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Console simples mostrando apenas o essencial
  Widget _buildSimpleConsole() {
    // 🚀 OTIMIZAÇÃO CRÍTICA: Limitar logs para últimos 3 (evita sobrecarga TOTAL!)
    // ANTES: 20 logs = travamentos e cursor mudando para ↔️
    // DEPOIS: 3 logs = UI super leve e responsiva
    final displayLogs = progress.logs.length > 3
        ? progress.logs.sublist(progress.logs.length - 3)
        : progress.logs;

    return RepaintBoundary(
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.fireOrange.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            // Header simples
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(7),
                  topRight: Radius.circular(7),
                ),
              ),
              child: Text(
                'Console de Geração',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // Content - OTIMIZADO com addAutomaticKeepAlives
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                // 🚀 OTIMIZAÇÃO: Usar apenas últimos 20 logs
                itemCount: displayLogs.length,
                // 🚀 OTIMIZAÇÃO CRÍTICA: Cache de widgets
                addAutomaticKeepAlives: true,
                addRepaintBoundaries: true,
                // 🚀 OTIMIZAÇÃO: Keys únicas para evitar rebuild
                itemBuilder: (context, index) {
                  final log = displayLogs[index];
                  return Padding(
                    key: ValueKey(
                      'log_${progress.logs.length - displayLogs.length + index}',
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 1),
                    child: Text(
                      '> $log',
                      style: const TextStyle(
                        color: Color(0xFF00FF41),
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Botão cancelar simples
  Widget _buildCancelButton() {
    return ElevatedButton(
      onPressed: onCancel,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red[600],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      child: const Text('Cancelar'),
    );
  }
}
