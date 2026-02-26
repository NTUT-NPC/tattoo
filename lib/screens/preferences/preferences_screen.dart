import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/components/option_entry_tile.dart';
import 'package:tattoo/components/section_header.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/repositories/auth_repository.dart';
import 'package:tattoo/repositories/preferences_repository.dart';
import 'package:tattoo/screens/main/profile/profile_providers.dart';

class PreferencesScreen extends ConsumerWidget {
  const PreferencesScreen({super.key});

  Future<void> _clearDatabase(BuildContext context, WidgetRef ref) async {
    final shouldClear = await _showClearDatabaseDialog(context);
    if (!context.mounted || shouldClear != true) return;

    try {
      await ref.read(preferencesRepositoryProvider).clearDatabase();
      await ref.read(authRepositoryProvider).reloginWithStoredCredentials();
      ref.invalidate(userProfileProvider);
      ref.invalidate(userAvatarProvider);
      ref.invalidate(activeRegistrationProvider);
      if (!context.mounted) return;
      _showMessage(context, t.preferences.messages.clearDbSuccess);
    } catch (error) {
      if (!context.mounted) return;
      _showMessage(context, _mapClearDatabaseError(error));
    }
  }

  String _mapClearDatabaseError(Object error) {
    return switch (error) {
      NotLoggedInException() => t.errors.sessionExpired,
      InvalidCredentialsException() => t.errors.credentialsInvalid,
      _ => t.preferences.messages.clearDbFailed,
    };
  }

  Future<bool?> _showClearDatabaseDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(t.preferences.dialogs.clearDbTitle),
          content: Text(t.preferences.dialogs.clearDbMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(t.preferences.dialogs.clearDbCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(t.preferences.dialogs.clearDbConfirm),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(t.profile.options.preferences)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SectionHeader(title: t.preferences.sections.dataManagement),
            const SizedBox(height: 8),
            OptionEntryTile(
              icon: Icons.delete_sweep_outlined,
              title: t.preferences.options.clearDb,
              onTap: () => _clearDatabase(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}
