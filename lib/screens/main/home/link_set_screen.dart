import 'package:material_ui/material_ui.dart';
import 'package:tattoo/components/option_entry_tile.dart';
import 'package:tattoo/shells/showcase_shell.dart';
import 'package:tattoo/utils/launch_url.dart';

class LinkSetScreen extends StatelessWidget {
  const LinkSetScreen({
    required this.title,
    required this.description,
    required this.links,
    this.urlOverrides = const {},
    this.logo,
    this.icon,
    super.key,
  }) : assert(logo == null || icon == null);

  final String title;
  final String description;
  final Widget? logo;
  final IconData? icon;
  final List<({String id, String title, String? url, IconData? icon})> links;

  /// URL overrides keyed by link ID, e.g. from `parseLinkUrlOverrides`.
  ///
  /// A listed ID replaces that link's `url` (`null` hides it); unlisted IDs
  /// keep their own `url`.
  final Map<String, String?> urlOverrides;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: ShowcaseShell(
          icon: logo ?? Icon(icon ?? Icons.link),
          title: title,
          subtitle: description,
          body: Column(
            spacing: 8,
            children: [
              for (final link in links)
                if (_urlOf(link)?.trim() case final raw? when raw.isNotEmpty)
                  if (Uri.tryParse(raw) case final url?
                      when (url.scheme == 'http' || url.scheme == 'https') &&
                          url.host.isNotEmpty)
                    OptionEntryTile.icon(
                      icon: link.icon ?? Icons.link,
                      title: link.title,
                      actionIcon: .exitToApp,
                      onTap: () => launchUrl(
                        url,
                        inExternalApplication: true,
                      ),
                    ),
            ],
          ),
          footer: const SizedBox.shrink(),
        ),
      ),
    );
  }

  String? _urlOf(
    ({String id, String title, String? url, IconData? icon}) link,
  ) => urlOverrides.containsKey(link.id) ? urlOverrides[link.id] : link.url;
}
