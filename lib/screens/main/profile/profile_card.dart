import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tattoo/components/app_skeleton.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/models/user.dart';
import 'package:tattoo/screens/main/profile/profile_providers.dart';
import 'package:tattoo/screens/main/user_providers.dart';

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

      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: switch ((profileAsync, registrationAsync)) {
          // NOT_LOGIN state: not logged in
          (AsyncData(value: null), _) => _ProfileCardFrame(
            child: Center(child: Text(t.general.notLoggedIn)),
          ),

          // ERROR state: show error message on card
          (AsyncError(:final error), _) ||
          (_, AsyncError(:final error)) => _ProfileCardFrame(
            child: Center(child: Text('Error: $error')),
          ),

          // DATA state: show profile content (even if refreshing)
          (
            AsyncValue(value: final profile, hasValue: true),
            AsyncValue(value: final registration, hasValue: true),
          )
              when profile != null =>
            _ProfileCardPager(
              profile: profile,
              registration: registration,
              avatarFile: avatarAsync.value,
            ),

          // LOADING state: show skeleton
          _ => const AppSkeleton(
            child: _ProfileCardFront(
              profile: _placeholderProfile,
              registration: _placeholderSemester,
            ),
          ),
        },
      ),
    );
  }
}

class _ProfileCardPager extends StatefulWidget {
  const _ProfileCardPager({
    required this.profile,
    this.registration,
    this.avatarFile,
  });

  final User profile;
  final UserRegistration? registration;
  final File? avatarFile;

  @override
  State<_ProfileCardPager> createState() => _ProfileCardPagerState();
}

class _ProfileCardPagerState extends State<_ProfileCardPager> {
  PageController? _pageController;
  static const double _spacing = 32.0;
  double? _lastWidth;

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // Total horizontal padding is 16 + 16 = 32
        final cardWidth = width - _spacing;
        // Height should match the card's aspect ratio based on its actual width
        final height = cardWidth * (638 / 1016);

        // Re-initialize controller only if width changes
        if (_pageController == null || _lastWidth != width) {
          _pageController?.dispose();
          _pageController = PageController(
            viewportFraction: 1.0,
          );
          _lastWidth = width;
        }

