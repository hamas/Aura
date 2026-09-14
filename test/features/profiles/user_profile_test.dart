import 'package:flutter_test/flutter_test.dart';
import 'package:aura/features/profiles/domain/entities/user_profile.dart';
import 'package:aura/features/profiles/data/models/user_profile_model.dart';

void main() {
  group('UserProfile & UserProfileModel Tests', () {
    final now = DateTime.now();

    test('UserProfile evaluates pin protection accurately', () {
      final adult = UserProfile(
        id: 'p1',
        name: 'Adult',
        avatarPath: '',
        pinHash: UserProfile.hashPin('1234'),
        createdAt: now,
      );

      final kids = UserProfile(
        id: 'p2',
        name: 'Kids',
        avatarPath: '',
        isKids: true,
        createdAt: now,
      );

      expect(adult.hasPin, true);
      expect(adult.verifyPin('1234'), true);
      expect(adult.verifyPin('9999'), false);
      expect(kids.hasPin, false);
    });

    test('UserProfileModel serialization roundtrip works correctly', () {
      final model = UserProfileModel(
        id: 'p1',
        name: 'Alice',
        avatarPath: 'https://example.com/avatar.png',
        isKids: true,
        pinHash: UserProfile.hashPin('9999'),
        maxAgeRating: 'PG',
        createdAt: now,
      );

      final json = model.toJson();
      final restored = UserProfileModel.fromJson(json);

      expect(restored.id, model.id);
      expect(restored.name, model.name);
      expect(restored.isKids, true);
      expect(restored.pinHash, model.pinHash);
      expect(restored.maxAgeRating, 'PG');
    });
  });
}
