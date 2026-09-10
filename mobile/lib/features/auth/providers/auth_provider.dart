import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/auth/auth_storage.dart';
import '../models/user.dart';

final authStorageProvider = Provider<AuthStorage>((ref) => AuthStorage());

final _authFailureController = StreamController<void>.broadcast();

final apiClientProvider = Provider<ApiClient>((ref) {
  final authStorage = ref.watch(authStorageProvider);
  return ApiClient(
    authStorage: authStorage,
    onAuthFailure: () => _authFailureController.add(null),
  );
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final notifier = AuthNotifier(
    apiClient: ref.watch(apiClientProvider),
    authStorage: ref.watch(authStorageProvider),
  );

  final sub = _authFailureController.stream.listen((_) {
    notifier.forceLogout();
  });
  ref.onDispose(sub.cancel);

  return notifier;
});

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  bool get isAuthenticated => user != null;

  AuthState copyWith({User? user, bool? isLoading, String? error}) => AuthState(
        user: user ?? this.user,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient;
  final AuthStorage _authStorage;

  AuthNotifier({
    required ApiClient apiClient,
    required AuthStorage authStorage,
  })  : _apiClient = apiClient,
        _authStorage = authStorage,
        super(const AuthState());

  Dio get _dio => _apiClient.dio;

  Future<void> tryAutoLogin() async {
    final hasTokens = await _authStorage.hasTokens;
    if (!hasTokens) return;

    state = state.copyWith(isLoading: true);
    try {
      final response = await _dio.get(ApiEndpoints.me);
      final user = User.fromJson(response.data['user'] as Map<String, dynamic>);
      state = AuthState(user: user);
    } on DioException {
      await _authStorage.clearTokens();
      state = const AuthState();
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _dio.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );

      await _authStorage.saveTokens(
        accessToken: response.data['accessToken'] as String,
        refreshToken: response.data['refreshToken'] as String,
      );

      final user = User.fromJson(response.data['user'] as Map<String, dynamic>);
      state = AuthState(user: user);
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ??
          'Login gagal. Coba lagi.';
      state = state.copyWith(isLoading: false, error: message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Login gagal: $e');
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String callsign,
    required String name,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _dio.post(
        ApiEndpoints.register,
        data: {
          'email': email,
          'password': password,
          'callsign': callsign,
          'name': name,
        },
      );

      await _authStorage.saveTokens(
        accessToken: response.data['accessToken'] as String,
        refreshToken: response.data['refreshToken'] as String,
      );

      final user = User.fromJson(response.data['user'] as Map<String, dynamic>);
      state = AuthState(user: user);
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ??
          'Registrasi gagal. Coba lagi.';
      state = state.copyWith(isLoading: false, error: message);
    }
  }

  Future<void> logout() async {
    try {
      final refreshToken = await _authStorage.refreshToken;
      if (refreshToken != null) {
        await _dio.post(
          ApiEndpoints.logout,
          data: {'refreshToken': refreshToken},
        );
      }
    } catch (_) {}
    await _authStorage.clearTokens();
    state = const AuthState();
  }

  void forceLogout() {
    _authStorage.clearTokens();
    state = const AuthState();
  }
}
