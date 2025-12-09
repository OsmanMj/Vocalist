import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../features/todo/data/repositories/todo_repository.dart';
import 'voice_service.dart';
import 'hive_service.dart';

part 'services_provider.g.dart';

@Riverpod(keepAlive: true)
TodoRepository todoRepository(Ref ref) {
  return HiveService.todoRepository;
}

@Riverpod(keepAlive: true)
VoiceService voiceService(Ref ref) {
  return VoiceService();
}
