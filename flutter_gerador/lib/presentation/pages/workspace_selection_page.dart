import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'home_page.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/color_extensions.dart';

class WorkspaceSelectionPage extends ConsumerWidget {
  const WorkspaceSelectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState is! AuthenticatedState) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.darkBackground,
              AppColors.darkBackground.o(0.8),
              Colors.black.o(0.9),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(authState.license),
              
              // Content
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Título
                        Text(
                          'Escolha seu Workspace',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: AppColors.fireOrange.o(0.5),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        Text(
                          'Selecione um dos workspaces para começar a gerar roteiros',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[400],
                            fontWeight: FontWeight.w300,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 48),
                        
                        // Grid de Workspaces
                        Container(
                          constraints: const BoxConstraints(maxWidth: 900),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(
                                child: _buildWorkspaceCard(
                                  context,
                                  ref,
                                  workspaceId: '1',
                                  title: 'Workspace 1',
                                  subtitle: 'Gerador Principal',
                                  icon: Icons.movie_creation,
                                  color: AppColors.fireOrange,
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: _buildWorkspaceCard(
                                  context,
                                  ref,
                                  workspaceId: '2',
                                  title: 'Workspace 2',
                                  subtitle: 'Gerador Secundário',
                                  icon: Icons.video_library,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: _buildWorkspaceCard(
                                  context,
                                  ref,
                                  workspaceId: '3',
                                  title: 'Workspace 3',
                                  subtitle: 'Gerador Auxiliar',
                                  icon: Icons.theaters,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(license) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.fireOrange.o(0.3)),
        ),
      ),
      child: Row(
        children: [
          // Logo
          Icon(
            Icons.movie_creation,
            color: AppColors.fireOrange,
            size: 32,
          ),
          const SizedBox(width: 12),
          Text(
            'Gerador de Roteiros IA',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const Spacer(),
          
          // Info do usuário
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.o(0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.fireOrange.o(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.person,
                  color: AppColors.fireOrange,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  license.clientName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${license.usagesLeft}/${license.maxUsages}',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkspaceCard(
    BuildContext context,
    WidgetRef ref, {
    required String workspaceId,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () => _openWorkspace(context, ref, workspaceId),
      child: Container(
        height: 300,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.o(0.1),
              color.o(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.o(0.3)),
          boxShadow: [
            BoxShadow(
              color: color.o(0.2),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ícone
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      color,
                      color.o(0.7),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.o(0.4),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Título
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              // Subtítulo
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w300,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 24),
              
              // Status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.o(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.o(0.5)),
                ),
                child: Text(
                  'Pronto',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openWorkspace(BuildContext context, WidgetRef ref, String workspaceId) {
    // Navega para a interface completa do gerador
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => HomePage(),
      ),
    );
  }
}
