import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tattoo/components/app_skeleton.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/repositories/auth_repository.dart';
import 'package:tattoo/router/app_router.dart';

final _placeholderProfile = UserWithStudent(
  User(id: 0, student: 0, avatarFilename: '', email: 't000000000@ntut.edu.tw'),
  Student(id: 0, studentId: '000000000', name: 'John Doe'),
);

class ProfileTab extends ConsumerWidget {
  const ProfileTab({
    super.key,
    required this.isLoading,
  });

  final bool isLoading;

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final authRepository = ref.read(authRepositoryProvider);
    await authRepository.logout();
    if (context.mounted) context.go(AppRoutes.intro);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 16,
            children: [
              _ProfileCard(isLoading: isLoading),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isLoading ? null : () => _logout(context, ref),
                  icon: const Icon(Icons.logout),
                  label: const Text('登出'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends ConsumerWidget {
  const _ProfileCard({this.isLoading = false});

  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isLoading) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: AppSkeleton(
            child: _ProfileContent(profile: _placeholderProfile),
          ),
        ),
      );
    }

    final profileAsync = ref.watch(userProfileProvider);
    final avatarAsync = ref.watch(userAvatarProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: profileAsync.when(
          loading: () => AppSkeleton(
            child: _ProfileContent(profile: _placeholderProfile),
          ),
          error: (error, _) => Text('Error: $error'),
          data: (profile) {
            if (profile == null) {
              return const Text('未登入');
            }
            return _ProfileContent(
              profile: profile,
              avatarFile: avatarAsync.value,
            );
          },
        ),
      ),
    );
  }
}

class _ProfileContent extends ConsumerWidget {
  const _ProfileContent({required this.profile, this.avatarFile});

  final UserWithStudent profile;
  final File? avatarFile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Row(
      spacing: 16,
      children: [
        Skeleton.leaf(
          child: CircleAvatar(
            radius: 32,
            backgroundColor: theme.colorScheme.primaryContainer,
            backgroundImage: avatarFile != null ? FileImage(avatarFile!) : null,
            child: avatarFile == null
                ? Text(
                    profile.student.name?.substring(0, 1) ?? '?',
                    style: TextStyle(
                      fontSize: 24,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  )
                : null,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              Text(
                profile.student.name ?? '未知',
                style: theme.textTheme.titleLarge,
              ),
              Text(
                profile.student.studentId,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                profile.user.email,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
