import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:smart_kids_app_end/screen/noconnect/no_connect.dart';

class InternetService {
  static final InternetService _instance = InternetService._internal();
  factory InternetService() => _instance;
  InternetService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isNoConnectionOpen = false;

  void startListening() {
    _subscription =
        _connectivity.onConnectivityChanged.listen((results) {
          final hasInternet =
          results.any((result) => result != ConnectivityResult.none);

          if (!hasInternet && !_isNoConnectionOpen) {
            _isNoConnectionOpen = true;
            Get.to(() => NoConnect());
          }

          if (hasInternet && _isNoConnectionOpen) {
            _isNoConnectionOpen = false;
            Get.back();
          }
        });
  }

  void dispose() {
    _subscription?.cancel();
  }
}
