import 'package:material_ui/material_ui.dart';

class FeatureCard extends StatelessWidget {
  const FeatureCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: .infinity,
        padding: const .symmetric(horizontal: 24, vertical: 12),
        child: Row(
          crossAxisAlignment: .center,
          spacing: 24,
          children: [
            Icon(icon, size: 28),
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                spacing: 4,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: .bold,
                    ),
                  ),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
