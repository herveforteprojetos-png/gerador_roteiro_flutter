import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io';

import 'core/theme/app_theme.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/providers/auth_provider.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Parse command line arguments
  String workspaceId = '1';
  String title = 'Workspace 1 - Principal';
  
  // Parse arguments in the format --workspace-id=X --workspace-title=Y
  for (String arg in args) {
    if (arg.startsWith('--workspace-id=')) {
      workspaceId = arg.substring('--workspace-id='.length);
    } else if (arg.startsWith('--workspace-title=')) {
      title = arg.substring('--workspace-title='.length);
    }
  }
  
  // Fallback to positional arguments if needed
  if (args.isNotEmpty && !args[0].startsWith('--')) {
    workspaceId = args[0];
    switch (workspaceId) {
      case '1':
        title = 'Workspace 1 - Principal';
        break;
      case '2':
        title = 'Workspace 2 - Secundário';
        break;
      case '3':
        title = 'Workspace 3 - Auxiliar';
        break;
    }
  }
  
  if (kDebugMode) debugPrint('Iniciando workspace $workspaceId: $title');

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    
    // Offset baseado no workspace
    Offset position;
    switch (workspaceId) {
      case '1':
        position = const Offset(100, 100);
        break;
      case '2':
        position = const Offset(200, 150);
        break;
      case '3':
        position = const Offset(300, 200);
        break;
      default:
        position = const Offset(150, 125);
    }
    
    WindowOptions windowOptions = WindowOptions(
      size: const Size(1400, 900),
      minimumSize: const Size(1200, 800),
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      title: title,
      center: false,
    );
    
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      await windowManager.setPosition(position);
      await windowManager.setAlwaysOnTop(true);
      await Future.delayed(Duration(milliseconds: 100));
      await windowManager.setAlwaysOnTop(false);
    });
  }

  runApp(ProviderScope(child: WorkspaceApp(workspaceId: workspaceId, title: title)));
}

class WorkspaceApp extends ConsumerWidget {
  final String workspaceId;
  final String title;
  
  const WorkspaceApp({super.key, required this.workspaceId, required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Simulate authentication for workspace mode
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).simulateLogin();
    });

    return MaterialApp(
      title: title,
      theme: appTheme,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Icon(Icons.workspace_premium, color: Colors.white),
              SizedBox(width: 8),
              Text(title),
            ],
          ),
          backgroundColor: _getWorkspaceColor(workspaceId),
          actions: [
            IconButton(
              icon: const Icon(Icons.minimize),
              onPressed: () {
                if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
                  windowManager.minimize();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                // Fechar esta janela
                if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
                  windowManager.close();
                }
              },
            ),
          ],
        ),
        body: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: HomePage(),
        ),
      ),
    );
  }
  
  Color _getWorkspaceColor(String workspaceId) {
    switch (workspaceId) {
      case '1':
        return const Color(0xFFFF6B35);
      case '2':
        return Colors.blue;
      case '3':
        return Colors.green;
      default:
        return const Color(0xFFFF6B35);
    }
  }
}
