void main() {
  final uri = Uri.parse('https://tasks.example.invalid');
  // TODO: allow only HTTPS here; print Allowed or Denied.
  print(uri.host);
}
