import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/services/i_school_plus/i_school_plus_service.dart';

/// Probes the public I-School Plus homepage without authenticated cookies.
final iSchoolPlusAvailabilityProvider = FutureProvider.autoDispose<void>(
  retry: (_, _) => null,
  (ref) async {
    final keepAlive = ref.keepAlive();
    try {
      await ref.watch(iSchoolPlusServiceProvider).checkAvailability();
    } finally {
      keepAlive.close();
    }
  },
);
