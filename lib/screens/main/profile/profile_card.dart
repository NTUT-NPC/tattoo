import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tattoo/components/app_skeleton.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/models/user.dart';
import 'package:tattoo/screens/main/profile/profile_providers.dart';

const _placeholderProfile = User(
  id: 0,
  studentId: '000000000',
  nameZh: '王襲浮',
  nameEn: 'XI-FU, WANG',
  departmentZh: '正在載入中系',
  departmentEn: 'Data Loooooding Engineering',
  avatarFilename: '',
  email: 't000000000@ntut.edu.tw',
);

const _placeholderSemester = UserRegistration(
  year: 199,
  term: 6,
  className: '載入一申',
  enrollmentStatus: EnrollmentStatus.learning,
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
    final registrationAsync = ref.watch(activeRegistrationProvider);
    final mediaQuery = MediaQuery.of(context);

    return MediaQuery(
      // no text scaling to prevent card style from breaking
      data: mediaQuery.copyWith(textScaler: TextScaler.noScaling),

      child: switch ((profileAsync, registrationAsync)) {
        // NOT_LOGIN state: not logged in
        (AsyncData(value: null), _) => _ProfileCardFrame(
          childBuilder: (context, _, _) =>
              Center(child: Text(t.general.notLoggedIn)),
        ),

        // ERROR state: show error message on card
        (AsyncError(:final error), _) ||
        (_, AsyncError(:final error)) => _ProfileCardFrame(
          childBuilder: (context, _, _) => Center(
            child: Text('Error: $error'),
          ),
        ),

        // DATA state: show profile content (even if refreshing)
        (
          AsyncValue(value: final profile, hasValue: true),
          AsyncValue(value: final registration, hasValue: true),
        )
            when profile != null =>
          _FlippableProfileCard(
            front: ProfileContent(
              profile: profile,
              registration: registration,
              avatarFile: avatarAsync.value,
            ),
            back: ProfileBackContent(profile: profile),
          ),

        // LOADING state: show skeleton
        _ => const AppSkeleton(
          child: ProfileContent(
            profile: _placeholderProfile,
            registration: _placeholderSemester,
          ),
        ),
      },
    );
  }
}

class _FlippableProfileCard extends StatefulWidget {
  const _FlippableProfileCard({required this.front, required this.back});

  final Widget front;
  final Widget back;

  @override
  State<_FlippableProfileCard> createState() => _FlippableProfileCardState();
}

class _FlippableProfileCardState extends State<_FlippableProfileCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = _controller.drive(
      Tween<double>(begin: 0.0, end: math.pi).chain(
        CurveTween(curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    if (_controller.status == AnimationStatus.forward ||
        _controller.status == AnimationStatus.completed) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleFlip,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value;
          // Since we only rotate from 0 to pi, back side is visible after pi/2
          final isBack = angle > math.pi / 2;

          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // Perspective
              ..rotateY(angle),
            alignment: Alignment.center,
            child: isBack
                ? Transform(
                    transform: Matrix4.identity()..rotateY(math.pi),
                    alignment: Alignment.center,
                    child: widget.back,
                  )
                : widget.front,
          );
        },
      ),
    );
  }
}

class ProfileContent extends StatelessWidget {
  const ProfileContent({
    super.key,
    required this.profile,
    this.registration,
    this.avatarFile,
  });

  final User profile;
  final UserRegistration? registration;
  final File? avatarFile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = GoogleFonts.notoSansTcTextTheme(theme.textTheme);

    return _ProfileCardFrame(
      childBuilder: (context, constraints, borderRadius) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final avatarSize = height * 0.59;
        // TODO: improve name display for non-Chinese names; revisit when adding i18n
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
                  registration?.enrollmentStatus?.toLabel() ??
                      t.general.student,
                  textAlign: TextAlign.left,
                  style: textTheme.bodyMedium?.copyWith(
                    color: Color(0xFF3B3B3B),
                    fontSize: height * 0.07,
                    fontWeight: FontWeight.w600,
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
                      textTheme.titleMedium?.copyWith(
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
                          profile.nameZh.isNotEmpty
                              ? profile.nameZh
                              : t.general.unknown,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontSize: height * 0.11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 4,
                            height: 1.6,
                          ),
                        ),
                      ),
                      Text(
                        profile.departmentZh ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        profile.studentId,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        registration != null
                            ? '${registration!.year}-${registration!.term} ${registration!.className ?? ''}'
                            : '',
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
                      child: switch (avatarFile) {
                        final file? => Image.file(file, fit: BoxFit.cover),
                        null => Center(
                          child: Text(
                            avatarInitial,
                            style: TextStyle(
                              color: const Color(0xFF808080),
                              fontWeight: FontWeight.w700,
                              fontSize: avatarSize * 0.36,
                            ),
                          ),
                        ),
                      },
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

class ProfileBackContent extends StatelessWidget {
  const ProfileBackContent({super.key, required this.profile});

  final User profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = GoogleFonts.notoSansTcTextTheme(theme.textTheme);

    return _ProfileCardFrame(
      childBuilder: (context, constraints, borderRadius) {
        final height = constraints.maxHeight;
        final width = constraints.maxWidth;

        //TODO: design is not determind yet, just put some info here for now and will polish later when design is ready
        return ClipRRect(
          borderRadius: borderRadius,
          child: Stack(
            children: [
              // Faint T logo in bottom right
              Positioned(
                right: height * 0.08,
                bottom: height * 0.08,
                child: Opacity(
                  opacity: 0.2,
                  child: SvgPicture.asset(
                    'assets/tat_icon.svg',
                    height: height * 0.25,
                    colorFilter: const ColorFilter.mode(
                      Colors.black,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),

              // Centered Information
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: width * 0.06),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        (profile.nameEn?.isNotEmpty == true
                                ? profile.nameEn!
                                : profile.nameZh)
                            .toUpperCase(),
                        textAlign: TextAlign.center,
                        style: textTheme.titleLarge?.copyWith(
                          color: const Color(0xFF222222),
                          fontSize: height * 0.085,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                        ),
                      ),
                      SizedBox(height: height * 0.03),
                      Text(
                        profile.departmentEn ?? profile.departmentZh ?? '',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF777777),
                          fontSize: height * 0.045,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: height * 0.08),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: width * 0.04,
                          vertical: height * 0.02,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFFB0B0B0),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(height * 0.025),
                        ),
                        child: Text(
                          profile.email,
                          style: textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF5A758E),
                            fontSize: height * 0.05,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
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
