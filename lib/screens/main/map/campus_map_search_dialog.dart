import 'package:material_ui/material_ui.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/utils/auto_spacing.dart';

/// Asks for a classroom name or number and pops with the submitted query.
class CampusMapSearchDialog extends StatefulWidget {
  const CampusMapSearchDialog({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  State<CampusMapSearchDialog> createState() => _CampusMapSearchDialogState();
}

class _CampusMapSearchDialogState extends State<CampusMapSearchDialog> {
  late final _text = TextEditingController(text: widget.initialQuery);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_text.text);

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(t.campusMap.search),
    content: TextField(
      controller: _text,
      autofocus: true,
      textInputAction: .search,
      onSubmitted: (_) => _submit(),
      decoration: InputDecoration(
        hintText: t.campusMap.searchHint.spaced,
        prefixIcon: const Icon(Icons.search),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(t.general.cancel),
      ),
      TextButton(onPressed: _submit, child: Text(t.campusMap.search)),
    ],
  );
}
