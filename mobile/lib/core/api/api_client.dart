import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

import '../../config/app_config.dart';
import '../../flavors/flavor_config.dart';
import '../auth/auth_interceptor.dart';
import '../auth/auth_storage.dart';

class ApiClient {
  late final Dio dio;
  final AuthStorage authStorage;

  ApiClient({required this.authStorage, required VoidCallback onAuthFailure}) {
    dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    // API 22 doesn't trust Let's Encrypt ISRG Root X1
    if (FlavorConfig.isKsun) {
      dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          client.badCertificateCallback = (cert, host, port) =>
              host == Uri.parse(AppConfig.apiBaseUrl).host;
          return client;
        },
      );
    }

    dio.interceptors.add(AuthInterceptor(
      dio: dio,
      authStorage: authStorage,
      onAuthFailure: onAuthFailure,
    ));

    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
      ));
    }
  }
}
