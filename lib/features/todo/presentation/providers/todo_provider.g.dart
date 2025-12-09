// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$todoListHash() => r'8982b3884d77d3a6f910e3e37c5723276704b9ba';

/// See also [TodoList].
@ProviderFor(TodoList)
final todoListProvider =
    AutoDisposeAsyncNotifierProvider<TodoList, List<Task>>.internal(
  TodoList.new,
  name: r'todoListProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$todoListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$TodoList = AutoDisposeAsyncNotifier<List<Task>>;
String _$todoFilterHash() => r'23a5fd57f3c30ab237354a4d198f3ad774ec2280';

/// See also [TodoFilter].
@ProviderFor(TodoFilter)
final todoFilterProvider = NotifierProvider<TodoFilter, TaskFilter>.internal(
  TodoFilter.new,
  name: r'todoFilterProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$todoFilterHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$TodoFilter = Notifier<TaskFilter>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
