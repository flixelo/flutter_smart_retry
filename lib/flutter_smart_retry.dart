/// Advanced retry logic for Flutter with exponential backoff, jitter,
/// circuit breaker, and custom retry policies.
///
/// ## Features
///
/// - **Multiple retry policies**: Exponential, linear, fixed delay, and custom
/// - **Circuit breaker**: Prevent cascading failures
/// - **Jitter**: Randomized delays to prevent thundering herd
/// - **Flexible configuration**: Callbacks, timeouts, and custom logic
/// - **Zero dependencies**: Pure Dart implementation
///
/// ## Quick Start
///
/// ```dart
/// import 'package:flutter_smart_retry/flutter_smart_retry.dart';
///
/// // Simple retry with exponential backoff
/// final result = await SmartRetry.execute(
///   () => apiCall(),
///   options: RetryOptions(
///     policy: ExponentialBackoffPolicy(
///       maxAttempts: 3,
///       baseDelay: Duration(seconds: 1),
///     ),
///   ),
/// );
/// ```
///
/// ## With Circuit Breaker
///
/// ```dart
/// final circuitBreaker = CircuitBreaker(
///   failureThreshold: 5,
///   resetTimeout: Duration(seconds: 60),
/// );
///
/// final result = await SmartRetry.execute(
///   () => apiCall(),
///   options: RetryOptions(
///     policy: ExponentialBackoffPolicy(),
///     circuitBreaker: circuitBreaker,
///   ),
/// );
/// ```
library flutter_smart_retry;

export 'src/smart_retry.dart';
export 'src/retry_policy.dart';
export 'src/circuit_breaker.dart';
