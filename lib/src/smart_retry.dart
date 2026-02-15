import 'dart:async';
import 'package:flutter/foundation.dart';
import 'retry_policy.dart';
import 'circuit_breaker.dart';

/// Retry options for fine-tuning retry behavior.
class RetryOptions {
  /// Retry policy to use.
  final RetryPolicy policy;

  /// Optional circuit breaker.
  final CircuitBreaker? circuitBreaker;

  /// Called before each retry attempt.
  final void Function(int attempt, Duration delay)? onRetry;

  /// Called when all retries are exhausted.
  final void Function(dynamic error)? onExhausted;

  /// Called on successful execution.
  final void Function()? onSuccess;

  /// Timeout for each attempt.
  final Duration? timeout;

  const RetryOptions({
    required this.policy,
    this.circuitBreaker,
    this.onRetry,
    this.onExhausted,
    this.onSuccess,
    this.timeout,
  });
}

/// Main retry executor.
class SmartRetry {
  /// Execute a function with retry logic.
  /// 
  /// Example:
  /// ```dart
  /// final result = await SmartRetry.execute(
  ///   () => apiCall(),
  ///   options: RetryOptions(
  ///     policy: ExponentialBackoffPolicy(maxAttempts: 3),
  ///   ),
  /// );
  /// ```
  static Future<T> execute<T>(
    Future<T> Function() action, {
    required RetryOptions options,
  }) async {
    int attempt = 0;

    while (true) {
      // Check circuit breaker
      if (options.circuitBreaker != null) {
        if (!options.circuitBreaker!.canExecute()) {
          throw CircuitBreakerOpenException();
        }
      }

      try {
        // Execute with optional timeout
        final result = options.timeout != null
            ? await action().timeout(options.timeout!)
            : await action();

        // Success!
        options.circuitBreaker?.onSuccess();
        options.onSuccess?.call();
        return result;
      } catch (error) {
        
        attempt++;

        debugPrint('SmartRetry: Attempt $attempt failed - $error');

        // Check if should retry
        if (!options.policy.shouldRetry(error, attempt)) {
          options.circuitBreaker?.onFailure();
          options.onExhausted?.call(error);
          rethrow;
        }

        // Calculate delay
        final delay = options.policy.calculateDelay(attempt);
        
        debugPrint('SmartRetry: Retrying in ${delay.inMilliseconds}ms');
        
        options.onRetry?.call(attempt, delay);

        // Wait before retry
        await Future.delayed(delay);
      }
    }
  }

  /// Execute a synchronous function with retry logic.
  static T executeSync<T>(
    T Function() action, {
    required RetryOptions options,
  }) {
    int attempt = 0;

    while (true) {
      // Check circuit breaker
      if (options.circuitBreaker != null) {
        if (!options.circuitBreaker!.canExecute()) {
          throw CircuitBreakerOpenException();
        }
      }

      try {
        final result = action();
        
        // Success!
        options.circuitBreaker?.onSuccess();
        options.onSuccess?.call();
        return result;
      } catch (error) {
        
        attempt++;

        debugPrint('SmartRetry: Attempt $attempt failed - $error');

        // Check if should retry
        if (!options.policy.shouldRetry(error, attempt)) {
          options.circuitBreaker?.onFailure();
          options.onExhausted?.call(error);
          rethrow;
        }

        // Calculate delay
        final delay = options.policy.calculateDelay(attempt);
        
        debugPrint('SmartRetry: Retrying in ${delay.inMilliseconds}ms');
        
        options.onRetry?.call(attempt, delay);

        // Wait before retry (blocking)
        sleep(delay);
      }
    }
  }

  /// Helper to create a retryable function.
  /// 
  /// Example:
  /// ```dart
  /// final retryableApiCall = SmartRetry.retryable(
  ///   () => apiCall(),
  ///   options: RetryOptions(
  ///     policy: ExponentialBackoffPolicy(),
  ///   ),
  /// );
  /// 
  /// final result = await retryableApiCall();
  /// ```
  static Future<T> Function() retryable<T>(
    Future<T> Function() action, {
    required RetryOptions options,
  }) {
    return () => execute(action, options: options);
  }
}

/// Helper function to sleep synchronously.
void sleep(Duration duration) {
  final end = DateTime.now().add(duration);
  while (DateTime.now().isBefore(end)) {
    // Busy wait
  }
}
