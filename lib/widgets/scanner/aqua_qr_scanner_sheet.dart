import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../services/aqua_barcode_lookup_service.dart';
import '../animations/aqua_motion.dart';

class AquaQrScannerSheet extends StatefulWidget {
  const AquaQrScannerSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.confirmButtonLabel,
    required this.onConfirmed,
    this.onResultConfirmed,
    this.lookupClient,
    this.accentColor = AppColors.freshMint,
  });

  final String title;
  final String subtitle;
  final String confirmButtonLabel;
  final ValueChanged<String> onConfirmed;
  final ValueChanged<AquaScannedCodeResult>? onResultConfirmed;
  final http.Client? lookupClient;
  final Color accentColor;

  @override
  State<AquaQrScannerSheet> createState() => _AquaQrScannerSheetState();
}

class _AquaQrScannerSheetState extends State<AquaQrScannerSheet>
    with SingleTickerProviderStateMixin {
  final TextEditingController _codeController = TextEditingController();
  MobileScannerController? _scannerController;
  late final AnimationController _laserController;

  bool _showManualInput = false;
  bool _isLookingUp = false;
  AquaScannedCodeResult? _resolvedResult;
  int _selectedMl = 500;
  String? _cameraErrorText;

  static const List<int> _volumeChoices = [250, 350, 500, 750, 1000];

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    if (AquaMotion.isTestEnvironment) {
      _showManualInput = true;
    } else {
      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        autoStart: true,
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AquaMotion.allowInfinite(context) &&
        !_laserController.isAnimating &&
        _resolvedResult == null) {
      _laserController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _laserController.dispose();
    _codeController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isLookingUp || _resolvedResult != null) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue?.trim() ?? '';
      if (raw.isNotEmpty) {
        await _processScannedCode(raw);
        return;
      }
    }
  }

  Future<void> _processScannedCode(String rawCode) async {
    final trimmed = rawCode.trim();
    if (trimmed.isEmpty || _isLookingUp) return;

    if (!AquaMotion.isTestEnvironment) {
      HapticFeedback.mediumImpact();
    }

    setState(() {
      _isLookingUp = true;
    });

    if (_scannerController != null &&
        _scannerController!.value.isInitialized &&
        _scannerController!.value.isRunning) {
      try {
        await _scannerController!.stop();
      } catch (_) {}
    }

    final result = await AquaBarcodeLookupService.lookup(
      trimmed,
      client: widget.lookupClient,
    );

    if (!mounted) return;
    setState(() {
      _isLookingUp = false;
      _resolvedResult = result;
      _selectedMl = result.recommendedMl;
    });
  }

  Future<void> _rescan() async {
    setState(() {
      _resolvedResult = null;
      _isLookingUp = false;
      _cameraErrorText = null;
    });

    if (_scannerController != null) {
      try {
        await _scannerController!.start();
      } catch (_) {}
    }
    if (mounted &&
        AquaMotion.allowInfinite(context) &&
        !_laserController.isAnimating) {
      _laserController.repeat(reverse: true);
    }
  }

  Future<void> _toggleTorch() async {
    final controller = _scannerController;
    if (controller == null || !controller.value.isInitialized) return;
    try {
      await controller.toggleTorch();
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _switchCamera() async {
    final controller = _scannerController;
    if (controller == null || !controller.value.isInitialized) return;
    try {
      await controller.switchCamera();
      if (mounted) setState(() {});
    } catch (_) {}
  }

  void _confirmResult() {
    final result = _resolvedResult;
    if (result == null) return;
    final finalized = result.copyWith(recommendedMl: _selectedMl);
    Navigator.of(context).pop();
    if (widget.onResultConfirmed != null) {
      widget.onResultConfirmed!(finalized);
    } else {
      widget.onConfirmed(finalized.rawCode);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final maxSheetHeight = MediaQuery.sizeOf(context).height * 0.90;
    return Container(
      margin: EdgeInsets.fromLTRB(12, 10, 12, 12 + bottomInset),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: widget.accentColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    Icons.qr_code_scanner_rounded,
                    color: widget.accentColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title, style: AppTypography.cardTitle()),
                      const SizedBox(height: 2),
                      Text(widget.subtitle, style: AppTypography.cardBody()),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Đóng',
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_resolvedResult == null) ...[
              _buildScannerViewport(),
              const SizedBox(height: 10),
              if (!AquaMotion.isTestEnvironment)
                Align(
                  alignment: Alignment.center,
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _showManualInput = !_showManualInput;
                      });
                    },
                    icon: Icon(
                      _showManualInput
                          ? Icons.keyboard_hide_rounded
                          : Icons.keyboard_alt_outlined,
                      size: 18,
                    ),
                    label: Text(
                      _showManualInput
                          ? 'Ẩn ô nhập mã thủ công'
                          : 'Không quét được? Nhập mã thủ công',
                      style: AppTypography.rowTitle(color: AppColors.oceanBlue)
                          .copyWith(fontSize: 13),
                    ),
                  ),
                ),
              if (_showManualInput) ...[
                const SizedBox(height: 6),
                TextField(
                  controller: _codeController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: _processScannedCode,
                  decoration: InputDecoration(
                    hintText:
                        'VD: 8935012011340 (La Vie), AQUACARE_VERIFIED_QR...',
                    prefixIcon: const Icon(Icons.qr_code_2_rounded),
                    filled: true,
                    fillColor: AppColors.pastelMist,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _isLookingUp
                      ? null
                      : () => _processScannedCode(_codeController.text),
                  icon: _isLookingUp
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.search_rounded),
                  label: Text(
                    _isLookingUp ? 'Đang tra cứu mã...' : 'Tra cứu mã này',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ] else
              _buildResolvedCard(_resolvedResult!),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerViewport() {
    if (_scannerController == null) {
      return Container(
        constraints: const BoxConstraints(minHeight: 132),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.pastelMist,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.qr_code_scanner_rounded,
              size: 40,
              color: widget.accentColor,
            ),
            const SizedBox(height: 8),
            Text(
              _isLookingUp ? 'Đang tra cứu dữ liệu mã vạch / QR...' : 'Camera trực tiếp sẽ mở trên thiết bị thật.\nNhập mã chai nước / QR bên dưới để kiểm tra.',
              textAlign: TextAlign.center,
              style: AppTypography.cardBody(),
            ),
          ],
        ),
      );
    }

    final controller = _scannerController!;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 235,
        child: Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(
              controller: controller,
              fit: BoxFit.cover,
              onDetect: _onDetect,
              errorBuilder: (context, error) {
                final message =
                    error.errorDetails?.message ??
                    'Không thể truy cập camera ($error)';
                if (_cameraErrorText != message) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _cameraErrorText = message;
                        _showManualInput = true;
                      });
                    }
                  });
                }
                return Container(
                  color: AppColors.navyInk,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.no_photography_outlined,
                        color: AppColors.sunnyButter,
                        size: 36,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Chưa cấp quyền Camera hoặc thiết bị không hỗ trợ.',
                        textAlign: TextAlign.center,
                        style: AppTypography.rowTitle(color: Colors.white),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Hãy cấp quyền Camera trong Cài đặt hoặc nhập mã thủ công ở bên dưới.',
                        textAlign: TextAlign.center,
                        style: AppTypography.cardBody(color: Colors.white70),
                      ),
                    ],
                  ),
                );
              },
            ),
            IgnorePointer(
              child: CustomPaint(
                painter: _ScannerFramePainter(accentColor: widget.accentColor),
              ),
            ),
            if (!_isLookingUp && _cameraErrorText == null)
              IgnorePointer(
                child: AnimatedBuilder(
                  animation: _laserController,
                  builder: (_, _) {
                    return Align(
                      alignment: Alignment(
                        0,
                        -0.58 + 1.16 * _laserController.value,
                      ),
                      child: Container(
                        width: 170,
                        height: 2.5,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          gradient: LinearGradient(
                            colors: [
                              widget.accentColor.withValues(alpha: 0.0),
                              widget.accentColor,
                              widget.accentColor.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            if (_isLookingUp)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 10),
                      Text(
                        'Đang nhận diện mã...',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Positioned(
              top: 10,
              right: 10,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _OverlayIconButton(
                    icon: controller.value.torchState == TorchState.on
                        ? Icons.flash_on_rounded
                        : Icons.flash_off_rounded,
                    tooltip: 'Bật / Tắt đèn pin',
                    onTap: _toggleTorch,
                  ),
                  const SizedBox(width: 8),
                  _OverlayIconButton(
                    icon: Icons.cameraswitch_rounded,
                    tooltip: 'Đổi camera',
                    onTap: _switchCamera,
                  ),
                ],
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 10,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.56),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Đưa mã QR trạm Refill, que thử nước hoặc mã vạch chai nước vào giữa khung',
                    textAlign: TextAlign.center,
                    style: AppTypography.cardBody(color: Colors.white)
                        .copyWith(fontSize: 11.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResolvedCard(AquaScannedCodeResult result) {
    final showsVolumeSelector =
        result.kind == AquaScannedKind.waterBottle ||
        result.kind == AquaScannedKind.refillStation ||
        result.kind == AquaScannedKind.genericText;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.pastelMist,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: result.isVerifiedMatch
              ? AppColors.freshMint
              : AppColors.cardBorder,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color:
                      (result.isVerifiedMatch
                              ? AppColors.freshMint
                              : AppColors.oceanBlue)
                          .withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      result.isVerifiedMatch
                          ? Icons.verified_rounded
                          : Icons.qr_code_2_rounded,
                      size: 14,
                      color: result.isVerifiedMatch
                          ? AppColors.emerald
                          : AppColors.oceanBlue,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      result.sourceLabel,
                      style: AppTypography.metricLabel(
                        result.isVerifiedMatch
                            ? AppColors.emerald
                            : AppColors.oceanBlue,
                      ),
                    ),
                  ],
                ),
              ),
              if (result.estimatedTdsPpm != null)
                _InfoPill(
                  label:
                      'TDS ${result.estimatedTdsPpm} ppm • ${result.estimatedTdsPpm! <= 50 ? 'Tinh khiết' : (result.estimatedTdsPpm! <= 300 ? 'Chuẩn WHO' : 'Cao')}',
                  color: result.estimatedTdsPpm! <= 300
                      ? AppColors.aquaTeal
                      : AppColors.softCoral,
                ),
              if (result.estimatedPh != null)
                _InfoPill(
                  label: 'pH ${result.estimatedPh!.toStringAsFixed(1)}',
                  color: AppColors.periwinkle,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(result.title, style: AppTypography.cardTitle()),
          const SizedBox(height: 3),
          Text(
            result.subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.cardBody(),
          ),
          if (result.kind == AquaScannedKind.waterBottle) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.sunnyTile,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.eco_rounded,
                    size: 16,
                    color: AppColors.emerald,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'Mẹo SDG 6: Ưu tiên Refill bình cá nhân tại trạm miễn phí để giảm ~20g rác nhựa dùng 1 lần!',
                      style: AppTypography.cardBody(color: AppColors.navyInk)
                          .copyWith(fontSize: 11.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 5),
          Text(
            'Mã: ${result.rawCode}',
            style: AppTypography.cardBody(color: AppColors.mutedGrey)
                .copyWith(fontSize: 11),
          ),
          if (showsVolumeSelector) ...[
            const SizedBox(height: 8),
            Text(
              'Chọn lượng nước vừa uống:',
              style: AppTypography.rowTitle().copyWith(fontSize: 12.5),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _volumeChoices.map((ml) {
                final selected = _selectedMl == ml;
                return ChoiceChip(
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  label: Text('$ml ml'),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedMl = ml),
                  selectedColor: widget.accentColor.withValues(alpha: 0.2),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _rescan,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Quét lại'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.navyInk,
                    side: const BorderSide(color: AppColors.cardBorder),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _confirmResult,
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: Text(
                    showsVolumeSelector
                        ? 'Xác nhận (+$_selectedMl ml)'
                        : widget.confirmButtonLabel,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverlayIconButton extends StatelessWidget {
  const _OverlayIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.54),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 19),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: AppTypography.metricLabel(color)),
    );
  }
}

class _ScannerFramePainter extends CustomPainter {
  const _ScannerFramePainter({required this.accentColor});

  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final boxSize = size.height * 0.68;
    final left = (size.width - boxSize) / 2;
    final top = (size.height - boxSize) / 2;
    final right = left + boxSize;
    final bottom = top + boxSize;
    const corner = 22.0;

    final dimPaint = Paint()..color = Colors.black.withValues(alpha: 0.32);
    canvas.drawRect(Rect.fromLTRB(0, 0, size.width, top), dimPaint);
    canvas.drawRect(
      Rect.fromLTRB(0, bottom, size.width, size.height),
      dimPaint,
    );
    canvas.drawRect(Rect.fromLTRB(0, top, left, bottom), dimPaint);
    canvas.drawRect(Rect.fromLTRB(right, top, size.width, bottom), dimPaint);

    final cornerPaint = Paint()
      ..color = accentColor
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Top-left
    canvas.drawLine(Offset(left, top + corner), Offset(left, top), cornerPaint);
    canvas.drawLine(Offset(left, top), Offset(left + corner, top), cornerPaint);
    // Top-right
    canvas.drawLine(
      Offset(right - corner, top),
      Offset(right, top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(right, top),
      Offset(right, top + corner),
      cornerPaint,
    );
    // Bottom-left
    canvas.drawLine(
      Offset(left, bottom - corner),
      Offset(left, bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left, bottom),
      Offset(left + corner, bottom),
      cornerPaint,
    );
    // Bottom-right
    canvas.drawLine(
      Offset(right - corner, bottom),
      Offset(right, bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(right, bottom - corner),
      Offset(right, bottom),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScannerFramePainter oldDelegate) =>
      oldDelegate.accentColor != accentColor;
}
