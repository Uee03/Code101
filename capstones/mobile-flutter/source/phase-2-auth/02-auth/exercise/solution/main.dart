void main() {
  const secondsUntilExpiry = 45;
  print(secondsUntilExpiry <= 60 ? 'Refresh before request' : 'Use current access token');
}
