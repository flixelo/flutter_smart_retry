import 'dart:async';
import 'dart:io';
import 'package:flutter_smart_retry/flutter_smart_retry.dart';

void main() async {
  print('=== Flutter Smart Retry Examples ===\n');

  // Example 1: Basic exponential backoff
  await example1();

  // Example 2: With circuit breaker
  await example2();

  // Example 3: Custom retry policy
  await example3();

  // Example 4: Linear backoff
  await example4();

  print('\n=== All examples completed ===');
}

/// Example 1: Basic exponential backoff
Future<void> example1() async {
  print('Example 1: Exponential Backoff');
  print('-' * 40);

  try {
    final result = await SmartRetry.execute(
      () => simulateApiCall(shouldFail: 2), // Fails twice, then succeeds
      options: RetryOptions(
        policy: ExponentialBackoffPolicy(
          maxAttempts: 3,
          baseDelay: Duration(seconds: 1),
          maxDelay: Duration(seconds: 10),
        ),
        onRetry: (attempt, delay) {
          print('  Retry attempt $attempt after ${delay.inSeconds}s');
        },
        onSuccess: () {
          print('  ✅ Success!');
        },
      ),
    );
    print('  Result: $result\n');
  } catch (e) {
    print('  ❌ Failed: $e\n');
  }
}

/// Example 2: Circuit breaker
Future<void> example2() async {
  print('Example 2: With Circuit Breaker');
  print('-' * 40);

  final circuitBreaker = CircuitBreaker(
    failureThreshold: 3,
    resetTimeout: Duration(seconds: 5),
  );

  // First request - will fail and open circuit
  for (var i = 0; i < 4; i++) {
    try {
      await SmartRetry.execute(
        () => simulateApiCall(shouldFail: 999), // Always fails
        options: RetryOptions(
          policy: FixedDelayPolicy(maxAttempts: 1),
          circuitBreaker: circuitBreaker,
        ),
      );
    } catch (e) {
      print('  Request $i: Failed (${circuitBreaker.state})');
    }
  }

  print('  Circuit state: ${circuitBreaker.state}');
  print('  Waiting for circuit to recover...');
  await Future.delayed(Duration(seconds: 6));

  print('  Circuit state after timeout: ${circuitBreaker.state}\n');
}

/// Example 3: Custom retry policy
Future<void> example3() async {
  print('Example 3: Custom Retry Policy');
  print('-' * 40);

  try {
    final result = await SmartRetry.execute(
      () => simulateApiCall(shouldFail: 2),
      options: RetryOptions(
        policy: CustomRetryPolicy(
          maxAttempts: 5,
          delayCalculator: (attempt) {
            // Custom: Fibonacci-like delays
            return Duration(seconds: attempt * attempt);
          },
          retryChecker: (error, attempt) {
            // Only retry on SocketException
            print('  Checking if should retry: ${error.runtimeType}');
            return error is SocketException && attempt < 3;
          },
        ),
        onRetry: (attempt, delay) {
          print('  Custom retry $attempt after ${delay.inSeconds}s');
        },
      ),
    );
    print('  Result: $result\n');
  } catch (e) {
    print('  ❌ Failed: $e\n');
  }
}

/// Example 4: Linear backoff
Future<void> example4() async {
  print('Example 4: Linear Backoff');
  print('-' * 40);

  try {
    final result = await SmartRetry.execute(
      () => simulateApiCall(shouldFail: 2),
      options: RetryOptions(
        policy: LinearBackoffPolicy(
          maxAttempts: 4,
          baseDelay: Duration(seconds: 1),
          maxDelay: Duration(seconds: 5),
        ),
        onRetry: (attempt, delay) {
          print('  Linear retry $attempt after ${delay.inSeconds}s');
        },
        timeout: Duration(seconds: 3),
      ),
    );
    print('  Result: $result\n');
  } catch (e) {
    print('  ❌ Failed: $e\n');
  }
}

/// Simulate an API call that fails N times
int _callCount = 0;
Future<String> simulateApiCall({int shouldFail = 0}) async {
  _callCount++;
  
  await Future.delayed(Duration(milliseconds: 100));

  if (_callCount <= shouldFail) {
    print('  API call #$_callCount: ❌ Failed');
    _callCount = 0; // Reset for next example
    throw SocketException('Connection failed');
  }

  print('  API call #$_callCount: ✅ Success');
  final result = 'Success after $_callCount attempts';
  _callCount = 0;
  return result;
}
