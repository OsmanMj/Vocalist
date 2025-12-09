import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/todo_provider.dart';
import '../widgets/task_card.dart';
import '../widgets/voice_dialog.dart';
import 'add_task_screen.dart';

class CategoryTasksScreen extends ConsumerWidget {
  const CategoryTasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(todoListProvider);
    final filter = ref.watch(todoFilterProvider);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          // Reset filter when leaving this screen
          // We use Future.microtask to avoid modifying provider parsing process if called during build (though pop usually happens on event)
          Future.microtask(() {
            // Smart Navigation Logic:
            // If we are deep in a category context (e.g. Today Work), go back to the Category (Work).
            // If we are just in a Category or Global list, go back to All (Main Screen).
            if (filter.type == FilterType.categoryToday ||
                filter.type == FilterType.categoryUpcoming) {
              ref
                  .read(todoFilterProvider.notifier)
                  .setFilter(FilterType.category, category: filter.category);
            } else {
              ref.read(todoFilterProvider.notifier).setFilter(FilterType.all);
            }
          });
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F9F9),
        appBar: AppBar(
          title: Text(
            filter.type == FilterType.all
                ? 'All Tasks'
                : filter.type == FilterType.today
                    ? 'Today'
                    : filter.type == FilterType.categoryToday
                        ? 'Today ${filter.category}'
                        : filter.type == FilterType.tomorrow
                            ? 'Tomorrow'
                            : filter.type == FilterType.upcoming
                                ? 'Upcoming'
                                : filter.type == FilterType.categoryUpcoming
                                    ? 'Upcoming ${filter.category}'
                                    : filter.category ?? 'Tasks',
            style: GoogleFonts.outfit(
                color: Colors.black, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const BackButton(color: Colors.black),
          actions: [
            IconButton(
              icon: const Icon(Icons.add, color: Colors.black),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => AddTaskScreen(
                            initialCategory: filter.type == FilterType.category
                                ? filter.category
                                : null,
                          )),
                );
              },
            ),
          ],
        ),
        body: tasksAsync.when(
          data: (tasks) {
            final filteredTasks =
                tasks.where((t) => filter.matches(t)).toList();
            if (filteredTasks.isEmpty) {
              return Center(
                  child: Text('No tasks.',
                      style: GoogleFonts.inter(color: Colors.grey)));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredTasks.length,
              itemBuilder: (context, index) {
                final task = filteredTasks[index];
                return TaskCard(task: task, ref: ref).animate().fade().slideY(
                    duration: 400.ms,
                    delay: (index * 50).ms,
                    curve: Curves.easeOutQuad);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'voice_fab_list',
          onPressed: () => showDialog(
              context: context, builder: (_) => const VoiceListeningDialog()),
          backgroundColor: const Color(0xFF5F33E1),
          child: const Icon(Icons.mic, color: Colors.white),
        ),
      ),
    );
  }
}
