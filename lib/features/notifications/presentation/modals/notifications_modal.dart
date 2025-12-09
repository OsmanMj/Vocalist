import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/notification_provider.dart';

class NotificationsModal extends ConsumerWidget {
  const NotificationsModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32), topRight: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Notifications',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D3142),
                ),
              ),
              if (notifications.isNotEmpty)
                TextButton(
                  onPressed: () {
                    ref.read(notificationProvider.notifier).clearAll();
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Clear All',
                    style: GoogleFonts.inter(color: Colors.redAccent),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          if (notifications.isEmpty)
            Center(
                child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text(
                'No new notifications',
                style: GoogleFonts.inter(color: Colors.grey),
              ),
            ))
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: notifications.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 32, color: Color(0xFFF0F0F0)),
                itemBuilder: (context, index) {
                  final item = notifications[index];
                  return InkWell(
                    onTap: () {
                      ref
                          .read(notificationProvider.notifier)
                          .markAsRead(item.id);
                    },
                    child: Opacity(
                      opacity: item.isRead ? 0.5 : 1.0,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: item.isRead
                                  ? Colors.transparent
                                  : const Color(0xFF5F33E1),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: const Color(0xFF2D3142),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.message,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  DateFormat.jm().format(item.timestamp),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
