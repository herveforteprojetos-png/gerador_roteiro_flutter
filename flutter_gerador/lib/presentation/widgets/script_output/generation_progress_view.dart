import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/generation_progress.dart';
import '../../../core/theme/app_colors.dart';

class GenerationProgressView extends ConsumerStatefulWidget {
  final GenerationProgress progress;
  final VoidCallback onCancel;

  const GenerationProgressView({
    super.key,
    required this.progress,
    required this.onCancel,
  });

  @override
  ConsumerState<GenerationProgressView> createState() => _GenerationProgressViewState();
}

class _GenerationProgressViewState extends ConsumerState<GenerationProgressView> {
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.darkBackground,
      child: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(32),
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
                
                const SizedBox(height: 20),
                
                // Informações de progresso
                _buildProgressInfo(),
                
                const SizedBox(height: 16),
                
                // Barra horizontal de progresso
                _buildHorizontalProgressBar(),
                
                const SizedBox(height: 20),
                
                // Console detalhado
                _buildDetailedConsole(),
                
                const SizedBox(height: 20),
                
                // Botão cancelar
                _buildCancelButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Informações de progresso detalhadas
  Widget _buildProgressInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.fireOrange.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          // Percentual principal
          Text(
            '${(widget.progress.percentage * 100).toInt()}%',
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 8),
          
          // Informações detalhadas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildInfoCard('Bloco', '${widget.progress.currentBlock}/${widget.progress.totalBlocks}'),
              _buildInfoCard('Fase', widget.progress.currentPhase),
              _buildInfoCard('Palavras', '${widget.progress.wordsGenerated}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: AppColors.fireOrange,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // Barra horizontal de progresso
  Widget _buildHorizontalProgressBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label da barra
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progresso Geral',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(widget.progress.percentage * 100).toInt()}%',
              style: TextStyle(
                color: AppColors.fireOrange,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Barra de progresso
        Container(
          width: double.infinity,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: widget.progress.percentage,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.fireOrange.withValues(alpha: 0.8),
                    AppColors.fireOrange,
                  ],
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Indicadores de bloco
        Row(
          children: [
            for (int i = 1; i <= widget.progress.totalBlocks; i++)
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i < widget.progress.totalBlocks ? 4 : 0),
                  height: 4,
                  decoration: BoxDecoration(
                    color: i <= widget.progress.currentBlock 
                        ? AppColors.fireOrange 
                        : Colors.grey[700],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // Console detalhado mostrando informações específicas
  Widget _buildDetailedConsole() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.fireOrange.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          // Header do console
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7),
                topRight: Radius.circular(7),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.terminal,
                  color: AppColors.fireOrange,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  'Console de Geração',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  'Bloco ${widget.progress.currentBlock}/${widget.progress.totalBlocks}',
                  style: TextStyle(
                    color: AppColors.fireOrange,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // Content do console
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  // Status atual compacto
                  _buildCurrentStatus(),
                  
                  const SizedBox(height: 6),
                  
                  // Logs scrolláveis
                  Expanded(
                    child: _buildScrollableLogs(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStatus() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[900]?.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.fireOrange.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.autorenew,
            color: AppColors.fireOrange,
            size: 12,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '${widget.progress.currentPhase} - Bloco ${widget.progress.currentBlock}/${widget.progress.totalBlocks}',
              style: const TextStyle(
                color: Color(0xFF00FF41),
                fontFamily: 'monospace',
                fontSize: 10,
              ),
            ),
          ),
          Text(
            '${((widget.progress.percentage) * 100).toInt()}%',
            style: TextStyle(
              color: AppColors.fireOrange,
              fontFamily: 'monospace',
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollableLogs() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(4),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _getDetailedLogs().length,
        itemBuilder: (context, index) {
          final log = _getDetailedLogs()[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Text(
              log,
              style: const TextStyle(
                color: Color(0xFF00FF41),
                fontFamily: 'monospace',
                fontSize: 11,
              ),
            ),
          );
        },
      ),
    );
  }

  List<String> _getDetailedLogs() {
    List<String> detailedLogs = [];
    
    // Adicionar logs de sistema
    detailedLogs.add('🚀 Sistema de geração iniciado');
    detailedLogs.add('🔧 Configuração carregada: ${widget.progress.totalBlocks} blocos planejados');
    
    // Adicionar logs baseados no progresso atual
    for (int i = 1; i <= widget.progress.currentBlock; i++) {
      if (i < widget.progress.currentBlock) {
        detailedLogs.add('✅ Bloco $i/${{widget.progress.totalBlocks}} concluído');
      } else {
        detailedLogs.add('⚡ Gerando bloco $i/${widget.progress.totalBlocks}...');
      }
    }
    
    // Adicionar logs originais do progress
    for (String log in widget.progress.logs) {
      detailedLogs.add('📋 $log');
    }
    
    // Adicionar informações de restante
    int remaining = widget.progress.totalBlocks - widget.progress.currentBlock;
    if (remaining > 0) {
      detailedLogs.add('📈 Restam $remaining blocos para conclusão');
    }
    
    return detailedLogs;
  }

  // Botão cancelar simples
  Widget _buildCancelButton() {
    return ElevatedButton(
      onPressed: widget.onCancel,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red[600],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      child: const Text('Cancelar'),
    );
  }
}
