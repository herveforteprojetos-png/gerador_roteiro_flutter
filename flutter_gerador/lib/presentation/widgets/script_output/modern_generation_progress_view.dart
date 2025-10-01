import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:math' as math;
import '../../../data/models/generation_progress.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_design_system.dart';

class ModernGenerationProgressView extends ConsumerStatefulWidget {
  final GenerationProgress progress;
  final VoidCallback onCancel;

  const ModernGenerationProgressView({
    super.key,
    required this.progress,
    required this.onCancel,
  });

  @override
  ConsumerState<ModernGenerationProgressView> createState() => _ModernGenerationProgressViewState();
}

class _ModernGenerationProgressViewState extends ConsumerState<ModernGenerationProgressView> 
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.progress.percentage,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _progressController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(ModernGenerationProgressView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress.percentage != widget.progress.percentage) {
      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: widget.progress.percentage,
      ).animate(CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeInOut,
      ));
      _progressController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
              _buildSimpleProgressCircle(),
              
              const SizedBox(height: 40),
              
              // Console simples
              _buildSimpleConsole(),
              
              const SizedBox(height: 30),
              
              // Botão cancelar
              _buildCancelButton(),
            ],
          ),
        ),
      ),
    );
  }

  // Progress circle simples e funcional
  Widget _buildSimpleProgressCircle() {
    return Container(
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
              value: widget.progress.percentage,
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
                '${(widget.progress.percentage * 100).toInt()}%',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Bloco ${widget.progress.currentBlock}/${widget.progress.totalBlocks}',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Console simples mostrando apenas o essencial
  Widget _buildSimpleConsole() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.fireOrange.withOpacity(0.3)),
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
          
          // Content
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: widget.progress.logs.length,
              itemBuilder: (context, index) {
                final log = widget.progress.logs[index];
                return Padding(
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
    );
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
