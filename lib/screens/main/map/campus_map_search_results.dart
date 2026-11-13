import 'package:material_ui/material_ui.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/models/campus_map.dart';
import 'package:tattoo/screens/main/map/campus_map_labels.dart';
import 'package:tattoo/utils/auto_spacing.dart';

/// Lets the user choose a building or room from the search results.
class CampusMapSearchResults extends StatelessWidget {
  const CampusMapSearchResults({super.key, required this.results});

  final CampusMapSearchResult results;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.6,
      child: Column(
        children: [
          Padding(
            padding: const .all(16),
            child: Text(
              (results.isExact
                      ? t.campusMap.searchResults(count: results.matches.length)
                      : t.campusMap.searchSuggestions)
                  .spaced,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: results.matches.length,
              itemBuilder: (context, index) {
                final match = results.matches[index];
                final room = match.room;
                final buildingName = campusMapBuildingName(
                  match.buildingCode,
                  fallbackName: match.buildingName,
                );
                return ListTile(
                  leading: Icon(
                    room == null
                        ? Icons.apartment_outlined
                        : Icons.room_outlined,
                  ),
                  title: Text(
                    (room == null ? buildingName : campusMapRoomTitle(room))
                        .spaced,
                  ),
                  subtitle: Text(
                    (room == null
                            ? t.campusMap.searchBuilding(
                                code: match.buildingCode,
                              )
                            : '$buildingName · ${room.floor.code}')
                        .spaced,
                  ),
                  onTap: () => Navigator.of(context).pop(match),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}
