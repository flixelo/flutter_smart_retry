/// Circuit breaker states.
enum CircuitState {
  /// Circuit is closed, allowing requests.
  closed,
  
  /// Circuit is open, rejecting requests.
  open,
  
  /// Circuit is half-open, testing if service recovered.
  halfOpen,
}

/// Circuit breaker to prevent cascading failures.
/// 
/// Opens circuit after threshold failures, preventing further requests.
/// After timeout, enters half-open state to test recovery.
class CircuitBreaker {
  /// Threshold of consecutive failures before opening circuit.
  final int failureThreshold;

  /// Duration to wait before attempting recovery.
  final Duration resetTimeout;

  /// Maximum number of requests allowed in half-open state.
  final int halfOpenMaxRequests;

  CircuitState _state = CircuitState.closed;
  int _failureCount = 0;
  int _halfOpenRequests = 0;
  DateTime? _openedAt;

  CircuitBreaker({
    this.failureThreshold = 5,
    this.resetTimeout = const Duration(seconds: 60),
    this.halfOpenMaxRequests = 3,
  });

  /// Get current circuit state.
  CircuitState get state => _state;

  /// Get current failure count.
  int get failureCount => _failureCount;

  /// Check if request is allowed through the circuit.
  bool canExecute() {
    _updateState();
    
    switch (_state) {
      case CircuitState.closed:
        return true;
      case CircuitState.open:
        return false;
      case CircuitState.halfOpen:
        if (_halfOpenRequests < halfOpenMaxRequests) {
          _halfOpenRequests++;
          return true;
        }
        return false;
    }
  }

  /// Record successful execution.
  void onSuccess() {
    _failureCount = 0;
    if (_state == CircuitState.halfOpen) {
      _state = CircuitState.closed;
      _halfOpenRequests = 0;
    }
  }

  /// Record failed execution.
  void onFailure() {
    _failureCount++;
    
    if (_state == CircuitState.halfOpen) {
      _openCircuit();
    } else if (_failureCount >= failureThreshold) {
      _openCircuit();
    }
  }

  /// Reset the circuit breaker.
  void reset() {
    _state = CircuitState.closed;
    _failureCount = 0;
    _halfOpenRequests = 0;
    _openedAt = null;
  }

  void _openCircuit() {
    _state = CircuitState.open;
    _openedAt = DateTime.now();
    _halfOpenRequests = 0;
  }

  void _updateState() {
    if (_state == CircuitState.open && _openedAt != null) {
      if (DateTime.now().difference(_openedAt!) >= resetTimeout) {
        _state = CircuitState.halfOpen;
        _halfOpenRequests = 0;
      }
    }
  }
}

/// Exception thrown when circuit breaker is open.
class CircuitBreakerOpenException implements Exception {
  final String message;

  CircuitBreakerOpenException([this.message = 'Circuit breaker is open']);

  @override
  String toString() => 'CircuitBreakerOpenException: $message';
}
