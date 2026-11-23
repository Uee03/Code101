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
    // TODO 3: true for status 408, 425, 429 and every status of 500 or more
    return false;
  }
}

Problem parseProblem(
  int status,
  Map<String, Object?> body, {
  String? retryAfterHeader,
}) {
  // TODO 1: build a Problem. type defaults to 'about:blank' and title to
  //         'Request failed ($status)'. Turn body['errors'] (a list of maps with
  //         'pointer' and 'detail') into fieldErrors. Turn a whole-number
  //         retryAfterHeader into a Duration in seconds.
  return Problem(type: 'about:blank', title: 'Request failed ($status)', status: status);
}

String message(Problem problem) {
  // TODO 2: return 'Please fix the highlighted fields.' for kind validation-error,
  //         'Too many requests. Try again in N seconds.' for rate-limited
  //         (N from retryAfter, or 'Too many requests. Try again in a moment.' without it),
  //         and the problem's title for any other kind.
  return problem.title;
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
