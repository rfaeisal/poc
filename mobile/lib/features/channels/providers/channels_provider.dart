import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_endpoints.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/channel.dart';

final channelsProvider =
    StateNotifierProvider<ChannelsNotifier, ChannelsState>((ref) {
  return ChannelsNotifier(dio: ref.watch(apiClientProvider).dio);
});

class ChannelsState {
  final List<Channel> channels;
  final bool isLoading;
  final String? error;

  const ChannelsState({
    this.channels = const [],
    this.isLoading = false,
    this.error,
  });

  ChannelsState copyWith({
    List<Channel>? channels,
    bool? isLoading,
    String? error,
  }) =>
      ChannelsState(
        channels: channels ?? this.channels,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class ChannelsNotifier extends StateNotifier<ChannelsState> {
  final Dio _dio;

  ChannelsNotifier({required Dio dio})
      : _dio = dio,
        super(const ChannelsState());

  Future<void> fetchChannels() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _dio.get(ApiEndpoints.channels);
      final list = (response.data['channels'] as List)
          .map((e) => Channel.fromJson(e as Map<String, dynamic>))
          .toList();
      state = ChannelsState(channels: list);
    } on DioException catch (e) {
      final message =
          e.response?.data?['message'] as String? ?? 'Gagal memuat channel.';
      state = state.copyWith(isLoading: false, error: message);
    }
  }

  Future<JoinChannelResult?> joinChannel(String channelId,
      {String? password}) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.joinChannel(channelId),
        data: password != null ? {'password': password} : {},
      );
      return JoinChannelResult.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ??
          'Gagal join channel.';
      state = state.copyWith(error: message);
      return null;
    }
  }

  Future<void> leaveChannel(String channelId) async {
    try {
      await _dio.post(ApiEndpoints.leaveChannel(channelId), data: {});
    } catch (_) {}
  }
}
