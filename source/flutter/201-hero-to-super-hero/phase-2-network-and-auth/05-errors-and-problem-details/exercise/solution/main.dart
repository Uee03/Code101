// Exercise 05: problem details. Run with: dart run main.dart

class Problem {
  const Problem({
    required this.type,
    required this.title,
    required this.status,
    this.fieldErrors = const {},
    this.retryAfter,
  });

  final String type;
  final String title;
  final int status;
  final Map<String, String> fieldErrors;
  final Duration? retryAfter;

  String get kind => type.split('/').last;

  bool get retryable {
    return status == 408 || status == 425 || status == 429 || status >= 500;
  }
}

Problem parseProblem(
  int status,
  Map<String, Object?> body, {
  String? retryAfterHeader,
}) {
  final errors = body['errors'];
  final seconds = int.tryParse(retryAfterHeader ?? '');
  return Problem(
    type: body['type'] as String? ?? 'about:blank',
    title: body['title'] as String? ?? 'Request failed ($status)',
    status: status,
    fieldErrors: {
      if (errors is List)
        for (final entry in errors)
          if (entry is Map && entry['pointer'] is String && entry['detail'] is String)
            entry['pointer'] as String: entry['detail'] as String,
    },
    retryAfter: seconds == null ? null : Duration(seconds: seconds),
  );
}

String message(Problem problem) {
  switch (problem.kind) {
    case 'validation-error':
      return 'Please fix the highlighted fields.';
    case 'rate-limited':
      final wait = problem.retryAfter;
      if (wait == null) {
        return 'Too many requests. Try again in a moment.';
      }
      return 'Too many requests. Try again in ${wait.inSeconds} seconds.';
    default:
      return problem.title;
  }
}

void main() {
  final validation = parseProblem(422, {
    'type': 'https://code101.example/problems/validation-error',
    'title': 'Validation failed',
    'errors': [
      {'pointer': '/title', 'detail': 'Title is required'},
    ],
  });
  print(message(validation));
  print(validation.fieldErrors['/title']);
  final limited = parseProblem(
    429,
    {
      'type': 'https://code101.example/problems/rate-limited',
      'title': 'Too many requests',
    },
    retryAfterHeader: '30',
  );
  print(message(limited));
  final unknown = parseProblem(418, {
    'type': 'https://code101.example/problems/teapot',
    'title': 'I am a teapot',
  });
  print(message(unknown));
  print(parseProblem(502, {}).retryable);
  print(parseProblem(404, {}).retryable);
}
