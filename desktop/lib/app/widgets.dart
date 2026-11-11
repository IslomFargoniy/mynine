import 'package:flutter/material.dart';

import '../core/theme/web_tokens.dart';
import '../data/repositories/sync_service.dart';
import 'theme.dart';

/// White card centred on the grey canvas — the web module-selection card
/// (index.tsx: `bg-white p-8 md:p-10 max-w-3xl border border-gray-300 shadow-md`).
class CenterCard extends StatelessWidget {
  const CenterCard({super.key, required this.child, this.maxWidth = 768});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: TW.gray300),
              boxShadow: const [
                BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 4), spreadRadius: -1),
                BoxShadow(color: Color(0x1A000000), blurRadius: 4, offset: Offset(0, 2), spreadRadius: -2),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class IeltsBadge extends StatelessWidget {
  const IeltsBadge({super.key, this.label = 'IELTS'});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: AppColors.ieltsRed, borderRadius: BorderRadius.circular(2)),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: -0.2),
        ),
      );
}

/// Green/red dot with "Online"/"Offline".
class ConnectionIndicator extends StatelessWidget {
  const ConnectionIndicator({super.key, required this.connection, this.sync, this.compact = false});

  final ConnectionStatus connection;
  final SyncService? sync;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([connection, ?sync]),
      builder: (context, _) {
        final online = connection.online;
        final pending = sync?.pendingAnswers ?? 0;
        final color = !online
            ? Colors.red
            : pending > 0
                ? Colors.amber.shade700
                : Colors.green.shade600;
        final label = !online
            ? 'Offline – answers are saved on this computer'
            : pending > 0
                ? 'Saving answers ($pending)…'
                : 'Online';
        return Tooltip(
          message: label,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(online ? Icons.wifi : Icons.wifi_off, size: 18, color: color),
              if (!compact) ...[
                const SizedBox(width: 6),
                Text(online ? (pending > 0 ? 'Saving…' : 'Online') : 'Offline',
                    style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Card heading block: `text-3xl font-bold tracking-tight` + `text-gray-600 mt-2`
/// inside `border-b-2 border-gray-200 pb-4 mb-6`.
class CardHeading extends StatelessWidget {
  const CardHeading({super.key, required this.title, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.only(bottom: 16),
        margin: const EdgeInsets.only(bottom: 24),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: TW.gray200, width: 2))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: inter(30, weight: FontWeight.w700, color: TW.gray900, letterSpacing: -0.75, height: 1.2)),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(subtitle!, style: inter(16, color: TW.gray600)),
          ],
        ]),
      );
}

/// index.tsx loading state: `w-12 h-12 border-4 border-black border-t-transparent
/// rounded-full animate-spin` + `LOADING...` (uppercase, tracking-widest, pulse).
class WebSpinner extends StatelessWidget {
  const WebSpinner({super.key, this.label = 'Loading...'});
  final String label;

  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(
          width: 48,
          height: 48,
          child: CircularProgressIndicator(strokeWidth: 4, color: TW.black, strokeCap: StrokeCap.butt),
        ),
        const SizedBox(height: 16),
        Text(label.toUpperCase(),
            textAlign: TextAlign.center,
            style: inter(18, weight: FontWeight.w500, color: TW.gray900, letterSpacing: 1.8)),
      ]);
}

/// Black action button `px-6 py-2 bg-black text-white font-semibold rounded-[2px]
/// uppercase tracking-wide text-sm` with "➔".
class BlackButton extends StatelessWidget {
  const BlackButton({super.key, required this.label, required this.onTap, this.arrow = true});
  final String label;
  final VoidCallback? onTap;
  final bool arrow;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          // Focusable: Tab + Enter/Space work like the web <button>.
          onTap: onTap,
          child: Opacity(
            opacity: onTap == null ? 0.6 : 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: const BoxDecoration(color: TW.black, borderRadius: WebTokens.r2),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(label.toUpperCase(),
                    style: inter(14, weight: FontWeight.w600, color: Colors.white, letterSpacing: 0.35)),
                if (arrow) ...[
                  const SizedBox(width: 8),
                  Text('➔', style: inter(14, color: Colors.white)),
                ],
              ]),
            ),
          ),
        ),
      );
}

/// Exam-room number of this PC ("PC 7"), given by the Admin on approval.
class PcNumberBadge extends StatelessWidget {
  const PcNumberBadge({super.key, required this.number, this.large = false});

  final int number;
  final bool large;

  @override
  Widget build(BuildContext context) => Container(
        key: const Key('pc-number'),
        padding: EdgeInsets.symmetric(horizontal: large ? 18 : 8, vertical: large ? 8 : 3),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(large ? 10 : 4),
        ),
        child: Text(
          'PC $number',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: large ? 30 : 13,
            letterSpacing: large ? 1 : 0.2,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      );
}
