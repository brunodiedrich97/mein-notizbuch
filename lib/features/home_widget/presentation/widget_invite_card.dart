import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../l10n/app_strings.dart';
import '../data/daily_word_widget.dart';
import '../providers/widget_invite_provider.dart';

/// Pede ao sistema para fixar o widget; se o launcher não permitir, mostra
/// como adicionar à mão.
Future<void> addDailyWordWidget(BuildContext context) async {
  if (await DailyWordWidget.canRequestPin()) {
    await DailyWordWidget.requestPin();
    return;
  }
  if (!context.mounted) return;
  await showAppSheet<void>(context, (ctx) {
    final p = AppPalette.of(ctx);
    Widget step(String n, String text) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                child: Text(n, style: AppTheme.mono(fontSize: 13, color: p.text400)),
              ),
              Expanded(child: Text(text, style: AppText.body(p))),
            ],
          ),
        );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(tr.addWidgetCaps, style: AppText.section(p)),
        const SizedBox(height: 12),
        step('1', tr.widgetStep1),
        step('2', tr.widgetStep2),
        step('3', tr.widgetStep3),
        const SizedBox(height: 14),
        PrimaryButton(
          label: tr.gotIt,
          onPressed: () => Navigator.of(ctx).pop(),
        ),
      ],
    );
  });
}

/// Cartão "Palavra do dia na tela inicial" no topo da tela inicial.
class WidgetInviteCard extends ConsumerWidget {
  const WidgetInviteCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(widgetInviteProvider)) return const SizedBox.shrink();
    final p = AppPalette.of(context);
    final controller = ref.read(widgetInviteProvider.notifier);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: p.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _MiniWidget(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr.widgetInviteTitle,
                        style: AppText.item(p).copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tr.widgetInviteText,
                        style: AppText.body(p).copyWith(
                          fontSize: 13,
                          color: p.text500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                InkResponse(
                  radius: 18,
                  onTap: controller.dismiss,
                  child: Icon(Icons.close_rounded, size: 18, color: p.text400),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SoftButton(
                    label: tr.notNow,
                    onPressed: controller.dismiss,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    label: tr.addWidget,
                    onPressed: () async {
                      await controller.dismiss();
                      if (context.mounted) await addDailyWordWidget(context);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Miniatura do widget no cartão de convite.
class _MiniWidget extends StatelessWidget {
  const _MiniWidget();

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    Widget bar(double width, Color color) => Container(
          width: width,
          height: 3,
          margin: const EdgeInsets.only(top: 5),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        );
    return Container(
      width: 56,
      height: 56,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: p.pronBox,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          bar(18, p.dots),
          bar(32, const Color(0xFF1D5FA7)),
          bar(24, p.text400),
          bar(16, p.dots),
        ],
      ),
    );
  }
}
