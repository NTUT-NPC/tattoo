import 'package:material_ui/material_ui.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/shells/showcase_shell.dart';

class LinkSetScreen extends StatelessWidget {
  const LinkSetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final title = t.$wip('Link Set');

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: ShowcaseShell(
          icon: const Icon(Icons.link, size: 64),
          title: title,
          subtitle: t.$wip('External links'),
          body: Column(
            spacing: 8,
            children: [Text(t.$wip('No links to display yet'))],
          ),
          footer: const SizedBox.shrink(),
        ),
      ),
    );
  }
}
