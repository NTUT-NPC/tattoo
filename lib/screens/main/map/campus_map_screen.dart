import 'dart:async';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tattoo/components/floating_action_bar.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/models/campus_map.dart';
import 'package:tattoo/repositories/campus_map_repository.dart';
import 'package:tattoo/screens/main/map/campus_map_floor_selector.dart';
import 'package:tattoo/screens/main/map/campus_map_geometry.dart';
import 'package:tattoo/screens/main/map/campus_map_providers.dart';
import 'package:tattoo/screens/main/map/campus_map_search_dialog.dart';
import 'package:tattoo/screens/main/map/campus_map_search_results.dart';
import 'package:tattoo/screens/main/map/campus_map_viewport.dart';
import 'package:tattoo/utils/auto_spacing.dart';

/// A campus overview with building-scoped indoor browsing and room search.
class CampusMapScreen extends ConsumerStatefulWidget {
  /// Opens the map and optionally searches [initialQuery] after its first frame.
  ///
  /// A unique name or classroom number is located immediately; ambiguous
  /// references show a result list. [tileProvider] supports offline widget tests.
  const CampusMapScreen({super.key, this.initialQuery, this.tileProvider});

  final String? initialQuery;
  final TileProvider? tileProvider;

  @override
  ConsumerState<CampusMapScreen> createState() => _CampusMapScreenState();
}

