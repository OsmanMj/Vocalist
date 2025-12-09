import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/todo_provider.dart';
import '../providers/category_provider.dart';
import '../../utils/category_utils.dart';

class AddTaskScreen extends ConsumerStatefulWidget {
  final String? initialCategory;
  const AddTaskScreen({super.key, this.initialCategory});

  @override
  ConsumerState<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends ConsumerState<AddTaskScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late String _category;
  String _priority = 'Medium';
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory ?? 'Work';
  }

  final List<String> _priorities = ['High', 'Medium', 'Low'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF5F33E1),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _saveTask() {
    if (_formKey.currentState!.validate()) {
      ref.read(todoListProvider.notifier).addTask(
            _titleController.text,
            description: _descriptionController.text.isEmpty
                ? null
                : _descriptionController.text,
            category: _category,
            priority: _priority,
            dueDate: _selectedDate,
          );
      Navigator.pop(context);
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF5F33E1)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  // Helper for Priority Icons/Colors
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
    // Watch dynamic categories
    final categories = ref.watch(categoryListProvider);

    // Ensure selected category exists
    if (!categories.contains(_category)) {
      if (categories.isNotEmpty) {
        _category = categories.first;
      } else {
        _category = 'Uncategorized';
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9), // Light grey background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: Text('New Task',
            style: GoogleFonts.outfit(color: Colors.black, fontSize: 20)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: Colors.black),
                decoration: _inputDecoration('Task Title'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                autovalidateMode: AutovalidateMode.onUserInteraction,
              )
                  .animate()
                  .fade(duration: 400.ms)
                  .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad),
              const SizedBox(height: 24),

              // Category & Priority
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _category,
                      dropdownColor: Colors.white,
                      style: const TextStyle(color: Colors.black),
                      decoration: _inputDecoration('Category'),
                      items: categories.map((c) {
                        return DropdownMenuItem(
                          value: c,
                          child: _HoverableCategoryItem(
                              icon: CategoryUtils.getIcon(c), text: c),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _category = v!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _priorities.contains(_priority)
                          ? _priority
                          : 'Medium',
                      dropdownColor: Colors.white,
                      style: const TextStyle(color: Colors.black),
                      decoration: _inputDecoration('Priority'),
                      items: _priorities.map((p) {
                        return DropdownMenuItem(
                          value: p,
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _getPriorityColor(p),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(p),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _priority = v!),
                    ),
                  ),
                ],
              )
                  .animate()
                  .fade(delay: 100.ms, duration: 400.ms)
                  .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad),

              const SizedBox(height: 24),

              // Date Picker
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          color: Colors.grey, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        _selectedDate == null
                            ? 'Select Date (Optional)'
                            : DateFormat('EEE, MMM d, yyyy')
                                .format(_selectedDate!),
                        style: TextStyle(
                            color: _selectedDate == null
                                ? Colors.grey
                                : Colors.black,
                            fontSize: 16),
                      ),
                      const Spacer(),
                      if (_selectedDate != null)
                        InkWell(
                          onTap: () => setState(() => _selectedDate = null),
                          child: const Icon(Icons.close,
                              color: Colors.grey, size: 20),
                        ),
                    ],
                  ),
                ),
              )
                  .animate()
                  .fade(delay: 200.ms, duration: 400.ms)
                  .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad),

              const SizedBox(height: 24),

              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                style: const TextStyle(color: Colors.black),
                decoration: _inputDecoration('Description / Subtasks'),
              )
                  .animate()
                  .fade(delay: 300.ms, duration: 400.ms)
                  .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad),

              const SizedBox(height: 32),

              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5F33E1), // Purple accent
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Save Task',
                    style: GoogleFonts.outfit(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              )
                  .animate()
                  .fade(delay: 400.ms, duration: 400.ms)
                  .scale(curve: Curves.easeOutBack),
            ],
          ),
        ),
      ),
    );
  }
}

class _HoverableCategoryItem extends StatefulWidget {
  final IconData icon;
  final String text;

  const _HoverableCategoryItem({required this.icon, required this.text});

  @override
  State<_HoverableCategoryItem> createState() => _HoverableCategoryItemState();
}

class _HoverableCategoryItemState extends State<_HoverableCategoryItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              widget.icon,
              size: 18,
              color: _isHovered ? const Color(0xFF5F33E1) : Colors.grey[700],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            widget.text,
            style: TextStyle(
              color: _isHovered ? const Color(0xFF5F33E1) : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
