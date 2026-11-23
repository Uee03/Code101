import 'package:dio/dio.dart';

import 'api_problem.dart';

/// One person-readable message for every problem type of the platform contract.
String problemMessage(ApiProblem problem) {
  switch (problem.kind) {
    case 'network':
      return 'No connection. Check your network and try again.';
    case 'bad-request':
      return 'The request was not understood. Update the app and try again.';
    case 'unauthorized':
      return 'Your session ended. Please sign in again.';
    case 'forbidden':
      return 'You are not allowed to do that.';
    case 'not-found':
      return 'That item does not exist, or you cannot see it.';
    case 'conflict':
      return 'That conflicts with something that already exists.';
    case 'precondition-failed':
      return 'Someone changed this item. Reload it and try again.';
    case 'validation-error':
      return 'Please fix the highlighted fields.';
    case 'precondition-required':
      return 'The app sent an incomplete request. Update the app.';
    case 'rate-limited':
      final wait = problem.retryAfter;
      if (wait == null) {
        return 'Too many requests. Try again in a moment.';
      }
      return 'Too many requests. Try again in ${wait.inSeconds} seconds.';
    case 'internal-error':
      return 'The server had a problem. Try again later.';
    default:
      return problem.title;
  }
}

/// A message for any failure a repository or provider may hand to a view.
String describeError(Object error) {
  if (error is DioException) {
    return problemMessage(ApiProblem.of(error));
  }
  if (error is ApiProblem) {
    return problemMessage(error);
  }
  return 'Something went wrong. Try again.';
}

/// The message the server attached to one field (a JSON Pointer such as /title), if any.
String? fieldMessage(Object? failure, String pointer) {
  if (failure is ApiProblem) {
    return failure.fieldErrors[pointer];
  }
  return null;
}
