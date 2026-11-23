import 'package:connectivity_plus/connectivity_plus.dart';

/// Says whether the phone has a network. A network is not the same as a reachable server:
/// the sync engine still treats every failed request as "try again later".
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  Future<bool> isOnline() async {
    return _hasNetwork(await _connectivity.checkConnectivity());
  }

  Stream<bool> get changes {
    return _connectivity.onConnectivityChanged.map(_hasNetwork);
  }

  static bool _hasNetwork(List<ConnectivityResult> results) {
    return !results.contains(ConnectivityResult.none);
  }
}
