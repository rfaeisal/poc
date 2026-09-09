import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../services/crash_reporting_service.dart';
import '../services/push_notification_service.dart';

final authSideEffectsProvider = Provider<void>((ref) {
  final auth = ref.watch(authProvider);
  final pushService = ref.read(pushNotificationServiceProvider);
  final crashService = ref.read(crashReportingServiceProvider);

  if (auth.isAuthenticated) {
    final user = auth.user!;
    final dio = ref.read(apiClientProvider).dio;

    crashService.setUserId(user.id);

    if (!pushService.isInitialized) {
      pushService.setDio(dio);
      pushService.initialize();
    }
  } else {
    crashService.clearUserId();
    pushService.unregisterDevice();
  }
});
