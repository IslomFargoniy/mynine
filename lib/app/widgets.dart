import 'package:flutter/material.dart';

import '../data/repositories/sync_service.dart';
import 'theme.dart';

/// White card centred on the grey canvas (code / rules / completed screens).
class CenterCard extends StatelessWidget {
  const CenterCard({super.key, required this.child, this.maxWidth = 720});

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
              border: Border.all(color: AppColors.border),
              boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4))],
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
