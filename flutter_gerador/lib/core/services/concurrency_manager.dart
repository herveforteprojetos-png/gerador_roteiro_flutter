import 'dart:async';
import 'package:flutter/foundation.dart';

/// Gerenciador de concorrência para controlar operações simultâneas
class ConcurrencyManager {
  static final ConcurrencyManager _instance = ConcurrencyManager._internal();
  factory ConcurrencyManager() => _instance;
  ConcurrencyManager._internal();

  // Semáforo para controlar máximo de operações simultâneas
  static const int _maxConcurrentOperations = 1; // Começar com 1 para testar
  int _currentOperations = 0;
  final List<Completer<void>> _waitingQueue = []; // Mantido caso futuro aumento de concorrência
  
  // Rastreamento de operações ativas
  final Map<String, DateTime> _activeOperations = {};

  /// Adquire permissão para executar uma operação
  Future<bool> acquire(String operationId) async {
    if (kDebugMode) {
      debugPrint('[ConcurrencyManager] $operationId requesting permission. Current: $_currentOperations/$_maxConcurrentOperations');
    }
    
    if (_currentOperations < _maxConcurrentOperations) {
      _currentOperations++;
      _activeOperations[operationId] = DateTime.now();
      if (kDebugMode) debugPrint('[ConcurrencyManager] $operationId acquired permission immediately');
      return true;
    }
    
    // Se já no máximo, retorna false em vez de esperar para evitar deadlock
    if (kDebugMode) debugPrint('[ConcurrencyManager] $operationId permission denied - at capacity');
    return false;
  }

  /// Libera uma operação
  void release(String operationId) {
  if (kDebugMode) debugPrint('[ConcurrencyManager] $operationId releasing permission');
    
    if (_currentOperations > 0) {
      _currentOperations--;
      _activeOperations.remove(operationId);
    }
    
  if (kDebugMode) debugPrint('[ConcurrencyManager] Current operations: $_currentOperations');
  }

  /// Força a liberação de uma operação específica
  void forceRelease(String operationId) {
  if (kDebugMode) debugPrint('[ConcurrencyManager] Force releasing $operationId');
    _activeOperations.remove(operationId);
    if (_currentOperations > 0) {
      _currentOperations--;
    }
    
    // Liberar próximo da fila se existir
    if (_waitingQueue.isNotEmpty) {
      final nextCompleter = _waitingQueue.removeAt(0);
      nextCompleter.complete();
    }
  }

  /// Obtém status atual do gerenciador
  Map<String, dynamic> getStatus() {
    return {
      'currentOperations': _currentOperations,
      'maxOperations': _maxConcurrentOperations,
      'queueSize': _waitingQueue.length,
      'activeOperations': _activeOperations.map((key, value) => MapEntry(
        key, 
        DateTime.now().difference(value).inSeconds,
      )),
    };
  }

  /// Limpa todas as operações (emergência)
  void clearAll() {
  if (kDebugMode) debugPrint('[ConcurrencyManager] EMERGENCY CLEAR - clearing all operations');
    _currentOperations = 0;
    _activeOperations.clear();
    
    // Cancelar todas as operações na fila
    while (_waitingQueue.isNotEmpty) {
      final completer = _waitingQueue.removeAt(0);
      completer.completeError('Emergency clear');
    }
  }
}
