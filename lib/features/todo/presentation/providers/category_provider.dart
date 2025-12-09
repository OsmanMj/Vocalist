import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/services/hive_service.dart';

part 'category_provider.g.dart';

@riverpod
class CategoryList extends _$CategoryList {
  static const List<String> _initialDefaults = [
    'Work',
    'Personal',
    'Shopping',
    'Health',
    'Learning'
  ];

  @override
  List<String> build() {
    final box = HiveService.categoryBox;

    // Seed defaults if empty
    if (box.isEmpty) {
      box.addAll(_initialDefaults);
    }

    return box.values.toList();
  }

  Future<void> addCategory(String name) async {
    debugPrint('Adding category: $name');
    final lowerName = name.toLowerCase();
    if (state.any((e) => e.toLowerCase() == lowerName)) {
      debugPrint('Category already exists');
      return;
    }

    final clean = name.trim();
    if (clean.isEmpty) return;
    final capitalized = clean[0].toUpperCase() + clean.substring(1);

    // Optimistic Update
    state = [...state, capitalized];

    // Persist
    await HiveService.categoryBox.add(capitalized);
    debugPrint('Category added to Hive.');
    // We don't strictly need to invalidate if we updated state correctly,
    // but verifying consistency is good. validation can happen later if needed.
  }

  Future<void> deleteCategory(String name) async {
    debugPrint('Deleting category: $name');
    final lowerName = name.toLowerCase();

    // Optimistic Update
    final newState = state.where((e) => e.toLowerCase() != lowerName).toList();
    if (newState.length == state.length) {
      debugPrint('Category not found in state to delete');
      return;
    }
    state = newState;

    // Persist
    final box = HiveService.categoryBox;
    final Map<dynamic, String> map = box.toMap().cast<dynamic, String>();
    dynamic keyToDelete;
    map.forEach((key, value) {
      if (value.toLowerCase() == lowerName) keyToDelete = key;
    });

    if (keyToDelete != null) {
      await box.delete(keyToDelete);
      debugPrint('Category deleted from Hive.');
    }
  }

  Future<void> editCategory(String oldName, String newName) async {
    debugPrint('Editing category: $oldName to $newName');
    final lowerOld = oldName.toLowerCase();

    final index = state.indexWhere((e) => e.toLowerCase() == lowerOld);
    if (index == -1) {
      debugPrint('Category not found in state to edit');
      return;
    }

    final clean = newName.trim();
    if (clean.isEmpty) return;
    final capitalized = clean[0].toUpperCase() + clean.substring(1);

    // Optimistic Update
    final newState = [...state];
    newState[index] = capitalized;
    state = newState;

    // Persist
    final box = HiveService.categoryBox;
    final Map<dynamic, String> map = box.toMap().cast<dynamic, String>();
    dynamic keyToEdit;
    map.forEach((key, value) {
      if (value.toLowerCase() == lowerOld) keyToEdit = key;
    });

    if (keyToEdit != null) {
      await box.put(keyToEdit, capitalized);
      debugPrint('Category updated in Hive.');
    }
  }
}
