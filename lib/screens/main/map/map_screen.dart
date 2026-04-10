import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tattoo/repositories/map_repository.dart';
import 'package:tattoo/i18n/strings.g.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final TransformationController _transformationController =
      TransformationController();
  bool _initialized = false;

  void _resetView() {
    setState(() {
      _transformationController.value = Matrix4.identity();
    });
  }

  @override
  Widget build(BuildContext context) {
    final manifestAsync = ref.watch(mapManifestProvider);
    final selectedFloor = ref.watch(selectedFloorProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t['nav.map'] ?? 'Campus Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.center_focus_strong),
            onPressed: _resetView,
            tooltip: 'Reset View',
          ),
        ],
      ),
      body: manifestAsync.when(
        data: (manifest) {
          final floorImage = selectedFloor != null
              ? manifest.floors[selectedFloor]
              : null;

          if (!_initialized) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_initialized) {
                setState(() {
                  _initialized = true;
                });
                ref.read(mapRepositoryProvider).precacheAll(manifest);
              }
            });
          }

          return ListenableBuilder(
            listenable: _transformationController,
            builder: (context, child) {
              // Calculate current zoom level
              final zoom = _transformationController.value.getMaxScaleOnAxis();
              final isHighResNeeded = zoom > 2.0;

              return Stack(
                children: [
                  // Map Viewer
                  Positioned.fill(
                    child: InteractiveViewer(
                      transformationController: _transformationController,
                      boundaryMargin: EdgeInsets.zero,
                      minScale: 1.0,
                      maxScale: 100.0,
                      child: Center(
                        child: AspectRatio(
                          aspectRatio:
                              16000 / 9099, // Use the exact image ratio
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // 1. Base Map - Medium Res (8K)
                              CachedNetworkImage(
                                imageUrl:
                                    '${MapRepository.baseUrl}${manifest.basemap}',
                                fit: BoxFit.fill,
                                memCacheWidth: 8192,
                                alignment: Alignment.center,
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              // 2. Base Map - High Res (16K)
                              if (isHighResNeeded)
                                CachedNetworkImage(
                                  imageUrl:
                                      '${MapRepository.baseUrl}${manifest.basemap}',
                                  fit: BoxFit.fill,
                                  alignment: Alignment.center,
                                  errorWidget: (context, url, error) =>
                                      const SizedBox.shrink(),
                                ),

                              // 3. Floor Layer
                              if (floorImage != null)
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Medium Res Floor (8K)
                                    CachedNetworkImage(
                                      key: ValueKey('${floorImage}_med'),
                                      imageUrl:
                                          '${MapRepository.baseUrl}$floorImage',
                                      fit: BoxFit.fill,
                                      memCacheWidth: 8192,
                                      alignment: Alignment.center,
                                    ),
                                    // High Res Floor (16K)
                                    if (isHighResNeeded)
                                      CachedNetworkImage(
                                        key: ValueKey('${floorImage}_high'),
                                        imageUrl:
                                            '${MapRepository.baseUrl}$floorImage',
                                        fit: BoxFit.fill,
                                        alignment: Alignment.center,
                                        errorWidget: (context, url, error) =>
                                            const SizedBox.shrink(),
                                      ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Floor Selector (Vertical)
                  Positioned(
                    right: 16,
                    top: 16,
                    bottom: 16,
                    child: Center(
                      child: Container(
                        width: 56,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surface.withAlpha(200),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(50),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: manifest.floors.length,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemBuilder: (context, index) {
                            final floorKeys = manifest.floors.keys
                                .toList()
                                .reversed
                                .toList();
                            final floor = floorKeys[index];
                            final isSelected = selectedFloor == floor;

                            return IconButton(
                              onPressed: () => ref
                                  .read(selectedFloorProvider.notifier)
                                  .set(floor),
                              icon: CircleAvatar(
                                backgroundColor: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.transparent,
                                radius: 18,
                                child: Text(
                                  floor,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.onPrimary
                                        : Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  // Legend/Info
                  Positioned(
                    left: 16,
                    bottom: 16,
                    child: IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surface.withAlpha(180),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              selectedFloor ?? 'Base',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Pinch to zoom, drag to move',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
