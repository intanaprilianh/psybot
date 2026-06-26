class UserProfileStore {
  static String name = '';
  static String? profileImagePath;

  static void saveProfile({
    required String userName,
    String? imagePath,
  }) {
    name = userName;
    profileImagePath = imagePath;
  }

  static String get firstName {
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) return 'User';

    return trimmedName.split(' ').first;
  }

  static bool get hasProfileImage {
    return profileImagePath != null && profileImagePath!.isNotEmpty;
  }
}

class UserProfileData {
  final String name;
  final String? localImagePath;

  const UserProfileData({
    required this.name,
    this.localImagePath,
  });

  String get firstName {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'User';
    return trimmed.split(' ').first;
  }

  UserProfileData copyWith({String? name, String? localImagePath}) {
    return UserProfileData(
      name: name ?? this.name,
      localImagePath: localImagePath ?? this.localImagePath,
    );
  }
}