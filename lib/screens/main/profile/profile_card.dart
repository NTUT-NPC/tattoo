import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tattoo/components/app_skeleton.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/screens/main/profile/profile_providers.dart';

const _placeholderProfile = UserProfile(
  id: 0,
  avatarFilename: '',
  email: 't000000000@ntut.edu.tw',
  studentId: '000000000',
  name: 'John Doe',
);

class ProfileCard extends ConsumerWidget {
  const ProfileCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final avatarAsync = ref.watch(userAvatarProvider);

    return profileAsync.when(
      loading: () => const AppSkeleton(
        child: ProfileContent(profile: _placeholderProfile),
      ),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (profile) {
        if (profile == null) {
          return const Text('未登入');
        }
        return ProfileContent(
          profile: profile,
          avatarFile: avatarAsync.value,
        );
      },
    );
  }
}

class ProfileContent extends StatelessWidget {
  const ProfileContent({super.key, required this.profile, this.avatarFile});

  final UserProfile profile;
  final File? avatarFile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AspectRatio(
      aspectRatio: 1016 / 638,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final avatarSize = height * 0.59;
          final borderRadius = BorderRadius.circular(height * 0.07);
          final avatarInitial = switch (profile.name) {
            final n? when n.isNotEmpty => n.substring(0, 1),
            _ => '?',
          };

          return DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 16.0,
                  offset: Offset(0.0, 4.0),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: borderRadius,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: SvgPicture.asset(
                      'assets/profile_card_background.svg',
                      fit: BoxFit.cover,
                    ),
                  ),

                  // identity on top right corner
                  Positioned(
                    right: width * 0.095,
                    top: height * 0.018,
                    child: Text(
                      '學生',
                      textAlign: TextAlign.left,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Color(0xFF3B3B3B),
                        fontSize: height * 0.07,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  // profile info
                  Positioned(
                    left: width * 0.07,
                    top: height * 0.25,
                    width: width * 0.48,
                    child: DefaultTextStyle(
                      style:
                          theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontSize: height * 0.065,
                            fontWeight: FontWeight.w400,
                            height: 1.1,
                          ) ??
                          const TextStyle(color: Colors.white),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        spacing: height * 0.01,
                        children: [
                          Transform.translate(
                            // fix horizontal alignment with other text
                            offset: Offset(-height * 0.01, 0),
                            child: Text(
                              profile.name ?? '未知',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontSize: height * 0.11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 4,
                                height: 1.6,
                              ),
                            ),
                          ),
                          Text(
                            // todo: replace with real department
                            '電子工程系',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            // todo: resolve vertical alignment issue when having no chinese character
                            profile.studentId,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            // todo: replace with real class
                            '114-2 電子三甲',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // avatar photo
                  Positioned(
                    left: width * 0.58,
                    top: height * 0.27,
                    width: avatarSize,
                    height: avatarSize,
                    child: Skeleton.leaf(
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFB3B3B5),
                        ),
                        child: ClipOval(
                          child: avatarFile != null
                              ? Image.file(
                                  avatarFile!,
                                  fit: BoxFit.cover,
                                )
                              : Center(
                                  child: Text(
                                    avatarInitial,
                                    style: TextStyle(
                                      color: const Color(0xFF808080),
                                      fontWeight: FontWeight.w700,
                                      fontSize: avatarSize * 0.36,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
