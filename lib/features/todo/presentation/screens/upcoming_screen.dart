import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/todo_provider.dart';
import '../widgets/task_card.dart';

class UpcomingScreen extends ConsumerWidget {
  const UpcomingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(todoListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: Text(
          'Upcoming',
          style: GoogleFonts.outfit(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: tasksAsync.when(
        data: (tasks) {
          // Filter: Not completed AND Due Date is after today
          final upcomingTasks = tasks.where((task) {
            if (task.isCompleted) return false;
            if (task.dueDate == null) return false;

            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            // "Upcoming" usually means tomorrow onwards
            return task.dueDate!.isAfter(today
                .add(const Duration(days: 1))
                .subtract(const Duration(milliseconds: 1)));
          }).toList();

          if (upcomingTasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_available_rounded,
                      size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No upcoming tasks',
                    style: GoogleFonts.inter(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: upcomingTasks.length,
            itemBuilder: (context, index) {
              return TaskCard(task: upcomingTasks[index], ref: ref)
                  .animate()
                  .fade()
                  .slideY(
                      delay: (index * 50).ms,
                      duration: 400.ms,
                      curve: Curves.easeOutQuad);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
