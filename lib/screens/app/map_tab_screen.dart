import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../state/aqua_ui_controller.dart';
import '../../widgets/animations/aqua_motion.dart';
import '../../widgets/interactive/interactive_panel.dart';
import '../../widgets/scanner/aqua_qr_scanner_sheet.dart';

/// Tab 3: Dual-engine OpenStreetMap (`flutter_map`) & SDG 6 Vector Refill Station Map,
/// live search, GPS locator, Camera QR check-in, station proposal & incident tracking.
class MapTabScreen extends StatefulWidget {
  const MapTabScreen({super.key, required this.controller});

  final AquaUiController controller;

  @override
  State<MapTabScreen> createState() => _MapTabScreenState();
}

class _MapTabScreenState extends State<MapTabScreen>
    with SingleTickerProviderStateMixin {
  bool _showOutageLayer = false;
  late bool _useOsmMap;
  late final AnimationController _pulseController;
  late final TextEditingController _searchCtrl;
  final MapController _osmMapController = MapController();
  bool _pulseInitialized = false;
  bool _mapReady = false;
  int _lastHandledGpsRev = 0;

  @override
  void initState() {
    super.initState();
    _useOsmMap = !AquaMotion.isTestEnvironment;
    _lastHandledGpsRev = widget.controller.gpsFixRevision;
    widget.controller.addListener(_onControllerChanged);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _searchCtrl = TextEditingController(text: widget.controller.searchQuery);

    if (!AquaMotion.isTestEnvironment) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !widget.controller.isLocatingGps) {
          widget.controller.refreshGpsLocation();
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant MapTabScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      _lastHandledGpsRev = widget.controller.gpsFixRevision;
      widget.controller.addListener(_onControllerChanged);
    }
  }

  void _onControllerChanged() {
    final c = widget.controller;
    if (c.gpsFixRevision != _lastHandledGpsRev) {
      _lastHandledGpsRev = c.gpsFixRevision;
      if (_useOsmMap && _mapReady && mounted) {
        try {
          _osmMapController.move(LatLng(c.userLat, c.userLng), 15.8);
        } catch (_) {}
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_pulseInitialized) {
      _pulseInitialized = true;
      if (AquaMotion.allowInfinite(context)) {
        _pulseController.repeat();
      } else {
        _pulseController.value = 0.45;
      }
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _osmMapController.dispose();
    _pulseController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openQrCheckinSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AquaQrScannerSheet(
        title: 'Quét QR check-in Refill xanh',
        subtitle:
            'Xác thực lấy nước tại ${widget.controller.selectedStation.name} để ghi nhận giảm 1 chai nhựa.',
        confirmButtonLabel: 'Xác nhận Refill bình (+350 ml) ✓',
        accentColor: AppColors.freshMint,
        onResultConfirmed: (res) {
          final msg = widget.controller.applyScannedCodeResult(res);
          if (mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(msg)));
          }
        },
        onConfirmed: (_) {
          widget.controller.checkInReusableBottle();
          widget.controller.addWater(350);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Hoàn tất Refill Xanh! +350 ml & +1 chai nhựa tiết kiệm',
                ),
              ),
            );
          }
        },
      ),
    );
  }

  void _openProposeStationSheet() {
    final nameCtrl = TextEditingController();
    double tds = 30;
    bool hotCold = true;
    bool open24h = false;
    bool hasHandwashSanitation = false;

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
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Đề xuất trạm nước & vệ sinh mới',
                    style: AppTypography.cardTitle(),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Đóng góp điểm lấy nước miễn phí hoặc trạm rửa tay công cộng quanh bạn.',
                    style: AppTypography.cardBody(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tên trạm nước / vệ sinh mới',
                      hintText: 'VD: Trạm Khu B Ký túc xá',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Chỉ số TDS ước tính: ${tds.round()} ppm',
                    style: AppTypography.rowTitle(),
                  ),
                  Slider(
                    value: tds,
                    min: 10,
                    max: 80,
                    activeColor: AppColors.freshMint,
                    onChanged: (v) => setSheetState(() => tds = v),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      AquaChoiceChip(
                        label: 'Có nóng / lạnh',
                        selected: hotCold,
                        selectedColor: AppColors.freshMint,
                        onTap: () => setSheetState(() => hotCold = !hotCold),
                      ),
                      AquaChoiceChip(
                        label: 'Mở 24/7',
                        selected: open24h,
                        selectedColor: AppColors.freshMint,
                        onTap: () => setSheetState(() => open24h = !open24h),
                      ),
                      AquaChoiceChip(
                        label: 'Có rửa tay / VS sạch',
                        selected: hasHandwashSanitation,
                        selectedColor: AppColors.oceanBlue,
                        onTap: () => setSheetState(
                          () => hasHandwashSanitation = !hasHandwashSanitation,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.freshMint,
                        foregroundColor: AppColors.pureWhite,
                      ),
                      onPressed: () {
                        final rawName = nameCtrl.text.trim();
                        if (rawName.isEmpty) return;
                        widget.controller.proposeStation(
                          name: rawName,
                          tdsPpm: tds.round(),
                          hasHotCold: hotCold,
                          isOpen24h: open24h,
                          hasHandwashSanitation: hasHandwashSanitation,
                        );
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Đã thêm trạm "$rawName" lên bản đồ!',
                            ),
                          ),
                        );
                      },
                      child: const Text('Ghim trạm mới lên bản đồ ✓'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(nameCtrl.dispose);
  }

  void _openReportIncidentSheet() {
    const levels = ['Thấp', 'Trung bình', 'Khẩn cấp'];
    const presets = [
      'Rò rỉ đường ống',
      'Nước đục / có mùi',
      'Điểm rửa tay / VS hỏng',
    ];
    final descCtrl = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return AnimatedBuilder(
          animation: widget.controller,
          builder: (_, _) {
            final c = widget.controller;
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Báo cáo Sự cố Nước & Vệ sinh (SDG 6)',
                      style: AppTypography.cardTitle(),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Gửi thông tin rò rỉ đường ống, nước đục/có mùi hoặc điểm rửa tay / vệ sinh công cộng cần sửa chữa.',
                      style: AppTypography.cardBody(),
                    ),
                    const SizedBox(height: 10),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: descCtrl,
                      builder: (_, value, _) {
                        return Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: presets.map((preset) {
                            return AquaChoiceChip(
                              label: preset,
                              selected: value.text == preset,
                              selectedColor: AppColors.softCoral,
                              onTap: () {
                                descCtrl.text = preset;
                              },
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Mô tả ngắn sự cố',
                        hintText: 'VD: Vòi trạm công viên bị rò rỉ van khóa',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: List.generate(3, (i) {
                        return AquaChoiceChip(
                          label: levels[i],
                          selected: c.incidentSeverity == i,
                          selectedColor: i == 2
                              ? AppColors.softCoral
                              : (i == 1
                                    ? AppColors.starAmber
                                    : AppColors.freshMint),
                          selectedTextColor: i == 1
                              ? AppColors.navyInk
                              : AppColors.pureWhite,
                          onTap: () => c.setIncidentSeverity(i),
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.softCoral,
                          foregroundColor: AppColors.pureWhite,
                        ),
                        onPressed: () {
                          c.submitIncidentReport(
                            description: descCtrl.text,
                            severity: c.incidentSeverity,
                          );
                          descCtrl.clear();
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Đã gửi báo cáo sự cố vào danh sách!',
                              ),
                            ),
                          );
                        },
                        child: const Text('Gửi báo cáo hiện trường'),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Nhật ký sự cố cộng đồng (${c.incidentReports.length})',
                      style: AppTypography.rowTitle(),
                    ),
                    const SizedBox(height: 6),
                    ...c.incidentReports.take(3).map((rep) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Material(
                          color: AppColors.pastelMist,
                          borderRadius: BorderRadius.circular(12),
                          child: ListTile(
                            dense: true,
                            title: Text(
                              rep.title,
                              style: AppTypography.rowTitle(),
                            ),
                            subtitle: Text(
                              '${rep.stationName} • ${rep.status} (${rep.createdAtLabel})',
                              style: AppTypography.cardBody(),
                            ),
                            trailing: TextButton.icon(
                              onPressed: () => c.upvoteIncidentItem(rep.id),
                              icon: const Icon(
                                Icons.thumb_up_alt_outlined,
                                size: 14,
                              ),
                              label: Text('${rep.upvotes}'),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(descCtrl.dispose);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final selected = c.selectedStation;
    final filteredStations = c.filteredStations;

    return Scaffold(
      backgroundColor: AppColors.iceCanvas,
      body: Stack(
        children: [
          // Dual-engine interactive map canvas
          Positioned.fill(
            child: _useOsmMap
                ? _buildOsmMap(c, selected, filteredStations)
                : _buildVectorMap(c, selected, filteredStations),
          ),

          // Floating top search & filter bar
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.pureWhite,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x140F1F2C),
                          blurRadius: 16,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 2,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search_rounded,
                          color: AppColors.cyanVivid,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: c.setSearchQuery,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              isDense: true,
                              filled: false,
                              hintText:
                                  'Tìm trạm nước & điểm rửa tay (${filteredStations.length})...',
                              hintStyle: AppTypography.cardBody(),
                            ),
                            style: AppTypography.rowTitle(),
                          ),
                        ),
                        if (c.searchQuery.isNotEmpty)
                          IconButton(
                            tooltip: 'Xóa từ khóa',
                            visualDensity: VisualDensity.compact,
                            onPressed: () {
                              _searchCtrl.clear();
                              c.setSearchQuery('');
                            },
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: AppColors.mutedGrey,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        AquaChoiceChip(
                          label: 'Miễn phí',
                          selected: c.filterFreeOnly,
                          selectedColor: AppColors.emerald,
                          onTap: () => c.toggleStationFilter(
                            freeOnly: !c.filterFreeOnly,
                          ),
                        ),
                        const SizedBox(width: 6),
                        AquaChoiceChip(
                          label: 'Nóng / lạnh',
                          selected: c.filterHotCold,
                          selectedColor: AppColors.emerald,
                          onTap: () =>
                              c.toggleStationFilter(hotCold: !c.filterHotCold),
                        ),
                        const SizedBox(width: 6),
                        AquaChoiceChip(
                          label: 'Mở 24/7',
                          selected: c.filterOpen24h,
                          selectedColor: AppColors.emerald,
                          onTap: () =>
                              c.toggleStationFilter(open24h: !c.filterOpen24h),
                        ),
                        const SizedBox(width: 6),
                        AquaChoiceChip(
                          label: 'Rửa tay & vệ sinh',
                          selected: c.filterSanitationOnly,
                          selectedColor: AppColors.oceanBlue,
                          onTap: () => c.toggleStationFilter(
                            sanitationOnly: !c.filterSanitationOnly,
                          ),
                        ),
                        const SizedBox(width: 6),
                        AquaChoiceChip(
                          label: 'Cảnh báo cắt nước',
                          selected: _showOutageLayer,
                          selectedColor: AppColors.softCoral,
                          onTap: () => setState(
                            () => _showOutageLayer = !_showOutageLayer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Compact unified map control capsule on right
          Positioned(
            right: 16,
            top: 132,
            child: Container(
              width: 44,
              decoration: BoxDecoration(
                color: AppColors.pureWhite,
                borderRadius: BorderRadius.circular(999),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x140F1F2C),
                    blurRadius: 14,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: _useOsmMap
                        ? 'Đổi sang bản đồ minh họa'
                        : 'Đổi sang bản đồ thực tế OSM',
                    onPressed: () => setState(() => _useOsmMap = !_useOsmMap),
                    icon: Icon(
                      _useOsmMap ? Icons.layers_rounded : Icons.map_outlined,
                      size: 20,
                      color: AppColors.oceanBlue,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Định vị vị trí của tôi',
                    onPressed: () async {
                      await c.refreshGpsLocation();
                      if (_useOsmMap && _mapReady && mounted) {
                        try {
                          _osmMapController.move(
                            LatLng(c.userLat, c.userLng),
                            15.8,
                          );
                        } catch (_) {}
                      }
                    },
                    icon: c.isLocatingGps
                        ? const SizedBox(
                            width: 17,
                            height: 17,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.oceanBlue,
                            ),
                          )
                        : const Icon(
                            Icons.my_location_rounded,
                            size: 20,
                            color: AppColors.oceanBlue,
                          ),
                  ),
                ],
              ),
            ),
          ),

          // Draggable bottom sheet with selected station + nearby list
          DraggableScrollableSheet(
            initialChildSize: 0.38,
            minChildSize: 0.25,
            maxChildSize: 0.72,
            builder: (ctx, scrollCtrl) {
              return Container(
                decoration: const BoxDecoration(
                  color: AppColors.pureWhite,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x180F1F2C),
                      blurRadius: 20,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.homeIndicator,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selected.name,
                                style: AppTypography.cardTitle(),
                              ),
                              Text(
                                '${c.distanceToStation(selected)}m • TDS ${selected.tdsPpm} ppm • ${selected.isFree ? 'Miễn phí' : 'Có phí'}${selected.hasHandwashSanitation ? ' • Có rửa tay / VS sạch' : ''}',
                                style: AppTypography.cardBody(),
                              ),
                            ],
                          ),
                        ),
                        BouncyPressable(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.emerald,
                              foregroundColor: AppColors.pureWhite,
                              elevation: 0,
                              shape: const StadiumBorder(),
                            ),
                            onPressed: _openQrCheckinSheet,
                            icon: const Icon(
                              Icons.qr_code_scanner_rounded,
                              size: 16,
                            ),
                            label: const Text('Refill QR'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      alignment: WrapAlignment.spaceBetween,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Đánh giá:', style: AppTypography.cardBody()),
                            const SizedBox(width: 4),
                            ...List.generate(5, (i) {
                              return InkWell(
                                onTap: () => c.setStationRating(i + 1),
                                child: Icon(
                                  (i + 1) <= c.stationRating
                                      ? Icons.star_rounded
                                      : Icons.star_border_rounded,
                                  size: 19,
                                  color: AppColors.starAmber,
                                ),
                              );
                            }),
                          ],
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          onPressed: _openProposeStationSheet,
                          icon: const Icon(
                            Icons.add_location_alt_outlined,
                            size: 16,
                          ),
                          label: const Text('Đề xuất trạm'),
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.softCoral,
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          onPressed: _openReportIncidentSheet,
                          icon: const Icon(
                            Icons.report_problem_outlined,
                            size: 16,
                          ),
                          label: const Text('Báo sự cố'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Các trạm gần đây (${filteredStations.length})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.sectionCaption(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            c.gpsStatusLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: AppTypography.sectionCaption(
                              color: AppColors.mutedGrey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (filteredStations.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Text(
                          'Không tìm thấy trạm phù hợp bộ lọc hiện tại.',
                          style: AppTypography.cardBody(),
                        ),
                      )
                    else
                      ...filteredStations.map((st) {
                        final isSel = st.id == selected.id;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Material(
                            color: isSel
                                ? AppColors.cyanTile
                                : AppColors.iceCanvas,
                            borderRadius: BorderRadius.circular(18),
                            clipBehavior: Clip.antiAlias,
                            child: ListTile(
                              dense: true,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              leading: Icon(
                                Icons.water_drop_rounded,
                                color: isSel
                                    ? AppColors.emerald
                                    : AppColors.cyanVivid,
                              ),
                              title: Text(st.name, style: AppTypography.rowTitle()),
                              subtitle: Text(
                                '${c.distanceToStation(st)}m • TDS ${st.tdsPpm} ppm${st.hasHandwashSanitation ? ' • Có rửa tay / VS sạch' : ''}${st.isUserProposed ? ' • Đề xuất mới' : ''}',
                                style: AppTypography.cardBody(),
                              ),
                              trailing: st.hasHandwashSanitation
                                  ? const Tooltip(
                                      message: 'Có điểm rửa tay / vệ sinh sạch',
                                      child: Icon(
                                        Icons.clean_hands_rounded,
                                        size: 18,
                                        color: AppColors.oceanBlue,
                                      ),
                                    )
                                  : null,
                              onTap: () => c.selectStation(st.id),
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOsmMap(
    AquaUiController c,
    AquaRefillStation selected,
    List<AquaRefillStation> filteredStations,
  ) {
    final userPoint = LatLng(c.userLat, c.userLng);
    final selectedPoint = LatLng(selected.latitude, selected.longitude);

    return FlutterMap(
      mapController: _osmMapController,
      options: MapOptions(
        initialCenter: userPoint,
        initialZoom: 15.6,
        onMapReady: () {
          _mapReady = true;
          try {
            _osmMapController.move(LatLng(c.userLat, c.userLng), 15.8);
          } catch (_) {}
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'vn.sdg6.aquacare',
        ),
        if (_showOutageLayer)
          CircleLayer(
            circles: [
              CircleMarker(
                point: const LatLng(15.9673, 108.2624),
                radius: 160,
                useRadiusInMeter: true,
                color: AppColors.softCoral.withValues(alpha: 0.25),
                borderColor: AppColors.softCoral,
                borderStrokeWidth: 2,
              ),
            ],
          ),
        PolylineLayer(
          polylines: [
            Polyline(
              points: [userPoint, selectedPoint],
              strokeWidth: 4,
              color: AppColors.deepSky,
            ),
          ],
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: userPoint,
              width: 28,
              height: 28,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.skyCyan,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.pureWhite, width: 3.5),
                  boxShadow: const [
                    BoxShadow(color: AppColors.skyCyanShadow, blurRadius: 10),
                  ],
                ),
              ),
            ),
            ...filteredStations.map((s) {
              final active = s.id == selected.id;
              return Marker(
                point: LatLng(s.latitude, s.longitude),
                width: 44,
                height: 44,
                child: GestureDetector(
                  onTap: () => c.selectStation(s.id),
                  child: Icon(
                    Icons.location_on_rounded,
                    size: active ? 40 : 32,
                    color: _showOutageLayer && s.id == 3
                        ? AppColors.softCoral
                        : (active ? AppColors.freshMint : AppColors.deepSky),
                  ),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildVectorMap(
    AquaUiController c,
    AquaRefillStation selected,
    List<AquaRefillStation> filteredStations,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (_, _) {
                  return CustomPaint(
                    painter: _FullMapPainter(
                      selectedStation: selected,
                      showOutageLayer: _showOutageLayer,
                      pulse: _pulseController.value,
                    ),
                  );
                },
              ),
            ),
            Positioned(
              left: constraints.maxWidth * 0.28 - 11,
              top: constraints.maxHeight * 0.44 - 11,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: AppColors.skyCyan,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.pureWhite, width: 3.5),
                  boxShadow: const [
                    BoxShadow(color: AppColors.skyCyanShadow, blurRadius: 10),
                  ],
                ),
              ),
            ),
            ...filteredStations.map((s) {
              final active = s.id == selected.id;
              return Positioned(
                left: constraints.maxWidth * s.xFactor - 20,
                top: constraints.maxHeight * s.yFactor - 38,
                child: GestureDetector(
                  onTap: () => c.selectStation(s.id),
                  child: AnimatedScale(
                    scale: active ? 1.25 : 0.95,
                    duration: const Duration(milliseconds: 340),
                    curve: Curves.elasticOut,
                    child: Icon(
                      Icons.location_on_rounded,
                      size: 36,
                      color: _showOutageLayer && s.id == 3
                          ? AppColors.softCoral
                          : (active ? AppColors.freshMint : AppColors.deepSky),
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class _FullMapPainter extends CustomPainter {
  _FullMapPainter({
    required this.selectedStation,
    required this.showOutageLayer,
    required this.pulse,
  });

  final AquaRefillStation selectedStation;
  final bool showOutageLayer;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFEAF5FC),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.08, size.height * 0.22, 90, 56),
        const Radius.circular(16),
      ),
      Paint()..color = const Color(0xFFDFF7EA),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.56, size.height * 0.42, 110, 68),
        const Radius.circular(18),
      ),
      Paint()..color = const Color(0xFFDFF7EA),
    );

    final roadPaint = Paint()
      ..color = AppColors.pureWhite
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke;

    for (final yRatio in [0.24, 0.44, 0.64]) {
      canvas.drawLine(
        Offset(0, size.height * yRatio),
        Offset(size.width, size.height * yRatio),
        roadPaint,
      );
    }
    for (final xRatio in [0.28, 0.54, 0.78]) {
      canvas.drawLine(
        Offset(size.width * xRatio, 0),
        Offset(size.width * xRatio, size.height),
        roadPaint,
      );
    }

    if (showOutageLayer) {
      canvas.drawCircle(
        Offset(size.width * 0.78, size.height * 0.64),
        48,
        Paint()..color = AppColors.softCoral.withValues(alpha: 0.24),
      );
    }

    final start = Offset(size.width * 0.28, size.height * 0.44);

    final pulseRadius = 14.0 + pulse * 34.0;
    final pulseAlpha = (1.0 - pulse) * 0.34;
    canvas.drawCircle(
      start,
      pulseRadius,
      Paint()..color = AppColors.skyCyan.withValues(alpha: pulseAlpha),
    );

    final end = Offset(
      size.width * selectedStation.xFactor,
      size.height * selectedStation.yFactor,
    );
    final routePath = Path()
      ..moveTo(start.dx, start.dy)
      ..lineTo(end.dx, start.dy)
      ..lineTo(end.dx, end.dy);

    final routePaint = Paint()
      ..color = AppColors.deepSky
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final metric in routePath.computeMetrics()) {
      double dist = (pulse * 24) % 16;
      while (dist < metric.length) {
        final next = (dist + 9).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(dist, next), routePaint);
        dist += 16;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FullMapPainter oldDelegate) =>
      oldDelegate.selectedStation.id != selectedStation.id ||
      oldDelegate.showOutageLayer != showOutageLayer ||
      oldDelegate.pulse != pulse;
}
