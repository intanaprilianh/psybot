import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/supabase_provider.dart';
import '../services/mood_service.dart';

final moodServiceProvider = Provider<MoodService>((ref) {
  return MoodService(ref.watch(supabaseProvider));
});

class TodayMoodsNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    return ref.watch(moodServiceProvider).getTodayMoods();
  }
}

final todayMoodsProvider =
    AsyncNotifierProvider<TodayMoodsNotifier, List<Map<String, dynamic>>>(
  TodayMoodsNotifier.new,
);
