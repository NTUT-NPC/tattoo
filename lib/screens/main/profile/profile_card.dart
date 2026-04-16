import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:barcode_widget/barcode_widget.dart';
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
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dummy to determine height based on aspect ratio
        const IgnorePointer(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: AspectRatio(
              aspectRatio: 1016 / 638,
              child: SizedBox.expand(),
            ),
          ),
        ),
        // Actual pager (full-width to allow shadow bleed)
        Positioned.fill(
          child: PageView(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            clipBehavior: Clip.none,
            allowImplicitScrolling: false,
            children: [
              RepaintBoundary(
                child: _ProfileCardFront(
                  profile: widget.profile,
                  registration: widget.registration,
                  avatarFile: widget.avatarFile,
                ),
              ),
              RepaintBoundary(
                child: _ProfileCardBack(
                  profile: widget.profile,
                  isGlassy: true,
                ),
              ),
              RepaintBoundary(
                child: _ProfileCardBarcode(
                  profile: widget.profile,
                  isGlassy: true,
                ),
              ),
            ],
          ),
        ),
      ],
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
                        final file? => Image.file(
                          file,
                          fit: BoxFit.cover,
                          // 進階優化：限制快取大小以節省記憶體，avatarSize 是邏輯像素
                          cacheWidth:
                              (avatarSize *
                                      MediaQuery.of(context).devicePixelRatio)
                                  .toInt(),
                          cacheHeight:
                              (avatarSize *
                                      MediaQuery.of(context).devicePixelRatio)
                                  .toInt(),
                        ),
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
              // 左側：QR Code 區域 (通常用於學號或其他身分驗證)
              Expanded(
                flex: 4,
                child: Center(
                  child: Theme(
                    data: ThemeData(
                      // 確保 QR Code 在磨砂玻璃主題下有正確的對比度
                      colorScheme: ColorScheme.fromSeed(
                        seedColor: Colors.white,
                        brightness: Brightness.dark,
                      ),
                    ),
                    child: QrImageView(
                      data: profile.studentId,
                      version: QrVersions.auto,
                      size: height * 0.45,
                      // 使用白色與透明的樣式，以契合玻璃感
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
              // 中央分隔線：帶有漸變消失效果的垂直線
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
              // 右側：個人詳細資訊 (仿商務名片風格)
              Expanded(
                flex: 5,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.nameZh,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: height * 0.12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      t.general.student,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: height * 0.05,
                        fontWeight: FontWeight.w300,
                        color: Colors.white.withValues(alpha: 0.8),
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: height * 0.1),
                    // 詳細資訊欄位 (學號, Email, 系所)
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

class _ProfileCardBarcode extends StatelessWidget {
  const _ProfileCardBarcode({required this.profile, this.isGlassy = false});

  final User profile;
  final bool isGlassy;

  @override
  Widget build(BuildContext context) {
    return _ProfileCardFrame(
      isGlassy: isGlassy,
      childBuilder: (context, constraints, borderRadius) {
        final height = constraints.maxHeight;
        final padding = height * 0.12;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(height * 0.04),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(height * 0.03),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: height * 0.02,
                  children: [
                    SizedBox(
                      height: height * 0.18,
                      child: BarcodeWidget(
                        barcode: Barcode.code39(),
                        data: profile.studentId,
                        width: double.infinity,
                        drawText: false,
                      ),
                    ),
                    Text(
                      profile.studentId,
                      style: GoogleFonts.outfit(
                        fontSize: height * 0.05,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
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

class _ProfileCardFrame extends StatefulWidget {
  const _ProfileCardFrame({
    this.childBuilder,
    this.child,
    this.isGlassy = false,
  }) : assert(
         (child == null) != (childBuilder == null),
         'Exactly one of child or childBuilder must be provided',
       );

  final Widget Function(
    BuildContext context,
    BoxConstraints constraints,
    BorderRadius borderRadius,
  )?
  childBuilder;
  final Widget? child;
  final bool isGlassy;

  @override
  State<_ProfileCardFrame> createState() => _ProfileCardFrameState();
}

class _ProfileCardFrameState extends State<_ProfileCardFrame> {
  // 用於追蹤點光源的位置 (Offset.zero 代表中心)
  late final ValueNotifier<Offset> _lightPositionNotifier = ValueNotifier(
    const Offset(-0.8, -0.8),
  );
  late final ValueNotifier<bool> _isTouchingNotifier = ValueNotifier(false);

  @override
  void dispose() {
    _lightPositionNotifier.dispose();
    _isTouchingNotifier.dispose();
    super.dispose();
  }

  void _updateLightPosition(PointerEvent event, BoxConstraints constraints) {
    if (!widget.isGlassy) return;
    // 直接更新 ValueNotifier 而非 setState，避免整張卡片與內容重複建構
    _lightPositionNotifier.value = Offset(
      (event.localPosition.dx / constraints.maxWidth) * 2 - 1,
      (event.localPosition.dy / constraints.maxHeight) * 2 - 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    // 身份證標準寬高比
    // 使用 Padding(horizontal: 16.0) 確保內容縮放同時留出陰影顯示空間
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: AspectRatio(
        aspectRatio: 1016 / 638,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final height = constraints.maxHeight;
            final borderRadius = BorderRadius.circular(
              height * _profileCardRadiusFactor,
            );

            return Listener(
              onPointerDown: (event) {
                _isTouchingNotifier.value = true;
                _updateLightPosition(event, constraints);
              },
              onPointerMove: (event) =>
                  _updateLightPosition(event, constraints),
              onPointerUp: (_) => _isTouchingNotifier.value = false,
              onPointerCancel: (_) => _isTouchingNotifier.value = false,
              child: Stack(
                children: [
                  if (widget.isGlassy) ...[
                    // 1. 底層流動色味 (背景) - 獨立的動畫圖層，避免觸發上方靜態元件重繪
                    Positioned.fill(
                      child: RepaintBoundary(
                        child: ClipRRect(
                          borderRadius: borderRadius,
                          child: ImageFiltered(
                            imageFilter: ImageFilter.blur(
                              sigmaX: 20.0,
                              sigmaY: 20.0,
                            ),
                            child: const _FlowingBlobs(),
                          ),
                        ),
                      ),
                    ),
                    // 2 & 3 & 5 & 6. 靜態玻璃質感層 (基底、邊框、角落掃光、頂部反光)
                    // 將這些不隨時間變化的元件封裝在同一個 RepaintBoundary 中，僅在尺寸改變時重新繪製
                    Positioned.fill(
                      child: RepaintBoundary(
                        child: Stack(
                          children: [
                            // 2. 磨砂玻璃基底
                            ClipRRect(
                              borderRadius: borderRadius,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: borderRadius,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    width: 0.5,
                                  ),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      const Color(0xFF64748B).withValues(
                                        alpha: 0.35,
                                      ),
                                      const Color(0xFF1E293B).withValues(
                                        alpha: 0.45,
                                      ),
                                      const Color(0xFF334155).withValues(
                                        alpha: 0.25,
                                      ),
                                    ],
                                    stops: const [0.0, 0.6, 1.0],
                                  ),
                                ),
                              ),
                            ),
                            // 3. 多層級物理邊框 (折射與反射)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: CustomPaint(
                                  painter: _RefractiveBorderPainter(
                                    borderRadius: borderRadius,
                                  ),
                                ),
                              ),
                            ),
                            // 5. 靜態角落掃光 (增強材質感)
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
                            // 6. 卡片頂部反光線
                            Positioned(
                              top: 0,
                              left: height * 0.1,
                              right: height * 0.1,
                              child: Container(
                                height: 1.5,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0x00FFFFFF),
                                      Color(0x99FFFFFF),
                                      Color(0x00FFFFFF),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // 4. 指尖點光源追蹤層 (動態互動核心) - 獨立圖層確保互動流暢
                    Positioned.fill(
                      child: IgnorePointer(
                        child: RepaintBoundary(
                          child: ValueListenableBuilder<Offset>(
                            valueListenable: _lightPositionNotifier,
                            builder: (context, lightPos, child) {
                              return ValueListenableBuilder<bool>(
                                valueListenable: _isTouchingNotifier,
                                builder: (context, isTouching, child) {
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeOutCubic,
                                    decoration: BoxDecoration(
                                      borderRadius: borderRadius,
                                      gradient: RadialGradient(
                                        center: Alignment(
                                          lightPos.dx,
                                          lightPos.dy,
                                        ),
                                        radius: 1.0,
                                        colors: [
                                          Colors.white.withValues(
                                            alpha: isTouching ? 0.25 : 0.15,
                                          ),
                                          Colors.white.withValues(alpha: 0),
                                        ],
                                        stops: const [0.0, 1.0],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ] else
                    // 普通卡片樣式
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: _profileCardBackgroundColor,
                        borderRadius: borderRadius,
                        boxShadow: const [_profileCardShadow],
                      ),
                      child: const SizedBox.expand(),
                    ),

                  // 玻璃版陰影
                  if (widget.isGlassy)
                    Positioned.fill(
                      child: IgnorePointer(
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
                    ),

                  // 內容區域 - 獨立圖層避免背景動畫觸發內容重繪
                  RepaintBoundary(
                    child:
                        widget.child ??
                        widget.childBuilder!(
                          context,
                          constraints,
                          borderRadius,
                        ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FlowingBlobs extends StatefulWidget {
  const _FlowingBlobs();

  @override
  State<_FlowingBlobs> createState() => _FlowingBlobsState();
}

class _FlowingBlobsState extends State<_FlowingBlobs>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _BlobsPainter(progress: _controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

/// 繪製在背景緩緩移動的彩色球體，建立流動感的視覺效果
class _BlobsPainter extends CustomPainter {
  _BlobsPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // 球體 1：活力的湖水藍 (Teal/Azure) - 圓周軌道運動
    final t1 = progress * 2 * math.pi;
    final x1 = size.width * (0.3 + 0.2 * math.cos(t1));
    final y1 = size.height * (0.4 + 0.2 * math.sin(t1));
    paint.color = const Color(0xFF22D3EE).withValues(alpha: 0.35);
    canvas.drawCircle(Offset(x1, y1), size.height * 0.5, paint);

    // 球體 2：深邃的靛藍 (Indigo/Purple) - 雙倍速 8 字型軌道運動
    final t2 = (progress + 0.33) * 2 * math.pi;
    final x2 = size.width * (0.7 + 0.2 * math.sin(t2));
    final y2 =
        size.height * (0.6 + 0.2 * math.cos(t2 * 2.0)); // 使用整數倍率確保動畫循環無跳變
    paint.color = const Color(0xFF6366F1).withValues(alpha: 0.3);
    canvas.drawCircle(Offset(x2, y2), size.height * 0.6, paint);

    // 球體 3：柔和的櫻花粉 (Soft Amber/Pink) - 變速波動運動
    final t3 = (progress + 0.66) * 2 * math.pi;
    final x3 = size.width * (0.5 + 0.25 * math.cos(t3));
    final y3 = size.height * (0.2 + 0.2 * math.sin(t3 * 2.0));
    paint.color = const Color(0xFFF472B6).withValues(alpha: 0.25);
    canvas.drawCircle(Offset(x3, y3), size.height * 0.4, paint);
  }

  @override
  bool shouldRepaint(_BlobsPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// 負責繪製玻璃卡片邊緣的物理特徵，包括環境溢光 (Bloom)、核心折射線與內部二次反射
class _RefractiveBorderPainter extends CustomPainter {
  _RefractiveBorderPainter({required this.borderRadius});

  final BorderRadius borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect);

    // 1. 環境溢光 (Bloom)：建立邊緣發光的層次感，讓卡片更融入白色背景
    final bloomPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

    bloomPaint.shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withValues(alpha: 0.15),
        Colors.white.withValues(alpha: 0.0),
        Colors.white.withValues(alpha: 0.1),
        Colors.white.withValues(alpha: 0.0),
      ],
    ).createShader(rect);
    canvas.drawRRect(rrect, bloomPaint);

    // 2. 核心折射邊緣 (High-intensity Refractive edge)：模擬玻璃在邊界對光線的強烈捕捉
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // 多節點漸變以模擬光線在不同角度的強弱變化
    paint.shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withValues(alpha: 0.9), // 左上角高光
        Colors.white.withValues(alpha: 0.15), // 上緣中段
        Colors.white.withValues(alpha: 0.6), // 右中段反光
        Colors.white.withValues(alpha: 0.1), // 右下角陰影區
        Colors.white.withValues(alpha: 0.5), // 下緣光暈
      ],
      stops: const [0.0, 0.3, 0.5, 0.8, 1.0],
    ).createShader(rect);

    canvas.drawRRect(rrect, paint);

    // 3. 內部二次反射線：模擬玻璃厚度產生的內部光影
    final innerHighlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    innerHighlightPaint.shader = LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [
        Colors.white.withValues(alpha: 0.0),
        Colors.white.withValues(alpha: 0.4),
        Colors.white.withValues(alpha: 0.0),
      ],
    ).createShader(rect);

    // 稍微向內縮排，模擬玻璃內壁的反光
    canvas.drawRRect(rrect.deflate(1.2), innerHighlightPaint);
  }

  @override
  bool shouldRepaint(_RefractiveBorderPainter oldDelegate) =>
      oldDelegate.borderRadius != borderRadius;
}
