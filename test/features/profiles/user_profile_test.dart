import 'package:flutter_test/flutter_test.dart';
import 'package:aura/features/profiles/domain/entities/user_profile.dart';

void main() {
  group('UserProfile Unit Tests', () {
    test('initials computation handles single and multi-word names correctly', () {
      final p1 = UserProfile(
        id: '1',
        name: 'Hamas',
        createdAt: DateTime.now(),
      );
      expect(p1.initials, 'HA');

      final p2 = UserProfile(
        id: '2',
        name: 'John Doe',
        createdAt: DateTime.now(),
      );
      expect(p2.initials, 'JD');

      final p3 = UserProfile(
        id: '3',
        name: 'A',
        createdAt: DateTime.now(),
      );
      expect(p3.initials, 'A');
    });

    test('PIN hashing and verification', () {
      final pin = '1234';
      final hashed = UserProfile.hashPin(pin);

      final profile = UserProfile(
        id: '1',
        name: 'Test',
        pinHash: hashed,
        createdAt: DateTime.now(),
      );

      expect(profile.hasPin, isTrue);
      expect(profile.verifyPin('1234'), isTrue);
      expect(profile.verifyPin('9999'), isFalse);
    });

    test('KidsCertification ratings guard', () {
      expect(KidsCertification.isAllowed('PG'), isTrue);
      expect(KidsCertification.isAllowed('G'), isTrue);
      expect(KidsCertification.isAllowed('TV-Y7'), isTrue);
      expect(KidsCertification.isAllowed('R'), isFalse);
      expect(KidsCertification.isAllowed('NC-17'), isFalse);
      expect(KidsCertification.isAllowed('TV-MA'), isFalse);
    });

    test('UserProfile copyWith mutations', () {
      final original = UserProfile(
        id: 'p1',
        name: 'Original',
        isKids: false,
        createdAt: DateTime.now(),
      );

      final mutated = original.copyWith(
        name: 'Updated Name',
        isKids: true,
        avatarPaletteId: 'neon_cyan',
      );

      expect(mutated.id, 'p1');
      expect(mutated.name, 'Updated Name');
      expect(mutated.isKids, isTrue);
      expect(mutated.avatarPaletteId, 'neon_cyan');
    });
  });
}
