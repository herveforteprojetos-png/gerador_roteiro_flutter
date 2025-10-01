import 'package:flutter/material.dart';
import '../../core/utils/color_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/workspace_config_provider.dart';
import '../widgets/workspace/workspace_config_dialog.dart';
import '../../data/models/workspace_config.dart';
import 'login_page.dart';
import 'home_page.dart';
import 'dart:io';
import 'dart:convert';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  // Store workspace processes for cleanup
  static final Map<String, Process> _workspaceProcesses = {};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    
    if (authState is LoadingState) {
      return Scaffold(
        backgroundColor: Color(0xFF1a1a1a),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFF6B35),
          ),
        ),
      );
    } 
    
    if (authState is AuthenticatedState) {
      return Scaffold(
        backgroundColor: Color(0xFF1a1a1a),
        appBar: AppBar(
          title: Text('Escolha seu Workspace'),
          backgroundColor: Color(0xFFFF6B35),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Selecione um Workspace:',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
              SizedBox(height: 20),
              Text(
                'Modo Overlay (Recomendado):',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              SizedBox(height: 20),
              // Workspace Buttons - Dynamic based on configs
              Consumer(
                builder: (context, ref, child) {
                  final configsAsync = ref.watch(allWorkspaceConfigsProvider);
                  
                  return configsAsync.when(
                    loading: () => const CircularProgressIndicator(),
                    error: (error, stack) => Text('Erro ao carregar workspaces: $error'),
                    data: (configs) {
                      return Column(
                        children: [
                          // Workspace 1
                          _buildWorkspaceButton(
                            context: context,
                            ref: ref,
                            workspaceId: '1',
                            workspaceConfig: configs['1']!,
                            color: const Color(0xFFFF6B35),
                            isOverlay: true,
                          ),
                          const SizedBox(height: 10),
                          // Workspace 2
                          _buildWorkspaceButton(
                            context: context,
                            ref: ref,
                            workspaceId: '2',
                            workspaceConfig: configs['2']!,
                            color: Colors.blue,
                            isOverlay: true,
                          ),
                          const SizedBox(height: 10),
                          // Workspace 3
                          _buildWorkspaceButton(
                            context: context,
                            ref: ref,
                            workspaceId: '3',
                            workspaceConfig: configs['3']!,
                            color: Colors.green,
                            isOverlay: true,
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              SizedBox(height: 30),
              Text(
                'Modo Nova Janela (Experimental):',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              SizedBox(height: 10),
              // New Window Workspace Buttons
              Consumer(
                builder: (context, ref, child) {
                  final configsAsync = ref.watch(allWorkspaceConfigsProvider);
                  
                  return configsAsync.when(
                    loading: () => const CircularProgressIndicator(),
                    error: (error, stack) => Text('Erro: $error'),
                    data: (configs) {
                      // Definir cores localmente para evitar conflitos
                      const orangeColor = Color(0xFFFF6B35);
                      const blueColor = Colors.blue;
                      const greenColor = Colors.green;
                      
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // W1 Button
                          _buildNewWindowButton(
                            workspaceId: '1',
                            workspaceConfig: configs['1']!,
                            buttonColor: orangeColor,
                          ),
                          const SizedBox(width: 10),
                          // W2 Button
                          _buildNewWindowButton(
                            workspaceId: '2',
                            workspaceConfig: configs['2']!,
                            buttonColor: blueColor,
                          ),
                          const SizedBox(width: 10),
                          // W3 Button
                          _buildNewWindowButton(
                            workspaceId: '3',
                            workspaceConfig: configs['3']!,
                            buttonColor: greenColor,
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      );
    }
    
    return LoginPage();
  }

  void _openWorkspaceInNewWindow(String workspaceId, String title) async {
    try {
      print('Abrindo workspace $workspaceId em nova janela...');
      
      // Get the current directory (should be the project root)
      String currentDir = Directory.current.path;
      
      // Try both Debug and Release paths with absolute paths
      String debugPath = '$currentDir\\build\\windows\\x64\\runner\\Debug\\flutter_gerador.exe';
      String releasePath = '$currentDir\\build\\windows\\x64\\runner\\Release\\flutter_gerador.exe';
      
      String executablePath;
      if (File(debugPath).existsSync()) {
        executablePath = debugPath;
        print('Found Debug executable: $executablePath');
      } else if (File(releasePath).existsSync()) {
        executablePath = releasePath;
        print('Found Release executable: $executablePath');
      } else {
        print('Debug path checked: $debugPath - exists: ${File(debugPath).existsSync()}');
        print('Release path checked: $releasePath - exists: ${File(releasePath).existsSync()}');
        throw Exception('Executable not found in Debug or Release folders');
      }
      
      // Arguments to pass to the new process
      List<String> arguments = [
        '--workspace-mode',
        '--workspace-id=$workspaceId',
        '--workspace-title=$title'
      ];
      
      // Start the new process
      Process.start(
        executablePath,
        arguments,
        workingDirectory: Directory.current.path,
      ).then((process) {
        print('Workspace $workspaceId aberto em processo ${process.pid}');
        
        // Store the process reference for potential cleanup
        _workspaceProcesses[workspaceId] = process;
        
        // Listen to process exit
        process.exitCode.then((exitCode) {
          print('Workspace $workspaceId fechado com código $exitCode');
          _workspaceProcesses.remove(workspaceId);
        });
      }).catchError((error) {
        print('Erro ao abrir workspace $workspaceId: $error');
        
        // Fallback: Try with dart run if executable not found
        _openWorkspaceWithDart(workspaceId, title);
      });
      
    } catch (e) {
      print('Erro ao abrir workspace: $e');
      // Fallback to dart run
      _openWorkspaceWithDart(workspaceId, title);
    }
  }

  void _openWorkspaceWithDart(String workspaceId, String title) async {
    try {
      print('Tentando abrir workspace via dart run...');
      
      List<String> arguments = [
        'run',
        'lib/main_workspace.dart',
        '--workspace-id=$workspaceId',
        '--workspace-title=$title'
      ];
      
      print('Executando: dart ${arguments.join(' ')}');
      print('Working directory: ${Directory.current.path}');
      
      // Try using flutter dart instead of just dart
      Process.start(
        'flutter',
        ['dart', ...arguments],
        workingDirectory: Directory.current.path,
      ).then((process) {
        print('Workspace $workspaceId aberto via flutter dart em processo ${process.pid}');
        
        _workspaceProcesses[workspaceId] = process;
        
        // Listen to stdout and stderr
        process.stdout.transform(utf8.decoder).listen((data) {
          print('Workspace $workspaceId stdout: $data');
        });
        
        process.stderr.transform(utf8.decoder).listen((data) {
          print('Workspace $workspaceId stderr: $data');
        });
        
        process.exitCode.then((exitCode) {
          print('Workspace $workspaceId (flutter dart) fechado com código $exitCode');
          _workspaceProcesses.remove(workspaceId);
        });
      }).catchError((error) {
        print('Erro ao executar flutter dart: $error');
        // Last fallback: just log the error
        print('Fallback para overlay não disponível neste contexto');
      });
    } catch (e) {
      print('Erro ao abrir workspace via flutter dart: $e');
    }
  }

  void _openWorkspaceInOverlay(BuildContext context, String workspaceId, String title) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog.fullscreen(
          child: Scaffold(
            appBar: AppBar(
              title: Text(title),
              backgroundColor: Color(0xFFFF6B35),
              leading: IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
              ),
            ),
            body: HomePage(),
          ),
        );
      },
    );
  }

  // Helper method to build workspace buttons with config support
  Widget _buildWorkspaceButton({
    required BuildContext context,
    required WidgetRef ref,
    required String workspaceId,
    required WorkspaceConfig workspaceConfig,
    required Color color,
    required bool isOverlay,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              if (isOverlay) {
                _openWorkspaceInOverlay(context, workspaceId, workspaceConfig.workspaceName);
              } else {
                _openWorkspaceInNewWindow(workspaceId, workspaceConfig.workspaceName);
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.workspace_premium, color: Colors.white),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    workspaceConfig.workspaceName,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              minimumSize: const Size(200, 50),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () async {
            await _showConfigDialog(context, workspaceId);
            // Recarrega as configurações após fechar o dialog
            ref.invalidate(allWorkspaceConfigsProvider);
          },
          icon: const Icon(Icons.settings),
          tooltip: 'Configurar Workspace',
          style: IconButton.styleFrom(
            backgroundColor: color.o(0.2),
            foregroundColor: color,
          ),
        ),
      ],
    );
  }

  // Helper method to build new window buttons
  Widget _buildNewWindowButton({
    required String workspaceId,
    required WorkspaceConfig workspaceConfig,
    required Color buttonColor,
  }) {
    return Tooltip(
      message: workspaceConfig.workspaceName,
      child: ElevatedButton(
        onPressed: () {
          _openWorkspaceInNewWindow(workspaceId, workspaceConfig.workspaceName);
        },
        child: Text('W$workspaceId'),
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor.o(0.7),
          minimumSize: const Size(60, 40),
        ),
      ),
    );
  }

  // Show configuration dialog
  Future<void> _showConfigDialog(BuildContext context, String workspaceId) async {
    await showDialog(
      context: context,
      builder: (context) => WorkspaceConfigDialog(workspaceId: workspaceId),
    );
  }
}
