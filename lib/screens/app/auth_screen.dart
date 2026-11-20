import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../state/aqua_ui_controller.dart';
import '../../widgets/animations/aqua_motion.dart';
import '../../widgets/mascot/aqua_mascot_catalog.dart';

/// Clean Waterllama-inspired Login / Sign-up screen with borderless pastel cards & pill CTAs.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.controller});

  final AquaUiController controller;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isRegister = false;
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _errorBanner;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _passwordCtrl;
  final TextEditingController _otpCtrl = TextEditingController(text: '4829');

  @override
  void initState() {
    super.initState();
    final isTest = AquaMotion.isTestEnvironment;
    _nameCtrl = TextEditingController(text: isTest ? 'Minh Nguyễn' : '');
    _emailCtrl = TextEditingController(
      text: isTest ? 'minhnguyen@aquacare.vn' : '',
    );
    _passwordCtrl = TextEditingController(text: isTest ? 'AquaCare@2026' : '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitAuth({required bool isNewUser}) async {
    if (_isSubmitting) return;

    if (!AquaMotion.isTestEnvironment) {
      if (_emailCtrl.text.trim().isEmpty || _passwordCtrl.text.isEmpty) {
        setState(() {
          _errorBanner = 'Vui lòng nhập email và mật khẩu, hoặc tiếp tục thiết lập hồ sơ mới bên dưới.';
        });
        return;
      }
      if (isNewUser && _nameCtrl.text.trim().isEmpty) {
        setState(() {
          _errorBanner = 'Vui lòng nhập họ và tên để tạo hồ sơ mới.';
        });
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
      _errorBanner = null;
    });

    final cloud = widget.controller.cloudSync;
    final res = isNewUser
        ? await cloud.registerWithEmail(
            email: _emailCtrl.text,
            password: _passwordCtrl.text,
            displayName: _nameCtrl.text,
          )
        : await cloud.signInWithEmail(
            email: _emailCtrl.text,
            password: _passwordCtrl.text,
            fallbackName: _nameCtrl.text,
          );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (!res.success) {
      setState(() => _errorBanner = res.errorMessage);
      return;
    }

    widget.controller.completeAuth(
      isNewUser: isNewUser,
      userName: res.displayName ?? _nameCtrl.text,
      uid: res.uid,
      isCloudAccount: res.isCloudAccount,
    );
  }

  Future<void> _submitGoogle() async {
    if (_isSubmitting) return;
    setState(() {
      _isSubmitting = true;
      _errorBanner = null;
    });
    final res = await widget.controller.cloudSync.signInWithGoogle(
      fallbackName: _nameCtrl.text.trim().isEmpty
          ? 'Người dùng Google'
          : _nameCtrl.text,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (!res.success) {
      setState(() => _errorBanner = res.errorMessage);
      return;
    }
    widget.controller.completeAuth(
      isNewUser: true,
      userName: res.displayName ?? _nameCtrl.text,
      uid: res.uid,
      isCloudAccount: res.isCloudAccount,
    );
  }

  void _openOtpSheet({required bool isNewUser}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final padded = _otpCtrl.text.padRight(4, ' ');
            final targetMail = _emailCtrl.text.trim().isEmpty
                ? 'email của bạn'
                : _emailCtrl.text.trim();
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                16,
                24,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.homeIndicator,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Xác thực mã OTP', style: AppTypography.pageTitle()),
                  const SizedBox(height: 6),
                  Text(
                    'Nhập mã 4 chữ số đã gửi tới $targetMail',
                    style: AppTypography.cardBody(),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(4, (i) {
                      final ch = padded[i].trim();
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 56,
                        height: 58,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.pastelMist,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: ch.isNotEmpty
                                ? AppColors.deepSky
                                : AppColors.cardBorder,
                            width: 1.6,
                          ),
                        ),
                        child: Text(
                          ch.isEmpty ? '•' : ch,
                          style: AppTypography.pageTitle().copyWith(
                            fontSize: 22,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _otpCtrl,
                    maxLength: 4,
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      widget.controller.setOtpCode(v);
                      setSheetState(() {});
                    },
                    decoration: const InputDecoration(
                      labelText: 'Mã OTP 4 chữ số',
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.skyCyan,
                        foregroundColor: AppColors.pureWhite,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _submitAuth(isNewUser: isNewUser);
                      },
                      child: Text(
                        'Xác nhận & tiếp tục',
                        style: AppTypography.ctaLabel(AppColors.pureWhite),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCloudConfigured = widget.controller.isFirebaseConfigured;
    return Scaffold(
      backgroundColor: AppColors.iceCanvas,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - 50).clamp(
                    0.0,
                    double.infinity,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              StaggeredEntrance(
                index: 0,
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: AppColors.cyanTile,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: AquaMascotVectorArt(
                          mascotId: 'giot_nuoc',
                          size: 38,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chào mừng đến AquaCare',
                            style: AppTypography.pageTitle().copyWith(
                              fontSize: 21,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Trợ lý cấp nước cá nhân & chăm sóc nước gia đình',
                            style: AppTypography.cardBody(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isCloudConfigured
                          ? AppColors.mintTile
                          : AppColors.cyanTile,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isCloudConfigured
                              ? Icons.cloud_done_rounded
                              : Icons.verified_user_outlined,
                          size: 15,
                          color: isCloudConfigured
                              ? AppColors.emerald
                              : AppColors.oceanBlue,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            isCloudConfigured
                                ? 'Đồng bộ đám mây đã sẵn sàng'
                                : 'Lưu trữ an toàn trên thiết bị',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.metricLabel(
                              isCloudConfigured
                                  ? AppColors.emerald
                                  : AppColors.oceanBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.controller.hasCompletedInitialSetup ||
                      widget.controller.genderProfile != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.mintTile,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.water_drop_rounded,
                            size: 14,
                            color: AppColors.emerald,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              '${widget.controller.role.label} • ${widget.controller.role == AquaRole.kids ? '${widget.controller.kidsGoalCups} cốc/ngày' : '${widget.controller.dailyGoalMl} ml/ngày'} ✓',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.metricLabel(
                                AppColors.emerald,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              StaggeredEntrance(
                index: 1,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: AppColors.pureWhite,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A0F1F2C),
                        blurRadius: 14,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _AuthTabButton(
                        label: 'Đăng nhập',
                        selected: !_isRegister,
                        onTap: () => setState(() {
                          _isRegister = false;
                          _errorBanner = null;
                        }),
                      ),
                      _AuthTabButton(
                        label: 'Đăng ký mới',
                        selected: _isRegister,
                        onTap: () => setState(() {
                          _isRegister = true;
                          _errorBanner = null;
                        }),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: _errorBanner == null
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.coralTile,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                size: 18,
                                color: AppColors.softCoral,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorBanner!,
                                  style: AppTypography.cardBody(
                                    color: AppColors.navyInk,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
              StaggeredEntrance(
                index: 2,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.pureWhite,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0C0F1F2C),
                        blurRadius: 20,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isRegister) ...[
                          TextField(
                            controller: _nameCtrl,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Họ và tên',
                              hintText: 'VD: Minh Nguyễn',
                              prefixIcon: Icon(Icons.person_outline, size: 19),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        TextField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email hoặc số điện thoại',
                            hintText: 'VD: ban@gmail.com',
                            prefixIcon: Icon(Icons.alternate_email, size: 19),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _passwordCtrl,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Mật khẩu',
                            hintText: 'Tối thiểu 6 ký tự',
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              size: 19,
                            ),
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 19,
                              ),
                            ),
                          ),
                        ),
                        if (!_isRegister)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => _openOtpSheet(isNewUser: false),
                              child: const Text('Quên mật khẩu?'),
                            ),
                          )
                        else
                          const SizedBox(height: 16),
                        BouncyPressable(
                          child: SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.cyanVivid,
                                foregroundColor: AppColors.pureWhite,
                                shape: const StadiumBorder(),
                                elevation: 0,
                              ),
                              onPressed: _isSubmitting
                                  ? null
                                  : () {
                                      if (_isRegister) {
                                        _openOtpSheet(isNewUser: true);
                                      } else {
                                        _submitAuth(isNewUser: false);
                                      }
                                    },
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: AppColors.pureWhite,
                                      ),
                                    )
                                  : Text(
                                      _isRegister
                                          ? 'Gửi mã xác thực OTP'
                                          : 'Đăng nhập ngay',
                                      style: AppTypography.pillCta(),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: Text(
                  'Hoặc tiếp tục nhanh',
                  style: AppTypography.sectionCaption(
                    color: AppColors.mutedGrey,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              BouncyPressable(
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.pureWhite,
                      foregroundColor: AppColors.navyInk,
                      shape: const StadiumBorder(),
                      elevation: 0,
                    ),
                    onPressed: _submitGoogle,
                    icon: const Icon(
                      Icons.g_mobiledata_rounded,
                      size: 26,
                      color: AppColors.oceanBlue,
                    ),
                    label: const Text(
                      'Tiếp tục bằng tài khoản Google',
                      style: TextStyle(
                        fontFamily: AppTypography.bodyFont,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () {
                    if (widget.controller.hasCompletedInitialSetup) {
                      widget.controller.completeSetup();
                    } else {
                      widget.controller.setStage(AppFlowStage.setup);
                    }
                  },
                  child: Text(
                    'Tiếp tục không cần đăng nhập →',
                    textAlign: TextAlign.center,
                    style: AppTypography.rowTitle(color: AppColors.oceanBlue),
                  ),
                ),
              ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AuthTabButton extends StatelessWidget {
  const _AuthTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 11),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.cyanVivid : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: AppTypography.rowTitle(
              color: selected ? AppColors.pureWhite : AppColors.mutedGrey,
            ),
          ),
        ),
      ),
    );
  }
}
