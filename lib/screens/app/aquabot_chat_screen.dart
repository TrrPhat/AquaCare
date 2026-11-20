import 'dart:async';
import 'package:material_ui/material_ui.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../state/aqua_ui_controller.dart';
import '../../widgets/animations/aqua_motion.dart';
import '../../widgets/animations/aqua_waterllama_motion.dart';
import '../../widgets/interactive/interactive_panel.dart';
import '../../widgets/mascot/aqua_mascot_catalog.dart';

/// Full-screen interactive AI assistant chat view with clean status banner & live AI configuration sheet.
class AquaBotChatScreen extends StatefulWidget {
  const AquaBotChatScreen({super.key, required this.controller});

  final AquaUiController controller;

  @override
  State<AquaBotChatScreen> createState() => _AquaBotChatScreenState();
}

class _AquaBotChatScreenState extends State<AquaBotChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _inputCtrl = TextEditingController();
  late final AnimationController _replyAnim;

  @override
  void initState() {
    super.initState();
    _replyAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _replyAnim.dispose();
    super.dispose();
  }

  void _send([String? preset]) {
    final text = preset ?? _inputCtrl.text;
    if (text.trim().isEmpty) return;
    unawaited(widget.controller.sendBotMessage(text));
    _replyAnim.forward(from: 0.0);
    if (preset == null) _inputCtrl.clear();
  }

  void _openAiConfigSheet() {
    final c = widget.controller;
    final urlCtrl = TextEditingController(text: c.activeAiEndpoint);
    final modelCtrl = TextEditingController(text: c.activeAiModel);
    final keyCtrl = TextEditingController(text: c.activeAiApiKey);
    bool obscureKey = true;

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
              child: SingleChildScrollView(
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
                    const SizedBox(height: 14),
                    Text(
                      'Cấu hình kết nối AI',
                      style: AppTypography.cardTitle(),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tự động nhận diện chuẩn Anthropic (/v1/messages) và OpenAI (/v1/chat/completions).',
                      style: AppTypography.cardBody(),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: urlCtrl,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'Địa chỉ API Endpoint',
                        hintText: 'https://.../v1/messages',
                        prefixIcon: Icon(Icons.link_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: modelCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Tên model sử dụng',
                        hintText: 'VD: gpt-4o-mini hoặc claude-3-5-haiku',
                        prefixIcon: Icon(Icons.memory_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: keyCtrl,
                      obscureText: obscureKey,
                      decoration: InputDecoration(
                        labelText: 'Mã khóa API Key',
                        prefixIcon: const Icon(Icons.key_rounded),
                        suffixIcon: IconButton(
                          onPressed: () =>
                              setSheetState(() => obscureKey = !obscureKey),
                          icon: Icon(
                            obscureKey
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 19,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              c.updateAiConfig(
                                endpoint: '',
                                model: '',
                                apiKey: '',
                              );
                              Navigator.of(ctx).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Đã khôi phục cấu hình AI mặc định',
                                  ),
                                ),
                              );
                            },
                            child: const Text('Mặc định'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.skyCyan,
                              foregroundColor: AppColors.pureWhite,
                            ),
                            onPressed: () {
                              c.updateAiConfig(
                                endpoint: urlCtrl.text,
                                model: modelCtrl.text,
                                apiKey: keyCtrl.text,
                              );
                              Navigator.of(ctx).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Đã lưu cấu hình kết nối AI trên thiết bị ✓',
                                  ),
                                ),
                              );
                            },
                            child: const Text('Lưu cấu hình ✓'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      urlCtrl.dispose();
      modelCtrl.dispose();
      keyCtrl.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final c = widget.controller;
        final msgs = c.chatMessages;
        final isCustom = c.isCustomAiConfigured;
        final modelLabel = c.customAiModelName;
        final isTyping = c.isBotTyping;
        final diagnostic = c.aiDiagnosticBanner;

        return Scaffold(
          backgroundColor: AppColors.iceCanvas,
          appBar: AppBar(
            backgroundColor: AppColors.pureWhite,
            elevation: 0,
            titleSpacing: 0,
            title: Row(
              children: [
                AquaPulseHalo(
                  maxScale: 1.07,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: AppColors.cyanTile,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: AquaMascotVectorArt(
                        mascotId: c.selectedMascotId,
                        size: 26,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trợ lý AI AquaBot',
                        style: AppTypography.headerTitle(),
                      ),
                      Text(
                        diagnostic != null
                            ? 'Trợ lý phân tích nội bộ • Luôn sẵn sàng'
                            : (isCustom
                                ? (modelLabel.isNotEmpty
                                    ? 'Model: $modelLabel'
                                    : 'Đã kết nối máy chủ AI')
                                : 'Trợ lý nội bộ trên thiết bị'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.metricLabel(
                          diagnostic != null
                              ? AppColors.oceanBlue
                              : AppColors.emerald,
                        ).copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Cấu hình kết nối AI',
                onPressed: _openAiConfigSheet,
                icon: const Icon(
                  Icons.tune_rounded,
                  color: AppColors.oceanBlue,
                ),
              ),
              IconButton(
                tooltip: 'Làm mới hội thoại',
                onPressed: c.clearBotChat,
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: AppColors.oceanBlue,
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: diagnostic == null
                    ? const SizedBox.shrink()
                    : Container(
                        width: double.infinity,
                        margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.skySoftBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 17,
                              color: AppColors.oceanBlue,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                diagnostic,
                                style: AppTypography.cardBody(
                                  color: AppColors.navyInk,
                                ).copyWith(fontSize: 12),
                              ),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: _openAiConfigSheet,
                              child: const Text('Cấu hình'),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: c.dismissAiDiagnostic,
                              icon: const Icon(Icons.close_rounded, size: 16),
                            ),
                          ],
                        ),
                      ),
              ),
              Expanded(
                child: AnimatedBuilder(
                  animation: _replyAnim,
                  builder: (_, _) {
                    final totalCount = msgs.length + (isTyping ? 1 : 0);
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: totalCount,
                      itemBuilder: (_, i) {
                        if (isTyping && i == msgs.length) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: const BoxDecoration(
                                color: AppColors.pureWhite,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                  bottomLeft: Radius.circular(6),
                                  bottomRight: Radius.circular(20),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0x0A0F1F2C),
                                    blurRadius: 12,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const AquaConcentricDotsSpinner(size: 24),
                                  const SizedBox(width: 8),
                                  Text(
                                    'AquaBot đang phân tích...',
                                    style: AppTypography.cardBody(),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        final m = msgs[i];
                        final isLatestBot = i == msgs.length - 1 && !m.isUser;
                        final showThinking = isLatestBot &&
                            _replyAnim.isAnimating &&
                            _replyAnim.value < 0.45;
                        final slideOffset = isLatestBot
                            ? (1.0 -
                                    Curves.easeOutCubic
                                        .transform(_replyAnim.value)) *
                                12
                            : 0.0;
                        return Transform.translate(
                          offset: Offset(0, slideOffset),
                          child: Align(
                            alignment: m.isUser
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 11,
                              ),
                              constraints: const BoxConstraints(maxWidth: 288),
                              decoration: BoxDecoration(
                                color: m.isUser
                                    ? AppColors.cyanVivid
                                    : AppColors.pureWhite,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(20),
                                  topRight: const Radius.circular(20),
                                  bottomLeft: Radius.circular(m.isUser ? 20 : 6),
                                  bottomRight:
                                      Radius.circular(m.isUser ? 6 : 20),
                                ),
                                boxShadow: m.isUser
                                    ? null
                                    : const [
                                        BoxShadow(
                                          color: Color(0x0A0F1F2C),
                                          blurRadius: 12,
                                          offset: Offset(0, 3),
                                        ),
                                      ],
                              ),
                              child: Text(
                                showThinking
                                    ? 'AquaBot đang trả lời...'
                                    : m.text,
                                style: AppTypography.cardBody(
                                  color: m.isUser
                                      ? AppColors.pureWhite
                                      : AppColors.navyInk,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Container(
                color: AppColors.pureWhite,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: SafeArea(
                  top: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: (switch (c.role) {
                            AquaRole.studentWorker => const [
                                'Hôm nay cần uống thêm mấy ml?',
                                'Cách vệ sinh bình nước cá nhân sạch khuẩn',
                                'Uống cà phê cần bù bao nhiêu nước?',
                                'Trạm Refill nào gần mình nhất?',
                              ],
                            AquaRole.household => [
                                'TDS bao nhiêu là tốt?',
                                'Nước máy & nước khoáng TDS bao nhiêu là an toàn?',
                                'Mẹo vệ sinh bồn nước & rửa tay gia đình',
                                'Tình trạng uống nước của ${c.kidsName}',
                              ],
                            AquaRole.kids => const [
                                'Vì sao uống nước giúp bé thông minh?',
                                'Hôm nay bé uống mấy cốc rồi?',
                                'Làm sao nhận thêm Sao Vàng?',
                              ],
                          })
                              .map((q) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: AquaChoiceChip(
                                label: q,
                                selected: false,
                                onTap: () => _send(q),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _inputCtrl,
                              onSubmitted: (_) => _send(),
                              decoration: const InputDecoration(
                                hintText: 'Nhập câu hỏi cho AquaBot...',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          BouncyPressable(
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.skyCyan,
                                foregroundColor: AppColors.pureWhite,
                                shape: const CircleBorder(),
                                padding: const EdgeInsets.all(13),
                              ),
                              onPressed: isTyping ? null : () => _send(),
                              child: const Icon(Icons.send_rounded, size: 18),
                            ),
                          ),
                        ],
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
