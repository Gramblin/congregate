import 'dart:async';
// import 'dart:js_interop';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:web/web.dart' as web;

class GameConnectionManager {
  GameConnectionManager() {
    _setupConnectivityListener();
  }
  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionStreamController =
      StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  Stream<bool> get connectionStream => _connectionStreamController.stream;

  void _setupConnectivityListener() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      results,
    ) {
      final hasConnection =
          results.isNotEmpty &&
          (results.contains(ConnectivityResult.bluetooth) ||
              results.contains(ConnectivityResult.ethernet) ||
              results.contains(ConnectivityResult.wifi) ||
              results.contains(ConnectivityResult.vpn) ||
              results.contains(ConnectivityResult.mobile));

      if (!hasConnection) {
        _setGameLiveStatus(false);
      } else {
        _setGameLiveStatus(true);
      }
    });
  }

  void _setGameLiveStatus(bool isLive) {
    if (!_connectionStreamController.isClosed) {
      _connectionStreamController.add(isLive);
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _connectionStreamController.close();
  }
}

final gameConnectionStreamProvider = StreamProvider<bool>((ref) {
  // if (kIsWeb) {
  // final controller =
  // StreamController<bool>.broadcast()..add(web.window.navigator.onLine);

  // web.window.addEventListener('online', ((_) => controller.add(true)).toJS());
  // web.window.addEventListener('offline', (_) => controller.add(false));

  //   ref.onDispose(controller.close);

  //   return controller.stream;
  // } else {
  final connectionManager = GameConnectionManager();
  ref.onDispose(connectionManager.dispose);
  return connectionManager.connectionStream;
  // }
});
