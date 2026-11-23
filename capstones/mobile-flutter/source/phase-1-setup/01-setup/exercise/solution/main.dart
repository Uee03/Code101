void main() {
  final uri = Uri.parse('https://tasks.example.invalid');
  final allowed = uri.scheme == 'https' && uri.host.isNotEmpty;
  print(allowed ? 'Allowed' : 'Denied');
}
