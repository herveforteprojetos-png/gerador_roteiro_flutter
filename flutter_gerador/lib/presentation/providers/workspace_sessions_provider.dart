import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/generation_config.dart';
import '../models/workspace_session.dart';

class WorkspaceSessionsNotifier extends StateNotifier<WorkspaceSessionsState> {
  WorkspaceSessionsNotifier() : super(WorkspaceSessionsState()) {
    _loadSavedSessions();
  }

  // Inicializa se necessário
  void initializeIfNeeded() {
    if (state.sessions.isEmpty) {
      _createDefaultSessions();
    }
  }

  // Carrega sessões salvas
  Future<void> _loadSavedSessions() async {
    // TODO: Implementar carregamento do SharedPreferences
    // Por enquanto, criar sessões padrão
    _createDefaultSessions();
  }

  void _createDefaultSessions() {
    final defaultSessions = [
      WorkspaceSession(
        id: '1',
        name: 'Workspace 1',
        config: GenerationConfig(
          apiKey: '',
          model: 'gemini-2.5-pro',
          title: '',
          context: '',
          measureType: 'palavras',
          quantity: 1000,
          language: 'Português',
          perspective: 'terceira',
          includeCallToAction: false,
        ),
      ),
      WorkspaceSession(
        id: '2',
        name: 'Workspace 2',
        config: GenerationConfig(
          apiKey: '',
          model: 'gemini-2.5-pro',
          title: '',
          context: '',
          measureType: 'palavras',
          quantity: 1000,
          language: 'Português',
          perspective: 'terceira',
          includeCallToAction: false,
        ),
      ),
      WorkspaceSession(
        id: '3',
        name: 'Workspace 3',
        config: GenerationConfig(
          apiKey: '',
          model: 'gemini-2.5-pro',
          title: '',
          context: '',
          measureType: 'palavras',
          quantity: 1000,
          language: 'Português',
          perspective: 'terceira',
          includeCallToAction: false,
        ),
      ),
    ];

    state = state.copyWith(
      sessions: defaultSessions,
      activeSessionId: '1',
    );
  }

  // Adiciona nova sessão
  void addSession() {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final newSession = WorkspaceSession(
      id: newId,
      name: 'Workspace ${state.sessions.length + 1}',
      config: GenerationConfig(
        apiKey: '',
        model: 'gemini-2.5-pro',
        title: '',
        context: '',
        measureType: 'palavras',
        quantity: 1000,
        language: 'Português',
        perspective: 'terceira',
        includeCallToAction: false,
      ),
    );

    state = state.copyWith(
      sessions: [...state.sessions, newSession],
      activeSessionId: newId,
    );
    _saveSessions();
  }

  // Remove sessão
  void removeSession(String sessionId) {
    if (state.sessions.length <= 1) return; // Manter pelo menos uma sessão

    final updatedSessions = state.sessions.where((s) => s.id != sessionId).toList();
    String newActiveId = state.activeSessionId;
    
    if (state.activeSessionId == sessionId) {
      newActiveId = updatedSessions.first.id;
    }

    state = state.copyWith(
      sessions: updatedSessions,
      activeSessionId: newActiveId,
    );
    _saveSessions();
  }

  // Seleciona sessão ativa
  void setActiveSession(String sessionId) {
    state = state.copyWith(activeSessionId: sessionId);
    _saveSessions();
  }

  // Atualiza configuração da sessão
  void updateSessionConfig(String sessionId, GenerationConfig config) {
    final updatedSessions = state.sessions.map((session) {
      if (session.id == sessionId) {
        return session.copyWith(config: config);
      }
      return session;
    }).toList();

    state = state.copyWith(sessions: updatedSessions);
    _saveSessions();
  }

  // Renomeia sessão
  void renameSession(String sessionId, String newName) {
    final updatedSessions = state.sessions.map((session) {
      if (session.id == sessionId) {
        return session.copyWith(name: newName);
      }
      return session;
    }).toList();

    state = state.copyWith(sessions: updatedSessions);
    _saveSessions();
  }

  // Duplica sessão
  void duplicateSession(String sessionId) {
    final originalSession = state.sessions.firstWhere((s) => s.id == sessionId);
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    
    final duplicatedSession = WorkspaceSession(
      id: newId,
      name: '${originalSession.name} (Cópia)',
      config: originalSession.config,
    );

    state = state.copyWith(
      sessions: [...state.sessions, duplicatedSession],
      activeSessionId: newId,
    );
    _saveSessions();
  }

  // Salva sessões
  Future<void> _saveSessions() async {
    // TODO: Implementar salvamento no SharedPreferences
  }

  // Getters úteis
  WorkspaceSession? get activeSession {
    try {
      return state.sessions.firstWhere((s) => s.id == state.activeSessionId);
    } catch (e) {
      return state.sessions.isNotEmpty ? state.sessions.first : null;
    }
  }

  List<WorkspaceSession> get availableSessions => state.sessions;
}

class WorkspaceSessionsState {
  final List<WorkspaceSession> sessions;
  final String activeSessionId;

  WorkspaceSessionsState({
    this.sessions = const [],
    this.activeSessionId = '',
  });

  WorkspaceSessionsState copyWith({
    List<WorkspaceSession>? sessions,
    String? activeSessionId,
  }) {
    return WorkspaceSessionsState(
      sessions: sessions ?? this.sessions,
      activeSessionId: activeSessionId ?? this.activeSessionId,
    );
  }
}

// Provider
final workspaceSessionsProvider = StateNotifierProvider<WorkspaceSessionsNotifier, WorkspaceSessionsState>((ref) {
  return WorkspaceSessionsNotifier();
});
