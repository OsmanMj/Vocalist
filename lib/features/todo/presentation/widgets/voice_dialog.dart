import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/todo_provider.dart';
import '../providers/category_provider.dart';
import '../../../../core/services/services_provider.dart';
import '../../data/models/task_model.dart';
import '../screens/category_tasks_screen.dart';
import '../screens/upcoming_screen.dart';
import '../screens/completed_screen.dart';

class VoiceListeningDialog extends ConsumerStatefulWidget {
  const VoiceListeningDialog({super.key});

  @override
  ConsumerState<VoiceListeningDialog> createState() =>
      _VoiceListeningDialogState();
}

class _VoiceListeningDialogState extends ConsumerState<VoiceListeningDialog>
    with SingleTickerProviderStateMixin {
  String _text = 'Listening...';
  String _status = 'Listening';
  bool _isProcessing = false;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _startListening();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startListening() async {
    try {
      final voiceService = ref.read(voiceServiceProvider);
      await voiceService.startListening(
          onResult: (text) => setState(() => _text = text),
          onDone: (finalText) {
            if (!_isProcessing && mounted) _processCommand(finalText);
          },
          onError: (errorMsg) {
            if (mounted) {
              String userMsg = errorMsg;
              if (errorMsg.contains('network') ||
                  errorMsg.contains('error_7') ||
                  errorMsg.contains('error_2') ||
                  errorMsg.contains('error_language_unavailable') ||
                  errorMsg.contains('error_language_not_supported')) {
                userMsg =
                    'No Internet Connection.\nPlease check your settings.';
              } else if (errorMsg.contains('speech_not_available')) {
                userMsg = 'Speech service not available.';
              }

              setState(() {
                _status = 'Error';
                _text = userMsg;
              });
              debugPrint('Voice Service Reported Error: $errorMsg');
            }
          });
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = 'Error';
          _text = e.toString().contains('MissingPluginException')
              ? 'Error: App rebuild required.\nPlease run "flutter clean" and "flutter run".'
              : 'Error: ${e.toString()}';
        });
        debugPrint('Voice Dialog Error: $e');
      }
    }
  }

  // Pre-compiled Regex patterns for better performance and consistency
  // Adjusted to match "create/make/new ... category" (excluding "add" to avoid conflict with tasks)
  final _addCategoryRegex =
      RegExp(r'^(?:create|make|new)\s+.*category.*', caseSensitive: false);

  final _deleteCategoryRegex =
      RegExp(r'(?:delete|remove)\s+(?:category)?', caseSensitive: false);
  final _editCategoryRegex =
      RegExp(r'(?:edit|rename|change)\s+(?:category)?', caseSensitive: false);
  final _deleteTaskRegex =
      RegExp(r'(?:delete|remove)\s+(?:task)?', caseSensitive: false);

  Future<void> _processCommand(String text) async {
    if (text.isEmpty) {
      if (mounted) Navigator.pop(context);
      return;
    }
    setState(() {
      _isProcessing = true;
      _status = 'Processing';
    });

    // Handle specific error messages from service
    if (text.startsWith("Error:")) {
      _finish(text.replaceFirst("Error: ", ""), isError: true);
      return;
    }

    final lower = text.toLowerCase().trim();
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    try {
      // 1. ADD CATEGORY
      // Matches: "add category Work", "create new category Personal", "add gym category"
      // We check this explicitly first.
      if (_addCategoryRegex.hasMatch(lower)) {
        _handleAddCategory(text);
        return;
      }
      // Fallback for strict "category" usage if regex missed but intent is clear?
      // No, regex above is quite broad (starts with add + contains category).

      // 2. RENAME CATEGORY
      // ... (rest remains same)
      if (_editCategoryRegex.hasMatch(lower) && lower.contains(' to ')) {
        _handleEditCategory(text);
        return;
      }

      // 3. DELETE CATEGORY
      if (_deleteCategoryRegex.hasMatch(lower) && lower.contains('category')) {
        _handleDeleteCategory(text);
        return;
      }

      // ... (rest remains same)
      if (_deleteTaskRegex.hasMatch(lower)) {
        _handleDelete(text);
        return;
      }

      // ... (status updates)
      bool isMark = lower.startsWith('mark') || lower.startsWith('set');
      if (lower.startsWith('uncheck') ||
          (isMark &&
              (lower.contains('incomplete') || lower.contains('not done')))) {
        _setTaskStatus(text, false);
        return;
      }
      if (isMark && (lower.contains('complete') || lower.contains('done'))) {
        _setTaskStatus(text, true);
        return;
      }

      // ... (show/filter)
      if (lower.startsWith('show') || lower.contains('what are my tasks')) {
        _handleFilter(text, lower);
        return;
      }

      // 7. DEFAULT: ADD TASK
      _handleAdd(text);
    } catch (e) {
      if (mounted) {
        setState(() => _status = 'Error: $e');
        debugPrint('Voice Command Error: $e');
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) Navigator.pop(context);
        });
      }
    }
  }

  Future<void> _handleAddCategory(String text) async {
    // text: "add category Work" OR "add Work category"
    // Remove "add", "create", "new", "category"
    String name = text;
    final cleanupRegex =
        RegExp(r'(?:add|create|make|new|category)', caseSensitive: false);

    // Replace known keywords with empty space
    name = name.replaceAll(cleanupRegex, '');

    // Clean up valid but annoying punctuation & extra spaces
    name = name.replaceAll(RegExp(r'[^\w\s]'), '').trim();
    name = name.replaceAll(RegExp(r'\s+'), ' '); // normalize spaces

    if (name.isNotEmpty) {
      await ref.read(categoryListProvider.notifier).addCategory(name);
      _finish('Category "$name" added');
    } else {
      _finish('Say "Add category [Name]"', isError: true);
    }
  }

  Future<void> _handleDeleteCategory(String text) async {
    // text: "delete category Work"
    // Clean key words
    String rawName = text
        .replaceAll(_deleteCategoryRegex, '')
        .replaceAll('category', '')
        .trim();
    if (rawName.isEmpty) {
      _finish('Say "Delete category [Name]"', isError: true);
      return;
    }

    final categories = ref.read(categoryListProvider);
    // Find best match
    final match = _findBestMatch(rawName, categories);

    if (match != null) {
      await ref.read(categoryListProvider.notifier).deleteCategory(match);
      _finish('Deleted category "$match"');
    } else {
      _finish('Category "$rawName" not found', isError: true);
    }
  }

  Future<void> _handleEditCategory(String text) async {
    // text: "rename category Work to Office"
    String clean = text.replaceAll(_editCategoryRegex, '').trim();

    // Split by "to"
    final parts = clean.split(RegExp(r'\s+to\s+', caseSensitive: false));
    if (parts.length < 2) {
      _finish('Say "Rename category X to Y"', isError: true);
      return;
    }

    String oldNameRaw = parts[0].trim();
    String newName = parts[1].trim();

    // Remove "category" noise from the name if user said "rename category Work..."
    oldNameRaw = oldNameRaw.replaceAll('category', '').trim();

    if (oldNameRaw.isEmpty || newName.isEmpty) {
      _finish('Category names missing', isError: true);
      return;
    }

    final categories = ref.read(categoryListProvider);
    final match = _findBestMatch(oldNameRaw, categories);

    if (match != null) {
      await ref
          .read(categoryListProvider.notifier)
          .editCategory(match, newName);
      _finish('Renamed to "$newName"');
    } else {
      _finish('Category "$oldNameRaw" not found', isError: true);
    }
  }

  // Helper to find existing items flexibly
  String? _findBestMatch(String query, List<String> items) {
    final q = query.toLowerCase();

    // 1. Exact match (insensitive)
    try {
      return items.firstWhere((i) => i.toLowerCase() == q);
    } catch (_) {}

    // 2. Contains match
    try {
      return items.firstWhere((i) => i.toLowerCase().contains(q));
    } catch (_) {}

    // 3. Reverse contains (if user said partial name)
    try {
      return items.firstWhere((i) => q.contains(i.toLowerCase()));
    } catch (_) {}

    return null;
  }

  void _handleFilter(String text, String lower) {
    final notifier = ref.read(todoFilterProvider.notifier);
    final currentFilter = ref.read(todoFilterProvider);

    // Dynamic Category Matching
    final categories = ref.read(categoryListProvider);
    String? foundCategory;
    for (final cat in categories) {
      if (lower.contains(cat.toLowerCase())) {
        foundCategory = cat;
        break;
      }
    }

    if (foundCategory != null) {
      notifier.setFilter(FilterType.category, category: foundCategory);
      _finish('Showing $foundCategory tasks', onNext: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const CategoryTasksScreen()));
      });
    } else if (lower.contains('today') || lower.contains('taody')) {
      // CONTEXT AWARE LOGIC FOR TODAY:
      if (currentFilter.type == FilterType.category ||
          currentFilter.type == FilterType.categoryUpcoming ||
          currentFilter.type == FilterType.categoryToday) {
        notifier.setFilter(FilterType.categoryToday,
            category: currentFilter.category);
        _finish('Showing Today in ${currentFilter.category}', onNext: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const CategoryTasksScreen()));
        });
      } else {
        notifier.setFilter(FilterType.today);
        _finish('Showing Today', onNext: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const CategoryTasksScreen()));
        });
      }
    } else if (lower.contains('tomorrow') || lower.contains('tomoorow')) {
      notifier.setFilter(FilterType.tomorrow);
      _finish('Showing Tomorrow', onNext: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const CategoryTasksScreen()));
      });
    } else if (lower.contains('next week') || lower.contains('upcoming')) {
      // CONTEXT AWARE LOGIC:
      // If we are already inside a category, show upcoming tasks FOR THAT CATEGORY.
      if (currentFilter.type == FilterType.category ||
          currentFilter.type == FilterType.categoryUpcoming) {
        notifier.setFilter(FilterType.categoryUpcoming,
            category: currentFilter.category);
        _finish('Showing Upcoming in ${currentFilter.category}', onNext: () {
          // Push CategoryTasksScreen again to refresh/ensure we are on the list view
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const CategoryTasksScreen()));
        });
      } else {
        // Otherwise, go to global Upcoming screen
        _finish('Showing Upcoming', onNext: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const UpcomingScreen()));
        });
      }
    } else if (lower.contains('complete') ||
        lower.contains('done') ||
        lower.contains('history') ||
        lower.contains('finished')) {
      _finish('Showing Completed', onNext: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const CompletedScreen()));
      });
    } else if (lower.contains('all') ||
        lower.contains('show me my tasks') ||
        lower.contains('show all my task')) {
      notifier.setFilter(FilterType.all);
      _finish('Showing All', onNext: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const CategoryTasksScreen()));
      });
    } else {
      notifier.setFilter(FilterType.all);
      _finish('Showing All', onNext: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const CategoryTasksScreen()));
      });
    }
  }

  // Keeping this for tasks
  void _handleDelete(String text) {
    String targetName = text.replaceAll(_deleteTaskRegex, '').trim();
    final tasks = ref.read(todoListProvider).valueOrNull ?? [];
    final task = tasks.cast<Task?>().firstWhere(
        (t) => t!.title.toLowerCase().contains(targetName),
        orElse: () => null);
    if (task != null) {
      ref.read(todoListProvider.notifier).deleteTask(task.id);
      _finish('Deleted "${task.title}"');
    } else {
      _finish('Not found', isError: true);
    }
  }

  void _setTaskStatus(String text, bool state) {
    String targetName = _removePhrase(
            text, ['uncheck', 'mark', 'as', 'complete', 'done', 'task'])
        .toLowerCase();
    final tasks = ref.read(todoListProvider).valueOrNull ?? [];
    final task = tasks.cast<Task?>().firstWhere(
        (t) => t!.title.toLowerCase().contains(targetName),
        orElse: () => null);
    if (task != null) {
      ref.read(todoListProvider.notifier).toggleTask(task);
      _finish('Updated "${task.title}"');
    } else {
      _finish('Not found', isError: true);
    }
  }

  void _handleAdd(String text) {
    String cleanTitle = text;
    final lower = text.toLowerCase();

    // Priority
    String priority = 'Medium';
    if (lower.contains('priority high') || lower.contains('urgent')) {
      priority = 'High';
      cleanTitle = _removePhrase(cleanTitle, ['priority high', 'urgent']);
    } else if (lower.contains('priority low')) {
      priority = 'Low';
      cleanTitle = _removePhrase(cleanTitle, ['priority low']);
    }

    DateTime? dueDate;
    DateTime now = DateTime.now();

    // 1. Relative Time: "after 5 minutes", "in 1 hour", "after 3 days"
    // Regex matches: (after|in) (digits) (minute|hour|sec|day)
    final relativeRegex = RegExp(
        r'(?:after|in)\s+(\d+)\s+(minute|min|hour|hr|second|sec|day)s?',
        caseSensitive: false);
    final relativeMatch = relativeRegex.firstMatch(lower);

    if (relativeMatch != null) {
      int amount = int.parse(relativeMatch.group(1)!);
      String unit = relativeMatch.group(2)!.toLowerCase();

      if (unit.startsWith('min')) {
        dueDate = now.add(Duration(minutes: amount));
      } else if (unit.startsWith('hour') || unit.startsWith('hr')) {
        dueDate = now.add(Duration(hours: amount));
      } else if (unit.startsWith('sec')) {
        dueDate = now.add(Duration(seconds: amount));
      } else if (unit.startsWith('day')) {
        dueDate = now.add(Duration(days: amount));
      }
      cleanTitle = cleanTitle.replaceAll(
          relativeMatch.group(0)!, ''); // Remove the specific match
    }

    // 2. Absolute Time: "at 5pm", "at 19:00", "today at 7"
    if (dueDate == null) {
      // Check for day keywords foundation
      DateTime baseDate = now;
      if (lower.contains('tomorrow')) {
        baseDate = now.add(const Duration(days: 1));
        cleanTitle = _removePhrase(cleanTitle, ['tomorrow']);
      } else if (lower.contains('today')) {
        cleanTitle = _removePhrase(cleanTitle, ['today']);
      }

      // Explicit Date Parsing: "on 12th Dec", "on Dec 12", "on 12 December"
      // Regex: on (day)(st/nd/rd/th)? (month)  OR  on (month) (day)(st/nd/rd/th)?
      final dateRegex1 = RegExp(r'on\s+(\d{1,2})(?:st|nd|rd|th)?\s+([a-zA-Z]+)',
          caseSensitive: false);
      final dateRegex2 = RegExp(r'on\s+([a-zA-Z]+)\s+(\d{1,2})(?:st|nd|rd|th)?',
          caseSensitive: false);

      Match? dateMatch =
          dateRegex1.firstMatch(lower) ?? dateRegex2.firstMatch(lower);

      if (dateMatch != null) {
        int? d;
        String? mStr;

        if (dateMatch.pattern == dateRegex1) {
          d = int.parse(dateMatch.group(1)!);
          mStr = dateMatch.group(2);
        } else {
          mStr = dateMatch.group(1);
          d = int.parse(dateMatch.group(2)!);
        }

        int? month = _parseMonth(mStr!);
        if (month != null && d != null) {
          // Year logic: if date is in past relative to today, assume next year?
          // Or defaulting to current year.
          int year = now.year;
          DateTime tentative = DateTime(year, month, d);
          if (tentative.isBefore(DateTime(now.year, now.month, now.day))) {
            // If it's explicitly e.g. "on 1st Jan" and today is "5th Jan", maybe user means next year?
            // For now let's keep it simple: current year unless user specifies year (not implemented yet).
            // Actually, for a todo list, usually upcoming.
            tentative = DateTime(year + 1, month, d);
          }
          // However, if the user says "on Dec 12" and it's Dec 9, it's current year.
          // If user says "on Jan 1" and it's Dec, it's next year.
          // Let's refine:
          tentative = DateTime(now.year, month, d);
          if (tentative.isBefore(DateTime(now.year, now.month, now.day))) {
            tentative = DateTime(now.year + 1, month, d);
          }

          baseDate = tentative;
          cleanTitle = cleanTitle.replaceAll(dateMatch.group(0)!, '');

          // Force set dueDate base so checking time below uses this date
          // If no time is specified later, we default to this date at 9 AM or current time?
          // Let's set it here.
          dueDate = baseDate;
        }
      }

      // Regex for time: at 5:30pm, at 19:00, at 5 pm, at 5
      final timeRegex = RegExp(r'at\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?');
      final timeMatch = timeRegex.firstMatch(lower);

      if (timeMatch != null) {
        int hour = int.parse(timeMatch.group(1)!);
        int minute =
            timeMatch.group(2) != null ? int.parse(timeMatch.group(2)!) : 0;
        String? period = timeMatch.group(3);

        // Convert to 24h
        if (period != null) {
          if (period == 'pm' && hour < 12) hour += 12;
          if (period == 'am' && hour == 12) hour = 0;
        } else if (hour < 12 && !lower.contains('morning')) {
          if (hour >= 1 && hour <= 11) {
            if (hour < 7) hour += 12; // "at 1" -> 13:00, "at 6" -> 18:00
          }
        }

        // Apply time to the baseDate (which might be Today, Tomorrow, or Explicit Date)
        dueDate =
            DateTime(baseDate.year, baseDate.month, baseDate.day, hour, minute);

        // If the resulting time is in the past (e.g. "at 9am" but it's 2pm), add a day?
        // Only if user didn't explicitly say "today" or a specific date.
        // If we haven't set a specific date (dateMatch == null) and no "tomorrow", check PAST.
        if (dateMatch == null &&
            !lower.contains('tomorrow') &&
            !lower.contains('today')) {
          if (dueDate!.isBefore(now)) {
            dueDate = dueDate!.add(const Duration(days: 1));
          }
        }

        cleanTitle = cleanTitle.replaceAll(timeRegex, '');
      } else if (dueDate != null && dateMatch != null) {
        // We have a date but no time (e.g. "on 12th Dec").
        // Set to default time? Or start of day?
        // Let's default to not setting a specific time so it's an "All Day" thing?
        // But our basic Task model uses DateTime as a point in time.
        // Let's Default to 9:00 AM if no time specified for a future date.
        dueDate = DateTime(dueDate!.year, dueDate!.month, dueDate!.day, 9, 0);
      }
    }

    // Fallback Date Logic (just days) to catch explicit "tomorrow/today" without time
    if (dueDate == null) {
      DateTime addDays(int d) => DateTime.now().add(Duration(days: d));
      if (lower.contains('today')) {
        // Default to end of day? Or just mark date?
        // Let's use 6 PM for general "today" tasks if no time match
        final d = addDays(0);
        dueDate = DateTime(d.year, d.month, d.day, 18, 0);
        cleanTitle = _removePhrase(cleanTitle, ['today']);
      } else if (lower.contains('tomorrow')) {
        final d = addDays(1);
        dueDate = DateTime(d.year, d.month, d.day, 9, 0);
        cleanTitle = _removePhrase(cleanTitle, ['tomorrow']);
      }
    }

    // Category Logic - Dynamic
    String category = 'Uncategorized';
    bool categoryFound = false;

    // 1. Check if category is explicitly mentioned
    final categories = ref.read(categoryListProvider);
    for (final cat in categories) {
      if (lower.contains(cat.toLowerCase())) {
        category = cat;
        cleanTitle = _removePhrase(cleanTitle, [cat, 'category']);
        categoryFound = true;
        break;
      }
    }

    // 2. If not mentioned, check current screen context
    if (!categoryFound) {
      final filter = ref.read(todoFilterProvider);
      if (filter.type == FilterType.category && filter.category != null) {
        category = filter.category!;
      }
    }

    // Cleanup
    cleanTitle =
        _removePhrase(cleanTitle, ['add task', 'create task', 'add', 'task']);

    // Remove lingering "at" or "after" if regex didn't catch them seamlessly or if they were detached
    cleanTitle = cleanTitle.replaceAll(
        RegExp(r'\b(at|after|in)\b\s*$', caseSensitive: false), '');

    cleanTitle = cleanTitle.trim();
    if (cleanTitle.isNotEmpty)
      cleanTitle = cleanTitle[0].toUpperCase() + cleanTitle.substring(1);

    if (cleanTitle.isNotEmpty) {
      ref.read(todoListProvider.notifier).addTask(cleanTitle,
          category: category, priority: priority, dueDate: dueDate);

      String response = 'Added "$cleanTitle"';
      if (dueDate != null) {
        // Simple format for feedback
        String timeStr =
            "${dueDate.hour}:${dueDate.minute.toString().padLeft(2, '0')}";
        response += " for $timeStr";
      }
      _finish(response);
    } else {
      _finish('Error', isError: true);
    }
  }

  void _finish(String msg, {bool isError = false, VoidCallback? onNext}) {
    if (mounted) {
      setState(() {
        _text = msg;
        _status = isError ? 'Error' : 'Success';
      });
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pop(context);
          onNext?.call();
        }
      });
    }
  }

  String _removePhrase(String text, List<String> phrases) {
    String result = text;
    for (final phrase in phrases)
      result = result.replaceAll(RegExp(phrase, caseSensitive: false), '');
    return result.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  int? _parseMonth(String monthStr) {
    final m = monthStr.toLowerCase();
    switch (m.substring(0, 3)) {
      case 'jan':
        return 1;
      case 'feb':
        return 2;
      case 'mar':
        return 3;
      case 'apr':
        return 4;
      case 'may':
        return 5;
      case 'jun':
        return 6;
      case 'jul':
        return 7;
      case 'aug':
        return 8;
      case 'sep':
        return 9;
      case 'oct':
        return 10;
      case 'nov':
        return 11;
      case 'dec':
        return 12;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    Color iconColor = _status == 'Success'
        ? Colors.green
        : (_status == 'Error' ? Colors.red : Colors.purple);
    return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.mic, size: 48, color: iconColor)
              .animate()
              .scale(duration: 500.ms, curve: Curves.elasticOut),
          const SizedBox(height: 16),
          Text(_text, textAlign: TextAlign.center, style: GoogleFonts.inter())
        ]));
  }
}
