import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

String friendlyErrorMessage(Object error, {required String fallback}) {
  if (error is AuthException) {
    final message = error.message.toLowerCase();

    if (message.contains('invalid login') ||
        message.contains('invalid credentials')) {
      return 'The email or password is incorrect.';
    }

    if (message.contains('expired') || message.contains('session')) {
      return 'Your session has expired. Please sign in again.';
    }

    if (message.contains('disabled')) {
      return 'This account is currently disabled.';
    }

    return 'Authentication could not be completed. Please try again.';
  }

  if (error is PostgrestException) {
    switch (error.code) {
      case '42501':
        return 'You do not have permission to perform this action.';
      case '23505':
        return 'A record with the same information already exists.';
      case 'PGRST116':
        return 'The selected record no longer exists.';
    }
  }

  final message = error.toString().toLowerCase();

  if (message.contains('socket') ||
      message.contains('network') ||
      message.contains('failed to fetch') ||
      message.contains('connection')) {
    return 'No network connection. Check your Internet connection and retry.';
  }

  if (message.contains('timeout') || message.contains('timed out')) {
    return 'The request took too long. Please try again.';
  }

  if (message.contains('permission') || message.contains('not allowed')) {
    return 'Permission was denied for this action.';
  }

  if (message.contains('no longer exists') || message.contains('not found')) {
    return 'The selected record no longer exists or has already changed.';
  }

  return fallback;
}

void logDebugError(String operation, Object error, [StackTrace? stackTrace]) {
  if (!kDebugMode) {
    return;
  }

  debugPrint('$operation failed (${error.runtimeType}): $error');
  if (stackTrace != null) {
    debugPrintStack(stackTrace: stackTrace);
  }
}