class _CampusMapScreenState extends ConsumerState<CampusMapScreen> {
  final _controller = MapController();
  String _query = '';
  String? _buildingCode;
  CampusMapFloor? _floor;
  CampusMapRoom? _selectedRoom;
  bool _mapReady = false;
  bool _busy = false;
  int _operation = 0;
  List<CampusMapPolygon>? _pendingFocus;
  Timer? _autoSelectTimer;
  bool _loadFailed = false;
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _loadFailedBar;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery case final query? when query.trim().isNotEmpty) {
      _query = query;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _search(query);
      });
    }
  }

  @override
  void dispose() {
    _operation++;
    _autoSelectTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _focus(List<CampusMapPolygon> polygons) {
    if (!_mapReady) {
      _pendingFocus = polygons;
      return;
    }
    final points = [
      for (final polygon in polygons)
        for (final point in polygon.rings.first)
          LatLng(point.latitude, point.longitude),
    ];
    if (points.isEmpty) return;
    _controller.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: const EdgeInsets.all(48),
        maxZoom: 21,
      ),
    );
  }

  void _selectBuilding(CampusMapBuilding building, {bool focus = true}) {
    _operation++;
    setState(() {
      _busy = false;
      _buildingCode = building.code;
      _floor =
          building.floors.where((floor) => floor.code == '1F').firstOrNull ??
          building.floors.firstOrNull;
      _selectedRoom = null;
    });
    if (focus) _focus(building.polygons);
  }

  void _onUserCameraChanged(MapCamera camera) {
    _autoSelectTimer?.cancel();
    // Programmatic search/focus changes are excluded by the viewport callback.
    // A zoomed-in camera center identifies the building under the user's view.
    if (camera.zoom < 19.5 || _busy) return;
    final point = (
      latitude: camera.center.latitude,
      longitude: camera.center.longitude,
    );
    final buildings = ref.read(campusMapBuildingsProvider).value ?? [];
    final matches = buildings.where(
      (building) => building.polygons.any(
        (polygon) => campusMapContainsPoint(polygon, point),
      ),
    );
    if (matches.any((building) => building.code == _buildingCode)) return;
    // Do not guess when campus outlines overlap.
    if (matches.length != 1) return;
    final building = matches.single;
    final operation = _operation;
    _autoSelectTimer = Timer(const Duration(milliseconds: 160), () {
      if (mounted &&
          !_busy &&
          operation == _operation &&
          _buildingCode != building.code) {
        _selectBuilding(building, focus: false);
      }
    });
  }

  void _selectFloor(CampusMapFloor floor) {
    _operation++;
    setState(() {
      _busy = false;
      _floor = floor;
      _selectedRoom = null;
    });
  }

  void _overview() {
    _operation++;
    setState(() {
      _busy = false;
      _buildingCode = null;
      _floor = null;
      _selectedRoom = null;
    });
    _controller.move(const LatLng(25.0436, 121.5350), 17.5);
  }

  Future<void> _search(String query) async {
    if (normalizeCampusMapQuery(query).isEmpty) return;
    final operation = ++_operation;
    setState(() => _busy = true);
    try {
      final repository = ref.read(campusMapRepositoryProvider);
      final matches = await repository.searchRooms(query);
      if (!mounted || operation != _operation) return;
      if (matches.isEmpty) {
        _showMessage(t.campusMap.noResults);
        return;
      }
      CampusMapRoom? result;
      if (matches.length == 1) {
        result = matches.single;
      } else {
        setState(() => _busy = false);
        result = await showModalBottomSheet<CampusMapRoom>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (context) => CampusMapSearchResults(rooms: matches),
        );
      }
      if (!mounted || operation != _operation || result == null) return;
      setState(() => _busy = true);
      final room = await repository.locateRoom(result);
      if (!mounted || operation != _operation) return;
      if (room == null) {
        _showMessage(t.campusMap.locationUnavailable);
        return;
      }
      setState(() {
        _buildingCode = room.buildingCode;
        _floor = room.floor;
        _selectedRoom = room;
      });
      _focus(room.polygons);
    } catch (_) {
      if (mounted && operation == _operation) {
        _showMessage(t.campusMap.searchFailed);
      }
    } finally {
      if (mounted && operation == _operation) setState(() => _busy = false);
    }
  }

  Future<void> _openSearch() async {
    if (_busy) return;
    final query = await showDialog<String>(
      context: context,
      builder: (context) => CampusMapSearchDialog(initialQuery: _query),
    );
    if (!mounted || query == null) return;
    _query = query;
    await _search(query);
  }

  /// Replaces the visible message so repeated failures do not queue up.
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> _showMessage(
    String message, {
    SnackBarAction? action,
  }) {
    return (ScaffoldMessenger.of(context)..hideCurrentSnackBar()).showSnackBar(
      SnackBar(content: Text(message), action: action),
    );
  }

  void _showLoadFailed() {
    final bar = _showMessage(
      t.campusMap.loadFailed,
      action: SnackBarAction(label: t.general.retry, onPressed: _refresh),
    );
    _loadFailedBar = bar;
    bar.closed.then((_) {
      if (identical(_loadFailedBar, bar)) _loadFailedBar = null;
    });
  }

  /// Shows or dismisses the retry message when the load state changes.
  void _syncLoadFailed(bool failed) {
    if (failed == _loadFailed) return;
    _loadFailed = failed;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || failed != _loadFailed) return;
      if (failed) {
        _showLoadFailed();
      } else if (_loadFailedBar != null) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
    });
  }

  Future<void> _refresh() async {
    if (_busy) return;
    final operation = ++_operation;
    setState(() => _busy = true);
    try {
      final repository = ref.read(campusMapRepositoryProvider);
      if (_floor case final floor?) {
        await repository.refreshFloor(floor.layerName);
      } else {
        await repository.refreshBuildings();
      }
    } catch (_) {
      if (mounted && operation == _operation) {
        _showLoadFailed();
      }
    } finally {
      if (mounted && operation == _operation) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(campusMapBuildingsProvider, (_, next) {
      final buildings = next.value;
      if (buildings == null || _buildingCode == null) return;
      final building = buildings
          .where((item) => item.code == _buildingCode)
          .firstOrNull;
      if (building == null) {
        _overview();
      } else if (_floor case final floor?
          when !building.floors.any(
            (item) => item.layerName == floor.layerName,
          )) {
        _selectBuilding(building);
      }
    });
    final catalog = ref.watch(campusMapBuildingsProvider);
    final buildings = catalog.value ?? const <CampusMapBuilding>[];
    final building = buildings
        .where((building) => building.code == _buildingCode)
        .firstOrNull;
    final floorData = _floor == null
        ? null
        : ref.watch(campusMapFloorProvider(_floor!.layerName));
    final rooms = floorData?.value?.rooms ?? const <CampusMapRoom>[];
    if (_floor case final floor?) {
      ref.listen(campusMapFloorProvider(floor.layerName), (_, next) {
        if (next.value case final data?
            when data.hasCache && _selectedRoom != null) {
          setState(() {
            _selectedRoom = data.rooms
                .where((room) => room.id == _selectedRoom!.id)
                .firstOrNull;
          });
        }
        if (building?.polygons.isEmpty == true &&
            _selectedRoom == null &&
            next.value?.rooms.isNotEmpty == true) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _floor?.layerName == floor.layerName) {
              _focus(
                next.value!.rooms.expand((room) => room.polygons).toList(),
              );
            }
          });
        }
      });
    }
    final failed =
        catalog.hasError ||
        (!catalog.isLoading && buildings.isEmpty) ||
        floorData?.hasError == true ||
        floorData?.value?.hasCache == false;
    _syncLoadFailed(failed);
    final loading = catalog.isLoading || floorData?.isLoading == true || _busy;
    final indoor = building != null && building.floors.isNotEmpty;
    final actions = [
      FloatingActionBarActionButton(
        icon: Icons.search,
        tooltip: t.campusMap.search,
        onTap: _openSearch,
      ),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(indoor ? building.name.spaced : t.campusMap.title),
        actions: [
          IconButton(
            tooltip: t.campusMap.refresh,
            onPressed: _busy ? null : _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      // The floating action button slot keeps snack bars clear of the bar.
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .stretch,
          spacing: 4,
          children: [
            const Align(
              alignment: .centerLeft,
              child: CampusMapAttribution(),
            ),
            if (indoor)
              FloatingActionBar(
                actions: actions,
                child: CampusMapFloorSelector(
                  key: ValueKey(building.code),
                  floors: building.floors,
                  selectedFloor: _floor,
                  onSelected: _selectFloor,
                ),
              )
            else
              Row(mainAxisAlignment: .end, spacing: 8, children: actions),
          ],
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            CampusMapViewport(
              controller: _controller,
              buildings: buildings,
              rooms: rooms.isEmpty && _selectedRoom != null
                  ? [_selectedRoom!]
                  : rooms,
              selectedBuildingCode: _buildingCode,
              selectedRoomId: _selectedRoom?.id,
              onBuildingSelected: _selectBuilding,
              onRoomSelected: (room) => setState(() => _selectedRoom = room),
              onReady: () {
                _mapReady = true;
                if (_pendingFocus case final polygons?) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _focus(polygons);
                  });
                  _pendingFocus = null;
                }
              },
              onUserCameraChanged: _onUserCameraChanged,
              tileProvider: widget.tileProvider,
            ),
            if (loading)
              const Align(
                alignment: .topCenter,
                child: LinearProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}
