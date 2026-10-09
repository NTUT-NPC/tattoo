import 'package:material_ui/material_ui.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/models/campus_map.dart';
import 'package:tattoo/screens/main/map/campus_map_labels.dart';
import 'package:tattoo/utils/auto_spacing.dart';

/// Lists ambiguous classroom matches so the user chooses a specific space.
class CampusMapSearchResults extends StatelessWidget {
  const CampusMapSearchResults({super.key, required this.rooms});

  final List<CampusMapRoom> rooms;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.6,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              t.campusMap.searchResults(count: rooms.length).spaced,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: rooms.length,
              itemBuilder: (context, index) {
                final room = rooms[index];
                return ListTile(
                  leading: const Icon(Icons.room_outlined),
                  title: Text(campusMapRoomTitle(room).spaced),
                  subtitle: Text(
                    '${room.buildingName} · ${room.floor.code}'.spaced,
                  ),
                  onTap: () => Navigator.of(context).pop(room),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}
