void main() {
  const release = true;
  final config = release ? 'config/release.example.json' : 'config/dev.json';
  print('Use $config');
}
