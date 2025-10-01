import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/generation_progress.dart';
import '../../../core/theme/app_colors.dart';
import 'modern_generation_progress_view.dart';

class GenerationProgressModal extends ConsumerStatefulWidget {
  final GenerationProgress progress;
  final VoidCallback onCancel;

  const GenerationProgressModal({
    super.key,
    required this.progress,
    required this.onCancel,
  });

  @override
  ConsumerState<GenerationProgressModal> createState() => _GenerationProgressModalState();

  static Future<void> show(
    BuildContext context, {
    required GenerationProgress progress,
    required VoidCallback onCancel,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Não permite fechar clicando fora
      builder: (context) => GenerationProgressModal(
        progress: progress,
        onCancel: onCancel,
      ),
    );
  }
}

class _GenerationProgressModalState extends ConsumerState<GenerationProgressModal>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _handleCancel() {
    _fadeController.reverse().then((_) {
      Navigator.of(context).pop();
      widget.onCancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.0,
              colors: [
                AppColors.darkBackground,
                AppColors.darkBackground.withOpacity(0.95),
                Colors.black.withOpacity(0.98),
              ],
            ),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                // Background com efeito de partículas (opcional)
                _buildBackgroundEffect(),
                
                // Conteúdo principal - usando o espaço total disponível
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 1200),
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  child: ModernGenerationProgressView(
                    progress: widget.progress,
                    onCancel: _handleCancel,
                  ),
                ),
                
                // Botão de fechar no canto superior direito
                Positioned(
                  top: 40,
                  right: 40,
                  child: _buildCloseButton(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundEffect() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 2.0,
          colors: [
            AppColors.fireOrange.withOpacity(0.05),
            Colors.transparent,
            Colors.transparent,
          ],
        ),
      ),
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return CustomPaint(
            painter: ParticlesPainter(
              animation: _fadeAnimation,
              color: AppColors.fireOrange.withOpacity(0.1),
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }

  Widget _buildCloseButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.fireOrange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: IconButton(
        onPressed: _handleCancel,
        icon: Icon(
          Icons.close,
          color: Colors.white,
          size: 24,
        ),
        tooltip: 'Cancelar Geração',
      ),
    );
  }

  Widget _buildTitle() {
    return Container(
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Geração de Roteiro em Andamento',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            height: 2,
            width: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.fireOrange,
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Painter para efeito de partículas de fundo
class ParticlesPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  ParticlesPainter({
    required this.animation,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Criar algumas partículas flutuantes
    for (int i = 0; i < 20; i++) {
      final x = (size.width * (i / 20)) + (animation.value * 50);
      final y = (size.height * ((i * 37) % 100 / 100)) + 
                (animation.value * 30 * (i % 3 - 1));
      final radius = 1.0 + (animation.value * 2);
      
      canvas.drawCircle(
        Offset(x % size.width, y % size.height),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
