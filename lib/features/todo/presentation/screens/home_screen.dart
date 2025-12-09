import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/todo_provider.dart';
import '../providers/category_provider.dart';
import '../../utils/category_utils.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';
import 'category_tasks_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Check reminders every minute to keep the bell updated in real-time
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      final tasksAsync = ref.read(todoListProvider);
      tasksAsync.whenData((tasks) {
        ref.read(notificationProvider.notifier).checkReminders(tasks);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryListProvider);
    final tasksAsync = ref.watch(todoListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Color(0xFF5F33E1),
            child: Icon(Icons.check, color: Colors.white),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              'To-do lists',
              style: GoogleFonts.outfit(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D3142),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('EEEE, d.MM.yyyy').format(DateTime.now()),
              style: GoogleFonts.inter(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: tasksAsync.when(
                data: (tasks) {
                  // Initial check
                  Future.microtask(() {
                    ref
                        .read(notificationProvider.notifier)
                        .checkReminders(tasks);
                  });

                  final allItems = ['All tasks', ...categories];

                  return GridView.builder(
                    itemCount: allItems.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.7,
                    ),
                    itemBuilder: (context, index) {
                      final category = allItems[index];
                      final isAllTasks = index == 0;

                      final count = isAllTasks
                          ? tasks.length
                          : tasks
                              .where((t) =>
                                  t.category.toLowerCase() ==
                                  category.toLowerCase())
                              .length;

                      final completedCount = isAllTasks
                          ? tasks.where((t) => t.isCompleted).length
                          : tasks
                              .where((t) =>
                                  t.category.toLowerCase() ==
                                      category.toLowerCase() &&
                                  t.isCompleted)
                              .length;
                      final progress =
                          count == 0 ? 0.0 : completedCount / count;

                      return _CategoryCard(
                        title: category,
                        count: count,
                        progress: progress,
                        isHighlighted: isAllTasks,
                        color: CategoryUtils.getColor(category),
                        icon: CategoryUtils.getIcon(category),
                        onTap: () {
                          final notifier =
                              ref.read(todoFilterProvider.notifier);
                          if (isAllTasks) {
                            notifier.setFilter(FilterType.all);
                          } else {
                            notifier.setFilter(FilterType.category,
                                category: category);
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const CategoryTasksScreen()),
                          );
                        },
                      ).animate().fade().scale(
                          delay: (index * 50).ms,
                          duration: 400.ms,
                          curve: Curves.easeOutBack);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatefulWidget {
  final String title;
  final int count;
  final double progress;
  final bool isHighlighted;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.title,
    required this.count,
    required this.progress,
    required this.isHighlighted,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color:
                widget.isHighlighted ? const Color(0xFF5F33E1) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: widget.isHighlighted
                    ? const Color(0xFF5F33E1).withOpacity(0.4)
                    : const Color(0xFF5F33E1)
                        .withOpacity(_isHovered ? 0.15 : 0.0),
                blurRadius: _isHovered ? 20 : 0,
                offset: Offset(0, _isHovered ? 10 : 0),
                spreadRadius: _isHovered ? -2 : 0,
              ),
              if (!widget.isHighlighted && !_isHovered)
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                )
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (widget.isHighlighted)
                    Text('${(widget.progress * 100).toInt()}%',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: Colors.white70))
                  else
                    Container(),
                  if (!widget.isHighlighted)
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_horiz, color: Colors.grey[300]),
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showEditDialog(context);
                        } else if (value == 'delete') {
                          _confirmDelete(context);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(
                            value: 'delete', child: Text('Delete')),
                      ],
                    ),
                ],
              ),
              if (widget.isHighlighted)
                LinearProgressIndicator(
                  value: widget.progress,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
                ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!widget.isHighlighted)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 48,
                      height: 48,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: _isHovered
                            ? widget.color
                            : widget.color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(widget.icon,
                              color: _isHovered ? Colors.white : widget.color,
                              size: 24)
                          .animate(target: _isHovered ? 1 : 0)
                          .scale(
                              begin: const Offset(1, 1),
                              end: const Offset(1.1, 1.1),
                              duration: 200.ms,
                              curve: Curves.easeOutBack),
                    ),
                  Text(
                    widget.title,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: widget.isHighlighted
                          ? Colors.white
                          : const Color(0xFF2D3142),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.count} items',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color:
                          widget.isHighlighted ? Colors.white70 : Colors.grey,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final controller = TextEditingController(text: widget.title);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Category'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          Consumer(builder: (context, ref, _) {
            return TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  ref
                      .read(categoryListProvider.notifier)
                      .editCategory(widget.title, controller.text);
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            );
          }),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text('Are you sure you want to delete "${widget.title}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          Consumer(builder: (context, ref, _) {
            return TextButton(
              onPressed: () {
                ref
                    .read(categoryListProvider.notifier)
                    .deleteCategory(widget.title);
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            );
          }),
        ],
      ),
    );
  }
}
