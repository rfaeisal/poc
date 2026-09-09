import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../config/app_config.dart';
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
