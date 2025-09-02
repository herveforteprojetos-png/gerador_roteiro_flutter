
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = WindowOptions(
      size: const Size(1400, 900),
      minimumSize: const Size(1200, 800),
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      title: AppStrings.appTitle,
    );
    await windowManager.waitUntilReadyToShow(windowOptions);
  }

  runApp(const ProviderScope(child: MyApp()));
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appTitle,
      theme: appTheme,
      debugShowCheckedModeBanner: false,
      home: Builder(
        builder: (context) => Shortcuts(
          shortcuts: <LogicalKeySet, Intent>{
            LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS): const SaveScriptIntent(),
            LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN): const NewScriptIntent(),
            LogicalKeySet(LogicalKeyboardKey.f5): const GenerateScriptIntent(),
          },
          child: Actions(
            actions: <Type, Action<Intent>>{
              SaveScriptIntent: CallbackAction<SaveScriptIntent>(onInvoke: (intent) {
                // Salva roteiro atual
                final container = ProviderScope.containerOf(context);
                final state = container.read(scriptGenerationProvider);
                final text = state.result?.scriptText ?? '';
                if (text.isNotEmpty) {
                  // Salva como TXT
                  // ...existing code...
                }
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Roteiro salvo!')));
                return null;
              }),
              NewScriptIntent: CallbackAction<NewScriptIntent>(onInvoke: (intent) {
                // Limpa campos e estado
                final container = ProviderScope.containerOf(context);
                container.read(scriptGenerationProvider.notifier).state = ScriptGenerationState();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Novo roteiro iniciado!')));
                return null;
              }),
              GenerateScriptIntent: CallbackAction<GenerateScriptIntent>(onInvoke: (intent) {
                // Dispara geração usando config atual
                final container = ProviderScope.containerOf(context);
                final config = container.read(scriptConfigProvider);
                container.read(scriptGenerationProvider.notifier).generateScript(config);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Geração iniciada!')));
                return null;
              }),
            },
            child: const HomePage(),
          ),
        ),
      ),
    );
  }
}

class SaveScriptIntent extends Intent {
  const SaveScriptIntent();
}
class NewScriptIntent extends Intent {
  const NewScriptIntent();
}
class GenerateScriptIntent extends Intent {
  const GenerateScriptIntent();
}
