import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tattoo/components/app_skeleton.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/screens/main/profile/profile_providers.dart';

const _placeholderProfile = User(
  id: 0,
  studentId: '000000000',
  nameZh: '王襲浮',
  avatarFilename: '',
  email: 't000000000@ntut.edu.tw',
);

// Configs for profile card styling
const _profileCardBackgroundColor = Color(0xFFF2F2F2);
const _profileCardRadiusFactor = 0.07;
const _profileCardShadow = BoxShadow(
  color: Color(0x66000000),
  blurRadius: 16.0,
  offset: Offset(0.0, 4.0),
);

class ProfileCard extends ConsumerWidget {
  const ProfileCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final avatarAsync = ref.watch(userAvatarProvider);
    final mediaQuery = MediaQuery.of(context);

    return MediaQuery(
      // no text scaling to prevent card style from breaking
      data: mediaQuery.copyWith(textScaler: TextScaler.noScaling),
      child: profileAsync.when(
        loading: () => const AppSkeleton(
          child: ProfileContent(profile: _placeholderProfile),
        ),
        error: (error, _) => _ProfileCardFrame(
          childBuilder: (context, _, _) => Center(
            child: Text('Error: $error'),
          ),
        ),
        data: (profile) {
          if (profile == null) {
            return _ProfileCardFrame(
              childBuilder: (context, _, _) => Center(child: Text('未登入')),
            );
          }
          return ProfileContent(
            profile: profile,
            avatarFile: avatarAsync.value,
          );
        },
      ),
    );
  }
}

class ProfileContent extends StatelessWidget {
  const ProfileContent({super.key, required this.profile, this.avatarFile});

  final User profile;
  final File? avatarFile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _ProfileCardFrame(
      childBuilder: (context, constraints, borderRadius) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final avatarSize = height * 0.59;
        final avatarInitial = switch (profile.nameZh) {
          final n when n.isNotEmpty => n.substring(0, 1),
          _ => '?',
        };

        return ClipRRect(
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
                          profile.nameZh.isNotEmpty ? profile.nameZh : '未知',
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
                        // TODO: replace with real department
                        '字串尚待更換學系',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        // TODO: resolve vertical alignment issue when having no chinese character
                        profile.studentId,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        // TODO: replace with real class
                        '999-9 叉叉一甲',
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
        );
      },
    );
  }
}

class _ProfileCardFrame extends StatelessWidget {
  const _ProfileCardFrame({required this.childBuilder});

  final Widget Function(
    BuildContext context,
    BoxConstraints constraints,
    BorderRadius borderRadius,
  )
  childBuilder;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1016 / 638,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final height = constraints.maxHeight;
          final borderRadius = BorderRadius.circular(
            height * _profileCardRadiusFactor,
          );

          return DecoratedBox(
            decoration: BoxDecoration(
              color: _profileCardBackgroundColor,
              borderRadius: borderRadius,
              boxShadow: const [_profileCardShadow],
            ),
            child: childBuilder(context, constraints, borderRadius),
          );
        },
      ),
    );
  }
}
