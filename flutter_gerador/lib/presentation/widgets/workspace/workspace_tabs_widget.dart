import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/workspace_sessions_provider.dart';
import '../../providers/auth_provider.dart';
import 'workspace_status_indicator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_design_system.dart';
import 'package:flutter_gerador/core/utils/color_extensions.dart';

class WorkspaceTabsWidget extends ConsumerStatefulWidget {
  const WorkspaceTabsWidget({super.key});

  @override
  ConsumerState<WorkspaceTabsWidget> createState() => _WorkspaceTabsWidgetState();
}

class _WorkspaceTabsWidgetState extends ConsumerState<WorkspaceTabsWidget> {
  
  @override
  Widget build(BuildContext context) {
    final workspaceState = ref.watch(workspaceSessionsProvider);
    final workspaceNotifier = ref.read(workspaceSessionsProvider.notifier);
    final authState = ref.watch(authProvider);

    if (authState is! AuthenticatedState) {
      return const SizedBox.shrink();
    }

    return Container(
      height: AppDesignSystem.tabHeight,
      decoration: BoxDecoration(
        color: AppColors.darkBackground,
        border: Border(
          bottom: BorderSide(color: AppColors.fireOrange.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          // Logo/Title
          Container(
            padding: AppDesignSystem.paddingHorizontalL,
            child: Row(
              children: [
                Icon(
                  Icons.movie_creation,
                  color: AppColors.fireOrange,
                  size: 20,
                ),
                AppDesignSystem.horizontalSpaceS,
                Text(
                  'Gerador Multi-Workspace',
                  style: AppDesignSystem.headingMedium,
                ),
              ],
            ),
          ),
          
          AppDesignSystem.horizontalSpaceXL,
          
          // Tabs das sessões
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...workspaceState.sessions.map((session) {
                    final isActive = session.id == workspaceState.activeSessionId;
                    
                    return _buildWorkspaceTab(
                      session: session,
                      isActive: isActive,
                      onTap: () => workspaceNotifier.setActiveSession(session.id),
                      onClose: workspaceState.sessions.length > 1 
                        ? () => workspaceNotifier.removeSession(session.id)
                        : null,
                      onRename: () => _showRenameDialog(session.id, session.name),
                      onDuplicate: () => workspaceNotifier.duplicateSession(session.id),
                    );
                  }).toList(),
                  
                  // Botão adicionar nova sessão
                  _buildAddSessionButton(workspaceNotifier),
                ],
              ),
            ),
          ),
          
          // Info da licença
          Container(
            padding: AppDesignSystem.paddingHorizontalL,
            child: _buildLicenseInfo(authState.license),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkspaceTab({
    required session,
    required bool isActive,
    required VoidCallback onTap,
    VoidCallback? onClose,
    required VoidCallback onRename,
    required VoidCallback onDuplicate,
  }) {
    return GestureDetector(
      onTap: onTap,
      onSecondaryTap: () => _showTabContextMenu(session, onRename, onDuplicate, onClose),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: AppDesignSystem.spacingS, horizontal: AppDesignSystem.spacingXS),
        padding: AppDesignSystem.paddingM,
        decoration: BoxDecoration(
          color: isActive 
            ? AppColors.fireOrange 
            : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDesignSystem.borderRadius),
          border: !isActive 
            ? Border.all(color: AppColors.fireOrange.withOpacity(0.3))
            : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Nome da sessão
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Text(
                session.name,
                style: AppDesignSystem.bodySmall.copyWith(
                  color: isActive ? Colors.white : Colors.grey[300],
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            AppDesignSystem.horizontalSpaceS,
            
            // Status indicator
            WorkspaceStatusIndicator(sessionId: session.id),
            
            // Botão fechar (se não for a última aba)
            if (onClose != null) ...[
              AppDesignSystem.horizontalSpaceS,
              GestureDetector(
                onTap: onClose,
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: isActive ? Colors.white : Colors.grey[400],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddSessionButton(WorkspaceSessionsNotifier notifier) {
    return GestureDetector(
      onTap: () => notifier.addSession(),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        padding: AppDesignSystem.paddingM,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppDesignSystem.borderRadius),
          border: Border.all(color: AppColors.fireOrange.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add,
              size: 14,
              color: AppColors.fireOrange,
            ),
            AppDesignSystem.horizontalSpaceXS,
            Text(
              'Novo',
              style: AppDesignSystem.bodySmall.copyWith(
                color: AppColors.fireOrange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLicenseInfo(license) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppDesignSystem.spacingL, vertical: AppDesignSystem.spacingS),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.fireOrange.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person,
            color: AppColors.fireOrange,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            license.clientName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${license.usedGenerations}/${license.maxGenerations == -1 ? "∞" : license.maxGenerations}',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  void _showTabContextMenu(session, VoidCallback onRename, VoidCallback onDuplicate, VoidCallback? onClose) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(100, 100, 100, 100),
      items: [
        PopupMenuItem(
          value: 'rename',
          child: Row(
            children: [
              Icon(Icons.edit, size: 16, color: Colors.grey[300]),
              const SizedBox(width: 8),
              const Text('Renomear'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'duplicate',
          child: Row(
            children: [
              Icon(Icons.copy, size: 16, color: Colors.grey[300]),
              const SizedBox(width: 8),
              const Text('Duplicar'),
            ],
          ),
        ),
        if (onClose != null)
          PopupMenuItem(
            value: 'close',
            child: Row(
              children: [
                Icon(Icons.close, size: 16, color: Colors.red[300]),
                const SizedBox(width: 8),
                Text('Fechar', style: TextStyle(color: Colors.red[300])),
              ],
            ),
          ),
      ],
    ).then((value) {
      switch (value) {
        case 'rename':
          onRename();
          break;
        case 'duplicate':
          onDuplicate();
          break;
        case 'close':
          onClose?.call();
          break;
      }
    });
  }

  void _showRenameDialog(String sessionId, String currentName) {
    final controller = TextEditingController(text: currentName);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkBackground,
        title: const Text('Renomear Workspace', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Nome do workspace',
            hintStyle: TextStyle(color: Colors.grey[600]),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.fireOrange),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.fireOrange),
            ),
          ),
          autofocus: true,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              ref.read(workspaceSessionsProvider.notifier).renameSession(sessionId, value.trim());
              Navigator.of(context).pop();
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref.read(workspaceSessionsProvider.notifier).renameSession(sessionId, controller.text.trim());
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.fireOrange),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}
