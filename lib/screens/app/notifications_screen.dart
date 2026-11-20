import 'package:material_ui/material_ui.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../state/aqua_ui_controller.dart';
import '../../widgets/animations/aqua_motion.dart';
import '../../widgets/interactive/interactive_panel.dart';

class _NotifItem {
  const _NotifItem({
    required this.category,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.accent,
    required this.icon,
    required this.targetTab,
    this.entersKidsMode = false,
  });

  final int category;
  final String title;
  final String subtitle;
  final String time;
  final Color accent;
  final IconData icon;
  final int targetTab;
  final bool entersKidsMode;
}

/// Role-aware Notification Center with unified Vietnamese Sentence case & smooth transitions.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, required this.controller});

  final AquaUiController controller;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _filter = 0;

  List<_NotifItem> _buildItemsForRole(AquaUiController c) {
    if (c.role == AquaRole.studentWorker) {
      return const [
        _NotifItem(
          category: 1,
          title: 'Nhắc uống nước ca chiều (15:30)',
          subtitle: 'Uống thêm 250 ml nước lọc để duy trì nhịp cấp ẩm hôm nay.',
          time: '45 phút trước',
          accent: AppColors.skyCyan,
          icon: Icons.water_drop_rounded,
          targetTab: 0,
        ),
        _NotifItem(
          category: 2,
          title: 'Nhắc vệ sinh bình cá nhân & sống xanh (WASH)',
          subtitle:
              'Rửa bình nước cá nhân mỗi ngày bằng nước ấm & xà phòng và ưu tiên Refill giảm rác nhựa.',
          time: '1 giờ trước',
          accent: AppColors.emerald,
          icon: Icons.clean_hands_rounded,
          targetTab: 1,
        ),
        _NotifItem(
          category: 3,
          title: 'Cập nhật trạm Refill Thư viện Thành phố',
          subtitle: 'Chỉ số TDS vừa kiểm định lại: 28 ppm (rất tốt • miễn phí).',
          time: 'Hôm qua',
          accent: AppColors.freshMint,
          icon: Icons.location_on_rounded,
          targetTab: 3,
        ),
      ];
    }

    return [
      const _NotifItem(
        category: 2,
        title: 'Bộ lọc thô cấp 1 còn 15%',
        subtitle:
            'Nên vệ sinh hoặc thay mới định kỳ để bảo đảm nước sạch theo chuẩn WHO/QCVN.',
        time: '15 phút trước',
        accent: AppColors.softCoral,
        icon: Icons.warning_amber_rounded,
        targetTab: 1,
      ),
      const _NotifItem(
        category: 1,
        title: 'Nhắc uống nước gia đình (15:30)',
        subtitle: 'Cả nhà nhớ bổ sung thêm nước lọc sạch vào buổi chiều nhé.',
        time: '45 phút trước',
        accent: AppColors.skyCyan,
        icon: Icons.water_drop_rounded,
        targetTab: 0,
      ),
      _NotifItem(
        category: 3,
        title: '${c.kidsName} vừa nhận huy hiệu Khóa vòi nước',
        subtitle:
            'Bé đã hoàn thành ${c.kidsCups}/${c.kidsGoalCups} cốc và tích lũy thêm +10 sao!',
        time: '2 giờ trước',
        accent: AppColors.starAmber,
        icon: Icons.star_rounded,
        targetTab: 0,
        entersKidsMode: true,
      ),
      const _NotifItem(
        category: 3,
        title: 'Cập nhật trạm Refill Thư viện Thành phố',
        subtitle: 'Chỉ số TDS vừa kiểm định lại: 28 ppm (rất tốt • miễn phí).',
        time: 'Hôm qua',
        accent: AppColors.freshMint,
        icon: Icons.location_on_rounded,
        targetTab: 3,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final isStudent = c.role == AquaRole.studentWorker;
    final sourceItems = _buildItemsForRole(c);
    final filterChips = isStudent
        ? const [
            ('Tất cả', 0),
            ('Nhắc nước', 1),
            ('Sống xanh', 2),
            ('Trạm Refill', 3),
          ]
        : const [
            ('Tất cả', 0),
            ('Nhắc nước', 1),
            ('Nước & vệ sinh', 2),
            ('Gia đình & trạm', 3),
          ];

    final visible = _filter == 0
        ? sourceItems
        : sourceItems.where((e) => e.category == _filter).toList();

    return Scaffold(
      backgroundColor: AppColors.iceCanvas,
      appBar: AppBar(
        backgroundColor: AppColors.pureWhite,
        elevation: 0,
        title: Text('Trung tâm thông báo', style: AppTypography.headerTitle()),
        actions: [
          TextButton(
            onPressed: () {
              c.markAllNotificationsRead();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  duration: Duration(seconds: 1),
                  content: Text('Đã đánh dấu tất cả là đã đọc'),
                ),
              );
            },
            child: const Text('Đọc hết'),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.pureWhite,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: filterChips.map((f) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: AquaChoiceChip(
                      label: f.$1,
                      selected: _filter == f.$2,
                      onTap: () => setState(() => _filter = f.$2),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: AquaSmoothSwitcher(
              child: ListView.separated(
                key: ValueKey<int>(_filter),
                padding: const EdgeInsets.all(16),
                itemCount: visible.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final item = visible[i];
                  return StaggeredEntrance(
                    index: i,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.pureWhite,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A0F1F2C),
                            blurRadius: 14,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            if (item.entersKidsMode) {
                              c.enterKidsMode();
                            } else {
                              c.setActiveTab(item.targetTab);
                            }
                            Navigator.of(context).pop();
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(15),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: item.accent.withValues(alpha: 0.14),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(item.icon, color: item.accent),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(item.title,
                                          style: AppTypography.rowTitle()),
                                      const SizedBox(height: 4),
                                      Text(item.subtitle,
                                          style: AppTypography.cardBody()),
                                      const SizedBox(height: 6),
                                      Text(
                                        item.time,
                                        style: AppTypography.sectionCaption(
                                          color: AppColors.mutedGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
