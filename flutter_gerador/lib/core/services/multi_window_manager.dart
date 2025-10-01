import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class MultiWindowManager {
  static final Map<String, bool> _openWindows = {};
  
  static Future<void> openWorkspaceWindow({
    required String workspaceId,
    required String title,
    required Widget content,
  }) async {
    // Verificar se a janela já está aberta
    if (_openWindows[workspaceId] == true) {
      // Se já estiver aberta, apenas focar nela
      await WindowManager.instance.focus();
      return;
    }

    try {
      // Marcar como aberta
      _openWindows[workspaceId] = true;
      
      // Configurar nova janela
      await WindowManager.instance.ensureInitialized();
      
      // Criar nova janela com offset baseado no workspace
      final offset = _getWindowOffset(workspaceId);
      
      final windowOptions = WindowOptions(
        size: const Size(1400, 900),
        minimumSize: const Size(1200, 800),
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.normal,
        title: title,
        center: false,
        alwaysOnTop: false,
      );
      
      // Aplicar configurações da janela
      await WindowManager.instance.waitUntilReadyToShow(windowOptions, () async {
        await WindowManager.instance.show();
        await WindowManager.instance.focus();
        
        // Posicionar janela com offset
        await WindowManager.instance.setPosition(offset);
      });
      
    } catch (e) {
  debugPrint('Erro ao criar nova janela: $e');
      _openWindows[workspaceId] = false;
    }
  }
  
  static Offset _getWindowOffset(String workspaceId) {
    // Calcular posição da janela baseada no ID do workspace
    switch (workspaceId) {
      case '1':
        return const Offset(100, 100);
      case '2':
        return const Offset(200, 150);
      case '3':
        return const Offset(300, 200);
      default:
        return const Offset(150, 125);
    }
  }
  
  static void markWindowClosed(String workspaceId) {
    _openWindows[workspaceId] = false;
  }
  
  static bool isWindowOpen(String workspaceId) {
    return _openWindows[workspaceId] == true;
  }
}

// Widget para janela individual do workspace
class WorkspaceWindow extends StatefulWidget {
  final String workspaceId;
  final String title;
  final Widget content;
  
  const WorkspaceWindow({
    super.key,
    required this.workspaceId,
    required this.title,
    required this.content,
  });
  
  @override
  State<WorkspaceWindow> createState() => _WorkspaceWindowState();
}

class _WorkspaceWindowState extends State<WorkspaceWindow> {
  @override
  void initState() {
    super.initState();
    _setupWindowCallbacks();
  }
  
  void _setupWindowCallbacks() {
    // Listener para quando a janela for fechada
    WindowManager.instance.addListener(AppWindowListener(onClose: () {
      MultiWindowManager.markWindowClosed(widget.workspaceId);
    }));
  }
  
  @override
  void dispose() {
    // Marcar janela como fechada quando o widget for descartado
    MultiWindowManager.markWindowClosed(widget.workspaceId);
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: widget.title,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: _getWorkspaceColor(widget.workspaceId),
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                // Fechar esta janela
                WindowManager.instance.close();
              },
            ),
          ],
        ),
        body: widget.content,
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

// Renomeado para evitar conflito com WindowListener do pacote window_manager
class AppWindowListener extends WindowListener {
  final VoidCallback? onClose;

  AppWindowListener({this.onClose});

  @override
  void onWindowClose() async {
    onClose?.call();
    await windowManager.destroy();
    // Não chama super pois implementação base é vazia
  }
}
