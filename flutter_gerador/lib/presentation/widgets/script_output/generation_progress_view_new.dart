import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/generation_progress.dart';
import '../../../core/theme/app_colors.dart';
import 'package:flutter_gerador/core/utils/color_extensions.dart';

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

class _GenerationProgressViewState extends ConsumerState<GenerationProgressView> 
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.progress.percentage,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void didUpdateWidget(GenerationProgressView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress.percentage != widget.progress.percentage) {
      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: widget.progress.percentage,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ));
      _animationController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildProgressView();
  }

  Widget _buildProgressView() {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildTerminalHeader(),
            const SizedBox(height: 16),
            _buildProgressBar(),
            const SizedBox(height: 24),
            _buildMetricsCards(),
            const SizedBox(height: 24),
            _buildPhaseIndicator(),
            const SizedBox(height: 24),
            _buildTerminalConsole(),
            const SizedBox(height: 24),
            _buildCancelButton(),
          ],
        );
      },
    );
  }

  Widget _buildTerminalHeader() {
    return Container(
      width: 600,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
        border: Border.all(color: AppColors.fireOrange),
      ),
      child: Row(
        children: [
          // Terminal window buttons
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: Colors.yellow,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Gerador de Roteiros - Terminal Avançado',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      width: 600,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progresso Geral',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _progressAnimation.value,
              minHeight: 8,
              backgroundColor: Colors.grey[800],
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.fireOrange),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(_progressAnimation.value * 100).toInt()}% Concluído',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsCards() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildMetricCard(
          'Blocos Gerados',
          '${widget.progress.currentBlock}/${widget.progress.totalBlocks}',
          Icons.build,
        ),
        const SizedBox(width: 16),
        _buildMetricCard(
          'Palavras',
          '${widget.progress.wordsGenerated}',
          Icons.text_fields,
        ),
        const SizedBox(width: 16),
        _buildMetricCard(
          'Fase Atual',
          widget.progress.currentPhase,
          Icons.timeline,
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon) {
    return Container(
      width: 140, // Aumentado de 120 para 140
      height: 110,
      padding: const EdgeInsets.all(12), // Reduzido de 16 para 12 para mais espaço
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
  border: Border.all(color: AppColors.fireOrange.o(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: AppColors.fireOrange,
            size: 24,
          ),
          const SizedBox(height: 6), // Reduzido de 8 para 6
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 11, // Reduzido de 12 para 11 para caber melhor
            ),
            textAlign: TextAlign.center,
            maxLines: 2, // Aumentado de 1 para 2 linhas
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseIndicator() {
    return Container(
      width: 600,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
  border: Border.all(color: AppColors.fireOrange.o(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fases Narrativas',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _buildPhaseSteps(),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPhaseSteps() {
    final phases = [
      'Preparação',
      'Introdução',
      'Desenvolvimento',
      'Clímax',
      'Resolução',
      'Finalização',
    ];

    return phases.asMap().entries.map((entry) {
      final index = entry.key;
      final phase = entry.value;
      final isActive = index <= widget.progress.phaseIndex;
      final isCurrent = index == widget.progress.phaseIndex;

      return Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isActive ? AppColors.fireOrange : Colors.grey[600],
              shape: BoxShape.circle,
              border: isCurrent
                  ? Border.all(color: Colors.white, width: 2)
                  : null,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 60,
            child: Text(
              phase,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[500],
                fontSize: 10,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }).toList();
  }

  Widget _buildTerminalConsole() {
    return Container(
      width: 600,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.fireOrange),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
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
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: widget.progress.logs.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    widget.progress.logs[index],
                    style: TextStyle(
                      color: Color(0xFF00FF41),
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelButton() {
    return OutlinedButton(
      onPressed: widget.onCancel,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.red),
        foregroundColor: Colors.red,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      ),
      child: Text(
        'Cancelar Geração',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
