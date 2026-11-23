abstract final class UrlPolicy {
  static Uri validate(String value, {required bool debug}) {
    final uri = Uri.parse(value);
    const hosts = {'10.0.2.2', 'localhost', '127.0.0.1'};
    if (uri.userInfo.isNotEmpty || uri.hasFragment || uri.hasQuery ||
        uri.host.isEmpty ||
        (uri.scheme != 'https' &&
            !(debug && uri.scheme == 'http' && hosts.contains(uri.host)))) {
      throw const FormatException('Use HTTPS, or a debug-only loopback host.');
    }
    return uri;
  }
}
