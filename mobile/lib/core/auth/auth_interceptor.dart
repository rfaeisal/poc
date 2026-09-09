import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../api/api_endpoints.dart';
import 'auth_storage.dart';

class AuthInterceptor extends QueuedInterceptor {
  final Dio _dio;
  final AuthStorage _authStorage;
  final VoidCallback onAuthFailure;

  AuthInterceptor({
    required Dio dio,
    required AuthStorage authStorage,
    required this.onAuthFailure,
  })  : _dio = dio,
        _authStorage = authStorage;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _authStorage.accessToken;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    final refreshToken = await _authStorage.refreshToken;
    if (refreshToken == null) {
      onAuthFailure();
      return handler.next(err);
    }

    try {
      final response = await _dio.post(
        ApiEndpoints.refresh,
        data: {'refreshToken': refreshToken},
        options: Options(headers: {'Authorization': ''}),
      );

      final newAccessToken = response.data['accessToken'] as String;
      final newRefreshToken = response.data['refreshToken'] as String;

      await _authStorage.saveTokens(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      );

      final retryOptions = err.requestOptions;
      retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';

      final retryResponse = await _dio.fetch(retryOptions);
      handler.resolve(retryResponse);
    } on DioException {
      await _authStorage.clearTokens();
      onAuthFailure();
      handler.next(err);
    }
  }
}
