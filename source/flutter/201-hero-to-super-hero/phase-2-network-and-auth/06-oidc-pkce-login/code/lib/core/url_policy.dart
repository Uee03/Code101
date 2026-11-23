abstract final class UrlPolicy {
  static const _devHosts = {'10.0.2.2', 'localhost', '127.0.0.1'};

  /// Accepts https URLs, and http only for development hosts in debug builds.
  static Uri validate(String value, {required bool debug}) {
    final uri = Uri.parse(value);
    final httpAllowed =
        debug && uri.scheme == 'http' && _devHosts.contains(uri.host);
    final badParts =
        uri.userInfo.isNotEmpty || uri.hasFragment || uri.hasQuery || uri.host.isEmpty;
    if (badParts || (uri.scheme != 'https' && !httpAllowed)) {
      throw const FormatException('Use HTTPS, or a debug-only loopback host.');
    }
    return uri;
  }
}
