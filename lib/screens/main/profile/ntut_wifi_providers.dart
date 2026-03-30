import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/repositories/campus_wifi_repository.dart';

final ntutWifiAssistantProvider =
    FutureProvider.autoDispose<Ntut8021xAssistantData>((ref) async {
      return ref
          .watch(campusWifiRepositoryProvider)
          .getNtut8021xAssistantData();
    });
