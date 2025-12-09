import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/todo_provider.dart';
import '../../utils/category_utils.dart';
import '../../../onboarding/presentation/screens/onboarding_screen.dart';
import '../../../notifications/presentation/widgets/notification_badge.dart';
import '../../../notifications/presentation/modals/notifications_modal.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(todoListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: tasksAsync.when(
        data: (tasks) {
          // Date Logic
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final nextWeek = today.add(const Duration(days: 7));

          // Grouping Helper
          Map<String, List<dynamic>> groupByCategory(List<dynamic> subset) {
            final map = <String, List<dynamic>>{};
            for (final t in subset) {
              map.putIfAbsent(t.category, () => []).add(t);
            }
            return map;
          }

          // Filter Today
          final todayTasks = tasks.where((t) {
            if (t.dueDate == null) return false;
            final d =
                DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
            return d.isAtSameMomentAs(today);
          }).toList();

          // Filter Upcoming
          final upcomingTasks = tasks.where((t) {
            if (t.dueDate == null) return false;
            final d = t.dueDate!;
            return d.isAfter(today) && d.isBefore(nextWeek);
          }).toList();

          final total = tasks.length;
          final completed = tasks.where((t) => t.isCompleted).length;

          final todayMap = groupByCategory(todayTasks);
          final upcomingMap = groupByCategory(upcomingTasks);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48), // Top padding
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Profile & Stats',
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2D3142),
                      ),
                    ),
                    NotificationBadge(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => const NotificationsModal(),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // -----------------------------------------------------------
                // 1. PRODUCTIVITY PULSE (Global Stats)
                // -----------------------------------------------------------
                Text(
                  'Productivity Pulse',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D3142),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Circular Indicator
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CircularProgressIndicator(
                              value: total == 0 ? 0 : completed / total,
                              backgroundColor: const Color(0xFFF0F0F0),
                              valueColor: const AlwaysStoppedAnimation(
                                  Color(0xFF5F33E1)),
                              strokeWidth: 8,
                              strokeCap: StrokeCap.round,
                            ),
                            Center(
                              child: Text(
                                '${(total == 0 ? 0 : (completed / total) * 100).toInt()}%',
                                style: GoogleFonts.outfit(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF5F33E1),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Text Stats
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _StatRow(
                                label: 'Completed',
                                value: '$completed',
                                color: Colors.green),
                            const SizedBox(height: 12),
                            _StatRow(
                                label: 'Pending',
                                value: '${total - completed}',
                                color: Colors.orange),
                            const SizedBox(height: 12),
                            _StatRow(
                                label: 'Total Tasks',
                                value: '$total',
                                color: Colors.grey),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fade().scale(),

                const SizedBox(height: 32),

                // -----------------------------------------------------------
                // 2. TODAY'S TASKS
                // -----------------------------------------------------------
                Text(
                  'Today\'s Tasks',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D3142),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  // If map empty show text, else show horizontal list of rings
                  child: todayMap.isEmpty
                      ? Center(
                          child: Text('No tasks due today',
                              style: GoogleFonts.inter(color: Colors.grey)))
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: todayMap.entries.map((entry) {
                              final catName = entry.key;
                              final catTasks = entry.value;
                              final total = catTasks.length;
                              final completed =
                                  catTasks.where((t) => t.isCompleted).length;
                              final progress =
                                  total == 0 ? 0.0 : completed / total;

                              return Padding(
                                padding: const EdgeInsets.only(right: 24.0),
                                child: _CategoryRing(
                                  category: catName,
                                  progress: progress,
                                  completedCount: completed,
                                  totalCount: total,
                                  color: CategoryUtils.getColor(catName),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                ).animate().fade().slideX(),

                const SizedBox(height: 32),

                // -----------------------------------------------------------
                // 2. UPCOMING TASKS
                // -----------------------------------------------------------
                Text(
                  'Upcoming Tasks',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D3142),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: upcomingMap.isEmpty
                      ? Center(
                          child: Text('No upcoming tasks',
                              style: GoogleFonts.inter(color: Colors.grey)))
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: upcomingMap.entries.map((entry) {
                              final catName = entry.key;
                              final catTasks = entry.value;
                              final total = catTasks.length;
                              final completed =
                                  catTasks.where((t) => t.isCompleted).length;
                              final progress =
                                  total == 0 ? 0.0 : completed / total;

                              return Padding(
                                padding: const EdgeInsets.only(right: 24.0),
                                child: _CategoryRing(
                                  category: catName,
                                  progress: progress,
                                  completedCount: completed,
                                  totalCount: total,
                                  color: CategoryUtils.getColor(catName)
                                      .withOpacity(0.7),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                ).animate().fade().slideX(delay: 100.ms),

                const SizedBox(height: 40),

                // -----------------------------------------------------------
                // 3. DATA MANAGEMENT
                // -----------------------------------------------------------
                Text(
                  'Data Management',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D3142),
                  ),
                ),
                const SizedBox(height: 16),
                _OptionTile(
                  icon: Icons.delete_outline,
                  title: 'Clear History',
                  subtitle: 'Delete all completed tasks',
                  color: Colors.redAccent,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Clear History?'),
                        content: const Text(
                            'This will permanentally delete all completed tasks.'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel')),
                          TextButton(
                              onPressed: () {
                                ref
                                    .read(todoListProvider.notifier)
                                    .deleteCompletedTasks();
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('History Cleared')));
                              },
                              style: TextButton.styleFrom(
                                  foregroundColor: Colors.red),
                              child: const Text('Clear')),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _OptionTile(
                  icon: Icons.restart_alt_rounded,
                  title: 'Reset App Tutorial',
                  subtitle: 'View the welcome screen again',
                  color: const Color(0xFF5F33E1),
                  onTap: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('seenOnboarding', false);
                    if (context.mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                            builder: (_) => const OnboardingScreen()),
                      );
                    }
                  },
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatRow(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(
              color: Colors.grey[600], fontWeight: FontWeight.w500),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.inter(
              fontWeight: FontWeight.bold, color: const Color(0xFF2D3142)),
        ),
      ],
    );
  }
}

class _CategoryRing extends StatelessWidget {
  final String category;
  final double progress;
  final int completedCount;
  final int totalCount;
  final Color color;

  const _CategoryRing({
    required this.category,
    required this.progress,
    required this.completedCount,
    required this.totalCount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 50,
          height: 50,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: progress,
                backgroundColor: color.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation(color),
                strokeWidth: 5,
                strokeCap: StrokeCap.round,
              ),
              Center(
                child: Text(
                  '${(progress * 100).toInt()}%',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          category,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: const Color(0xFF2D3142),
          ),
        ),
        Text(
          '$completedCount / $totalCount',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title,
            style:
                GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16)),
        subtitle: Text(subtitle,
            style: GoogleFonts.inter(color: Colors.grey, fontSize: 13)),
        onTap: onTap,
        trailing:
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      ),
    ).animate().fade().slideX();
  }
}
