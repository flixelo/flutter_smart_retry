# flutter_smart_retry

Advanced retry logic for Flutter with exponential backoff, jitter, circuit breaker, and custom retry policies.

[![pub package](https://img.shields.io/pub/v/flutter_smart_retry.svg)](https://pub.dev/packages/flutter_smart_retry)

## Features

- 🔄 **Multiple Retry Policies**
  - Exponential backoff
  - Linear backoff
  - Fixed delay
  - Custom policies

- 🔌 **Circuit Breaker Pattern**
  - Prevent cascading failures
  - Automatic recovery testing
  - Configurable thresholds

- 🎲 **Jitter Support**
  - Randomized delays
  - Prevent thundering herd problem

- ⚙️ **Flexible Configuration**
  - Custom callbacks
  - Per-attempt timeouts
  - Error filtering

- 🪶 **Zero Dependencies**
  - Pure Dart implementation
  - Lightweight and fast

## Installation

```yaml
dependencies:
  flutter_smart_retry: ^1.0.0
```

Then run:

```bash
flutter pub get
```

## Quick Start

### Basic Retry

```dart
import 'package:flutter_smart_retry/flutter_smart_retry.dart';

final result = await SmartRetry.execute(
  () => apiCall(),
  options: RetryOptions(
    policy: ExponentialBackoffPolicy(
      maxAttempts: 3,
      baseDelay: Duration(seconds: 1),
    ),
  ),
);
```

### With Circuit Breaker

```dart
final circuitBreaker = CircuitBreaker(
  failureThreshold: 5,
  resetTimeout: Duration(seconds: 60),
);

final result = await SmartRetry.execute(
  () => apiCall(),
  options: RetryOptions(
    policy: ExponentialBackoffPolicy(),
    circuitBreaker: circuitBreaker,
    onRetry: (attempt, delay) {
      print('Retry attempt $attempt after ${delay.inSeconds}s');
    },
  ),
);
```

### Linear Backoff

```dart
final result = await SmartRetry.execute(
  () => apiCall(),
  options: RetryOptions(
    policy: LinearBackoffPolicy(
      maxAttempts: 5,
      baseDelay: Duration(seconds: 2),
      maxDelay: Duration(seconds: 10),
    ),
  ),
);
```

### Fixed Delay

```dart
final result = await SmartRetry.execute(
  () => apiCall(),
  options: RetryOptions(
    policy: FixedDelayPolicy(
      maxAttempts: 3,
      baseDelay: Duration(seconds: 3),
    ),
  ),
);
```

### Custom Retry Policy

```dart
final result = await SmartRetry.execute(
  () => apiCall(),
  options: RetryOptions(
    policy: CustomRetryPolicy(
      maxAttempts: 5,
      delayCalculator: (attempt) {
        // Custom delay logic
        return Duration(seconds: attempt * 2);
      },
      retryChecker: (error, attempt) {
        // Only retry on specific errors
        if (error is SocketException) return true;
        if (error is TimeoutException) return true;
        return false;
      },
    ),
  ),
);
```

### With Callbacks

```dart
final result = await SmartRetry.execute(
  () => apiCall(),
  options: RetryOptions(
    policy: ExponentialBackoffPolicy(maxAttempts: 3),
    onRetry: (attempt, delay) {
      print('Retrying... Attempt: $attempt, Delay: ${delay.inSeconds}s');
    },
    onSuccess: () {
      print('Success!');
    },
    onExhausted: (error) {
      print('All retries exhausted. Last error: $error');
    },
    timeout: Duration(seconds: 10), // Per-attempt timeout
  ),
);
```

### Reusable Retryable Function

```dart
final retryableApiCall = SmartRetry.retryable(
  () => apiCall(),
  options: RetryOptions(
    policy: ExponentialBackoffPolicy(),
  ),
);

// Call multiple times
final result1 = await retryableApiCall();
final result2 = await retryableApiCall();
```

## Retry Policies

### ExponentialBackoffPolicy

Delays increase exponentially: `baseDelay * (2 ^ attempt)`

```dart
ExponentialBackoffPolicy(
  maxAttempts: 3,              // Maximum retry attempts
  baseDelay: Duration(seconds: 1),  // Initial delay
  maxDelay: Duration(seconds: 30),  // Maximum delay cap
  useJitter: true,             // Add randomization
  multiplier: 2.0,             // Exponential multiplier
)
```

**Example delays:** 1s, 2s, 4s, 8s, 16s...

### LinearBackoffPolicy

Delays increase linearly: `baseDelay * attempt`

```dart
LinearBackoffPolicy(
  maxAttempts: 5,
  baseDelay: Duration(seconds: 2),
  maxDelay: Duration(seconds: 10),
  useJitter: true,
)
```

**Example delays:** 2s, 4s, 6s, 8s, 10s...

### FixedDelayPolicy

Always uses the same delay.

```dart
FixedDelayPolicy(
  maxAttempts: 3,
  baseDelay: Duration(seconds: 3),
)
```

**Example delays:** 3s, 3s, 3s...

## Circuit Breaker

Prevents cascading failures by "opening" the circuit after threshold failures.

```dart
final circuitBreaker = CircuitBreaker(
  failureThreshold: 5,              // Open after 5 failures
  resetTimeout: Duration(seconds: 60),  // Try recovery after 60s
  halfOpenMaxRequests: 3,           // Test with 3 requests
);

// States: closed → open → halfOpen → closed
print(circuitBreaker.state); // CircuitState.closed
```

### Circuit States

- **Closed**: Normal operation, requests allowed
- **Open**: Too many failures, requests rejected
- **Half-Open**: Testing recovery, limited requests allowed

## Error Handling

```dart
try {
  final result = await SmartRetry.execute(
    () => apiCall(),
    options: RetryOptions(
      policy: ExponentialBackoffPolicy(),
      circuitBreaker: circuitBreaker,
    ),
  );
} on CircuitBreakerOpenException {
  print('Circuit breaker is open!');
} catch (e) {
  print('All retries failed: $e');
}
```

## Best Practices

1. **Choose appropriate max attempts**: 3-5 for most cases
2. **Set reasonable delays**: Start with 1-2 seconds
3. **Always use jitter**: Prevents thundering herd
4. **Use circuit breaker**: For external services
5. **Add timeouts**: Prevent hanging requests
6. **Log retry attempts**: Monitor retry patterns

## Performance

- Zero overhead when no retries needed
- Minimal memory footprint
- No background threads
- Pure Dart implementation

## License

MIT License - see LICENSE file for details.
