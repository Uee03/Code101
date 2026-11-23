import 'package:connectivity_plus/connectivity_plus.dart';

final class ConnectivityService {
  Stream<bool> get changes => Connectivity().onConnectivityChanged.map((values) => !values.contains(ConnectivityResult.none));
  Future<bool> available() async => !(await Connectivity().checkConnectivity()).contains(ConnectivityResult.none);
}
