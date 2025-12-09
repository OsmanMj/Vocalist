import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/todo_provider.dart';
import '../../data/models/task_model.dart';
import '../../utils/category_utils.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final WidgetRef ref;
  const TaskCard({super.key, required this.task, required this.ref});

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = task.isCompleted;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: ListTile(
        onTap: () => ref.read(todoListProvider.notifier).toggleTask(task),
        leading: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: isCompleted ? Colors.purple : Colors.grey, width: 2),
            color: isCompleted ? Colors.purple : Colors.white,
          ),
          child: isCompleted
              ? const Icon(Icons.check, size: 14, color: Colors.white)
              : null,
        ),
        title: Text(task.title,
            style: GoogleFonts.inter(
                decoration: isCompleted ? TextDecoration.lineThrough : null,
                fontWeight: FontWeight.w600)),
        subtitle: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Priority
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _getPriorityColor(task.priority),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(task.priority,
                  style: GoogleFonts.inter(color: Colors.grey, fontSize: 13)),

              const SizedBox(width: 8),
              Text('•', style: GoogleFonts.inter(color: Colors.grey)),
              const SizedBox(width: 8),

              // Category
              Icon(CategoryUtils.getIcon(task.category),
                  size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(task.category, style: GoogleFonts.inter(color: Colors.grey)),

              // Due Date (Optional)
              if (task.dueDate != null) ...[
                const SizedBox(width: 8),
                Text('•', style: GoogleFonts.inter(color: Colors.grey)),
                const SizedBox(width: 8),
                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM d').format(task.dueDate!),
                  style: GoogleFonts.inter(color: Colors.grey),
                ),
              ],
            ],
          ),
        ),
        trailing: _AnimatedTrashIcon(
          onTap: () => ref.read(todoListProvider.notifier).deleteTask(task.id),
        ),
      ),
    );
  }
}

class _AnimatedTrashIcon extends StatefulWidget {
  final VoidCallback onTap;
  const _AnimatedTrashIcon({required this.onTap});

  @override
  State<_AnimatedTrashIcon> createState() => _AnimatedTrashIconState();
}

class _AnimatedTrashIconState extends State<_AnimatedTrashIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 40,
          height: 40,
          color: Colors.transparent, // Hit test area
          alignment: Alignment.center,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return SizedBox(
                width: 24,
                height: 24,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Bin (Static body)
                    Positioned(
                      bottom: 4,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border.all(
                            color: _isHovered ? Colors.red : Colors.grey[400]!,
                            width: 2,
                          ),
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    // Vertical lines on bin
                    Positioned(
                      bottom: 7,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                              width: 2,
                              height: 6,
                              color:
                                  _isHovered ? Colors.red : Colors.grey[400]!),
                          const SizedBox(width: 2),
                          Container(
                              width: 2,
                              height: 6,
                              color:
                                  _isHovered ? Colors.red : Colors.grey[400]!),
                        ],
                      ),
                    ),

                    // Lid (Animated)
                    Positioned(
                      top: 4, // Initial closed position
                      child: Transform.translate(
                        offset: Offset(
                            2, -2 * _controller.value), // Lift up slightly
                        child: Transform.rotate(
                          angle: -0.5 * _controller.value, // Rotate ~30 degrees
                          alignment: Alignment.bottomRight, // Hinge on right
                          child: Column(
                            children: [
                              // Handle
                              Container(
                                width: 4,
                                height: 2,
                                color:
                                    _isHovered ? Colors.red : Colors.grey[400]!,
                              ),
                              // Lid Body
                              Container(
                                width: 16,
                                height: 2,
                                decoration: BoxDecoration(
                                  color: _isHovered
                                      ? Colors.red
                                      : Colors.grey[400]!,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
