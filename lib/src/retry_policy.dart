/// Retry policy that defines how retries should be executed.
abstract class RetryPolicy {
  /// Maximum number of retry attempts.
  final int maxAttempts;

  /// Base delay between retries in milliseconds.
  final Duration baseDelay;

  /// Maximum delay between retries in milliseconds.
  final Duration maxDelay;

  /// Whether to add jitter to delays.
  final bool useJitter;

  const RetryPolicy({
    required this.maxAttempts,
    required this.baseDelay,
    required this.maxDelay,
    this.useJitter = true,
  });

  /// Calculate delay for the given attempt number.
  Duration calculateDelay(int attempt);

  /// Check if the error is retryable.
  bool shouldRetry(dynamic error, int attempt);
}

/// Exponential backoff retry policy.
/// 
/// Delays increase exponentially: baseDelay * (2 ^ attempt)
/// Example: 1s, 2s, 4s, 8s, 16s...
class ExponentialBackoffPolicy extends RetryPolicy {
  /// Multiplier for exponential growth (default: 2).
  final double multiplier;

  const ExponentialBackoffPolicy({
    super.maxAttempts = 3,
    super.baseDelay = const Duration(seconds: 1),
    super.maxDelay = const Duration(seconds: 30),
    super.useJitter = true,
    this.multiplier = 2.0,
  });

  @override
  Duration calculateDelay(int attempt) {
    final delay = baseDelay.inMilliseconds * 
        (multiplier * attempt).toInt();
    
    var finalDelay = Duration(
      milliseconds: delay.clamp(
        baseDelay.inMilliseconds,
        maxDelay.inMilliseconds,
      ),
    );

    if (useJitter) {
      finalDelay = _addJitter(finalDelay);
    }

    return finalDelay;
  }

  @override
  bool shouldRetry(dynamic error, int attempt) {
    return attempt < maxAttempts;
  }

  Duration _addJitter(Duration delay) {
    final jitter = (delay.inMilliseconds * 0.1 * 
        (DateTime.now().millisecondsSinceEpoch % 100) / 100).round();
    return Duration(milliseconds: delay.inMilliseconds + jitter);
  }
}

/// Linear backoff retry policy.
/// 
/// Delays increase linearly: baseDelay * attempt
/// Example: 1s, 2s, 3s, 4s, 5s...
class LinearBackoffPolicy extends RetryPolicy {
  const LinearBackoffPolicy({
    super.maxAttempts = 3,
    super.baseDelay = const Duration(seconds: 1),
    super.maxDelay = const Duration(seconds: 30),
    super.useJitter = true,
  });

  @override
  Duration calculateDelay(int attempt) {
    final delay = baseDelay.inMilliseconds * attempt;
    
    var finalDelay = Duration(
      milliseconds: delay.clamp(
        baseDelay.inMilliseconds,
        maxDelay.inMilliseconds,
      ),
    );

    if (useJitter) {
      finalDelay = _addJitter(finalDelay);
    }

    return finalDelay;
  }

  @override
  bool shouldRetry(dynamic error, int attempt) {
    return attempt < maxAttempts;
  }

  Duration _addJitter(Duration delay) {
    final jitter = (delay.inMilliseconds * 0.1 * 
        (DateTime.now().millisecondsSinceEpoch % 100) / 100).round();
    return Duration(milliseconds: delay.inMilliseconds + jitter);
  }
}

/// Fixed delay retry policy.
/// 
/// Always uses the same delay between retries.
class FixedDelayPolicy extends RetryPolicy {
  const FixedDelayPolicy({
    super.maxAttempts = 3,
    super.baseDelay = const Duration(seconds: 1),
    super.maxDelay = const Duration(seconds: 1),
    super.useJitter = false,
  });

  @override
  Duration calculateDelay(int attempt) {
    return baseDelay;
  }

  @override
  bool shouldRetry(dynamic error, int attempt) {
    return attempt < maxAttempts;
  }
}

/// Custom retry policy with user-defined logic.
class CustomRetryPolicy extends RetryPolicy {
  /// Custom function to calculate delay.
  final Duration Function(int attempt) delayCalculator;

  /// Custom function to determine if retry should happen.
  final bool Function(dynamic error, int attempt)? retryChecker;

  const CustomRetryPolicy({
    required this.delayCalculator,
    this.retryChecker,
    super.maxAttempts = 3,
    super.baseDelay = const Duration(seconds: 1),
    super.maxDelay = const Duration(seconds: 30),
    super.useJitter = false,
  });

  @override
  Duration calculateDelay(int attempt) {
    return delayCalculator(attempt);
  }

  @override
  bool shouldRetry(dynamic error, int attempt) {
    if (retryChecker != null) {
      return retryChecker!(error, attempt);
    }
    return attempt < maxAttempts;
  }
}
