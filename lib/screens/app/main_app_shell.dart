import 'package:material_ui/material_ui.dart';
import '../../core/theme/app_colors.dart';
import '../../state/aqua_ui_controller.dart';
import '../../widgets/common/aqua_bottom_tab_bar.dart';
import '../../widgets/scanner/aqua_qr_scanner_sheet.dart';
import 'focus_stats_tab_screen.dart';
import 'home_tab_screen.dart';
import 'kids_tab_screen.dart';
import 'map_tab_screen.dart';
import 'profile_tab_screen.dart';
import 'quality_tab_screen.dart';

/// Role-adaptive App Shell:
/// - `AquaRole.kids`: Fullscreen Kid-Locked space (adult tabs hidden behind Parent Gate).
/// - `AquaRole.studentWorker`: [Trang chủ, Sống xanh, Quét mã (Modal Camera), Trạm nước, Cá nhân].
/// - `AquaRole.household`: [Gia đình, Nước & vệ sinh, Quét mã (Modal Camera), Trạm & Sự cố, Cá nhân].
class MainAppShell extends StatelessWidget {
  const MainAppShell({super.key, required this.controller});

  final AquaUiController controller;

  void _openUniversalScanner(BuildContext context) {
    final isHousehold = controller.role == AquaRole.household;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AquaQrScannerSheet(
        title: isHousehold
            ? 'Quét mã nguồn nước, que thử hoặc chai nước'
            : 'Quét mã vạch chai nước hoặc QR trạm Refill',
        subtitle: isHousehold
            ? 'Hướng camera vào mã QR kiểm định nước, tem bộ lọc hoặc mã vạch nước đóng chai.'
            : 'Hướng camera vào mã vạch chai La Vie, Aquafina... hoặc mã QR tại trạm tiếp nước.',
        confirmButtonLabel: 'Xác nhận kết quả ✓',
        accentColor: isHousehold ? AppColors.oceanBlue : AppColors.skyCyan,
        onResultConfirmed: (result) {
          final msg = controller.applyScannedCodeResult(result);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(msg)),
            );
          }
        },
        onConfirmed: (rawCode) {
          controller.addScannedDrink(
            rawMl: 350,
            drinkLabel: 'Mã $rawCode',
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (controller.role == AquaRole.kids) {
      return Scaffold(
        backgroundColor: AppColors.kidsCream,
        body: KidsTabScreen(controller: controller),
      );
    }

    final safeTabIndex =
        controller.activeTabIndex == 2 ? 0 : controller.activeTabIndex.clamp(0, 4);
    final isStudent = controller.role == AquaRole.studentWorker;

    return Scaffold(
      body: TweenAnimationBuilder<double>(
        key: ValueKey<String>('${controller.role.name}_$safeTabIndex'),
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        builder: (_, t, child) {
          return Opacity(
            opacity: (0.76 + 0.24 * t).clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, (1.0 - t) * 8),
              child: child,
            ),
          );
        },
        child: IndexedStack(
          index: safeTabIndex,
          children: [
            HomeTabScreen(controller: controller),
            isStudent
                ? FocusStatsTabScreen(controller: controller)
                : QualityTabScreen(controller: controller),
            const SizedBox.shrink(),
            MapTabScreen(controller: controller),
            ProfileTabScreen(controller: controller),
          ],
        ),
      ),
      bottomNavigationBar: AquaBottomTabBar(
        role: controller.role,
        activeIndex: safeTabIndex,
        onSelectTab: controller.setActiveTab,
        onCenterScanTap: () => _openUniversalScanner(context),
      ),
    );
  }
}