        return SizedBox(
          height: height,
          child: PageView(
            controller: _pageController,
            clipBehavior: Clip.none,
            allowImplicitScrolling: true,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: _spacing / 2),
                child: _ProfileCardFront(
                  profile: widget.profile,
                  registration: widget.registration,
                  avatarFile: widget.avatarFile,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: _spacing / 2),
                child: _ProfileCardBack(
                  profile: widget.profile,
                  isGlassy: true,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileCardFront extends StatelessWidget {
  const _ProfileCardFront({
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
                    color: const Color(0xFF3B3B3B),
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

class _ProfileCardBack extends StatelessWidget {
  const _ProfileCardBack({required this.profile, this.isGlassy = false});

  final User profile;
  final bool isGlassy;

  @override
  Widget build(BuildContext context) {
    return _ProfileCardFrame(
      isGlassy: isGlassy,
      childBuilder: (context, constraints, borderRadius) {
        final height = constraints.maxHeight;
        final padding = height * 0.1;

        return Padding(
          padding: EdgeInsets.all(padding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left: QR Code
              Expanded(
                flex: 4,
                child: Center(
                  child: Theme(
                    data: ThemeData(
                      // Make sure QR and its background fit the glass theme
                      colorScheme: ColorScheme.fromSeed(
                        seedColor: Colors.white,
                        brightness: Brightness.dark,
                      ),
                    ),
                    child: QrImageView(
                      data: profile.studentId,
                      version: QrVersions.auto,
                      size: height * 0.45,
                      // White-on-transparent look for glassmorphism
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Colors.white,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Colors.white,
                      ),
                      gapless: false,
                    ),
                  ),
                ),
              ),
              // Divider
              Container(
                width: 1,
                margin: EdgeInsets.symmetric(horizontal: padding * 0.5),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0),
                      Colors.white.withValues(alpha: 0.3),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
              // Right: Personal Details (from card image inspiration)
              Expanded(
                flex: 5,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.nameZh,
                      style: GoogleFonts.outfit(
                        fontSize: height * 0.12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      t.general.student,
                      style: GoogleFonts.outfit(
                        fontSize: height * 0.05,
                        fontWeight: FontWeight.w300,
                        color: Colors.white.withValues(alpha: 0.8),
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: height * 0.1),
                    _BusinessDetailItem(
                      icon: Icons.badge_outlined,
                      text: profile.studentId,
                      height: height,
                    ),
                    _BusinessDetailItem(
                      icon: Icons.email_outlined,
                      text: profile.email,
                      height: height,
                    ),
                    if (profile.departmentZh case final dept?)
                      _BusinessDetailItem(
                        icon: Icons.school_outlined,
                        text: dept,
                        height: height,
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BusinessDetailItem extends StatelessWidget {
  const _BusinessDetailItem({
    required this.icon,
    required this.text,
    required this.height,
  });

  final IconData icon;
  final String text;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: height * 0.015),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: height * 0.045,
            color: Colors.white.withValues(alpha: 0.6),
          ),
          SizedBox(width: height * 0.03),
          Flexible(
            child: Text(
              text,
              style: GoogleFonts.outfit(
                fontSize: height * 0.035,
                fontWeight: FontWeight.w300,
                color: Colors.white.withValues(alpha: 0.9),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCardFrame extends StatelessWidget {
  const _ProfileCardFrame({
    this.childBuilder,
    this.child,
    this.isGlassy = false,
  });

  final Widget Function(
    BuildContext context,
    BoxConstraints constraints,
    BorderRadius borderRadius,
  )?
  childBuilder;
  final Widget? child;
  final bool isGlassy;

  @override
  Widget build(BuildContext context) {
    // Standard ID card aspect ratio
    return AspectRatio(
      aspectRatio: 1016 / 638,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final height = constraints.maxHeight;
          final borderRadius = BorderRadius.circular(
            height * _profileCardRadiusFactor,
          );

          return Stack(
            children: [
              if (isGlassy) ...[
                // Colorful Glass backdrop with blur
                ClipRRect(
                  borderRadius: borderRadius,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: borderRadius,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(
                              0xFF64748B,
                            ).withValues(alpha: 0.5), // Lighter Slate
                            const Color(
                              0xFF1E293B,
                            ).withValues(alpha: 0.6), // Deep Slate
                            const Color(
                              0xFF334155,
                            ).withValues(alpha: 0.4), // Mid Slate
                          ],
                          stops: const [0.0, 0.6, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
                // Soft radial glow in top-left
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: borderRadius,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.topLeft,
                          radius: 1.5,
                          colors: [
                            Colors.white.withValues(alpha: 0.2),
                            Colors.white.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Diagonal Shimmer Highlight
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: borderRadius,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: const Alignment(-1.2, -1.2),
                          end: const Alignment(1.2, 1.2),
                          colors: [
                            Colors.white.withValues(alpha: 0),
                            Colors.white.withValues(alpha: 0.05),
                            Colors.white.withValues(alpha: 0.2),
                            Colors.white.withValues(alpha: 0.05),
                            Colors.white.withValues(alpha: 0),
                          ],
                          stops: const [0.0, 0.2, 0.45, 0.7, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
                // Edge Highlight (Reflection)
                Positioned(
                  top: 0,
                  left: height * 0.1,
                  right: height * 0.1,
                  child: Container(
                    height: 1.5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0),
                          Colors.white.withValues(alpha: 0.6),
                          Colors.white.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ] else
                // Original solid look
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: _profileCardBackgroundColor,
                    borderRadius: borderRadius,
                    boxShadow: const [_profileCardShadow],
                  ),
                  child: const SizedBox.expand(),
                ),

              // Glass version shadow (since BackdropFilter doesn't handle shadows well)
              if (isGlassy)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: borderRadius,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 20,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),

              // Content
              child ?? childBuilder!(context, constraints, borderRadius),
            ],
          );
        },
      ),
    );
  }
}
