import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/supabase_provider.dart';
import '../models/user_profile_model.dart';

class UserProfileNotifier extends AsyncNotifier<UserProfileData> {
  @override
  Future<UserProfileData> build() async {
    final client = ref.watch(supabaseProvider);
    final userId = client.auth.currentUser?.id;
    if (userId == null) return const UserProfileData(name: '');

    final userData = await client
        .from('users')
        .select('nama')
        .eq('id', userId)
        .maybeSingle();

    final name = (userData?['nama'] as String?) ?? '';
    // Keep static store in sync so screens that haven't migrated still see the name
    UserProfileStore.name = name;

    return UserProfileData(
      name: name,
      localImagePath: UserProfileStore.profileImagePath,
    );
  }

  void updateName(String name) {
    final prev = state.valueOrNull ?? const UserProfileData(name: '');
    state = AsyncData(UserProfileData(name: name, localImagePath: prev.localImagePath));
    UserProfileStore.name = name;
  }

  void setLocalImagePath(String? path) {
    final prev = state.valueOrNull ?? const UserProfileData(name: '');
    state = AsyncData(UserProfileData(name: prev.name, localImagePath: path));
    UserProfileStore.profileImagePath = path;
  }

  void clear() {
    UserProfileStore.name = '';
    UserProfileStore.profileImagePath = null;
    state = const AsyncData(UserProfileData(name: ''));
  }
}

final profileProvider =
    AsyncNotifierProvider<UserProfileNotifier, UserProfileData>(
  UserProfileNotifier.new,
);
