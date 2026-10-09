import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/models/campus_map.dart';
import 'package:tattoo/repositories/campus_map_repository.dart';

/// Watches the cached campus outline and available floors for each building.
final campusMapBuildingsProvider =
    StreamProvider.autoDispose<List<CampusMapBuilding>>((ref) {
      return ref.watch(campusMapRepositoryProvider).watchBuildings();
    });

/// Watches only the selected indoor layer and releases it when no longer shown.
final campusMapFloorProvider = StreamProvider.autoDispose
    .family<CampusMapFloorData, String>((ref, layerName) {
      return ref.watch(campusMapRepositoryProvider).watchFloor(layerName);
    });
