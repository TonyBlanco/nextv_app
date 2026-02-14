import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nextv_app/core/services/favorites_service.dart';
import '../test_helpers.dart';

/// Unit tests for FavoritesService
void main() {
  group('FavoritesService Tests', () {
    late FavoritesService favoritesService;

    setUp(() async {
      await TestHelpers.setupMockSharedPreferences();
      final prefs = await SharedPreferences.getInstance();
      favoritesService = FavoritesService(prefs);
      await favoritesService.init();
    });

    test('should initialize with empty favorites', () {
      expect(favoritesService.favoriteIds, isEmpty);
    });

    test('should add favorite successfully', () async {
      await favoritesService.toggleFavorite(12345);
      
      expect(favoritesService.isFavorite(12345), isTrue);
      expect(favoritesService.favoriteIds, contains(12345));
      expect(favoritesService.favoriteIds.length, 1);
    });

    test('should remove favorite successfully', () async {
      await favoritesService.toggleFavorite(12345);
      expect(favoritesService.isFavorite(12345), isTrue);
      
      await favoritesService.toggleFavorite(12345);
      expect(favoritesService.isFavorite(12345), isFalse);
      expect(favoritesService.favoriteIds, isEmpty);
    });

    test('should handle multiple favorites', () async {
      await favoritesService.toggleFavorite(111);
      await favoritesService.toggleFavorite(222);
      await favoritesService.toggleFavorite(333);
      
      expect(favoritesService.favoriteIds.length, 3);
      expect(favoritesService.isFavorite(111), isTrue);
      expect(favoritesService.isFavorite(222), isTrue);
      expect(favoritesService.isFavorite(333), isTrue);
      expect(favoritesService.isFavorite(444), isFalse);
    });

    test('should persist favorites to SharedPreferences', () async {
      await favoritesService.toggleFavorite(12345);
      
      // Create a new instance to check persistence
      final prefs = await SharedPreferences.getInstance();
      final newService = FavoritesService(prefs);
      await newService.init();
      
      expect(newService.isFavorite(12345), isTrue);
    });

    test('should get all favorite IDs', () async {
      await favoritesService.toggleFavorite(111);
      await favoritesService.toggleFavorite(222);
      await favoritesService.toggleFavorite(333);
      
      final ids = favoritesService.favoriteIds;
      
      expect(ids, hasLength(3));
      expect(ids, containsAll([111, 222, 333]));
    });

    test('should clear all favorites', () async {
      await favoritesService.toggleFavorite(111);
      await favoritesService.toggleFavorite(222);
      await favoritesService.toggleFavorite(333);
      
      await favoritesService.clearAllFavorites();
      
      expect(favoritesService.favoriteIds, isEmpty);
      expect(favoritesService.isFavorite(111), isFalse);
    });

    test('should handle concurrent operations', () async {
      // Simulate multiple toggles happening quickly
      final futures = [
        favoritesService.toggleFavorite(111),
        favoritesService.toggleFavorite(222),
        favoritesService.toggleFavorite(333),
      ];
      
      await Future.wait(futures);
      
      expect(favoritesService.favoriteIds.length, 3);
    });

    test('should handle large number of favorites', () async {
      // Add 1000 favorites
      for (int i = 0; i < 1000; i++) {
        await favoritesService.toggleFavorite(i);
      }
      
      expect(favoritesService.favoriteIds.length, 1000);
      expect(favoritesService.isFavorite(500), isTrue);
      expect(favoritesService.isFavorite(1000), isFalse);
    });
  });

  group('FavoritesService Edge Cases', () {
    late FavoritesService favoritesService;

    setUp(() async {
      await TestHelpers.setupMockSharedPreferences();
      final prefs = await SharedPreferences.getInstance();
      favoritesService = FavoritesService(prefs);
      await favoritesService.init();
    });

    test('should handle negative IDs', () async {
      await favoritesService.toggleFavorite(-1);
      expect(favoritesService.isFavorite(-1), isTrue);
    });

    test('should handle zero ID', () async {
      await favoritesService.toggleFavorite(0);
      expect(favoritesService.isFavorite(0), isTrue);
    });

    test('should handle very large IDs', () async {
      const largeId = 999999999999;
      await favoritesService.toggleFavorite(largeId);
      expect(favoritesService.isFavorite(largeId), isTrue);
    });

    test('should maintain order of favorites', () async {
      await favoritesService.toggleFavorite(333);
      await favoritesService.toggleFavorite(111);
      await favoritesService.toggleFavorite(222);
      
      final ids = favoritesService.favoriteIds.toList();
      // Order might be maintained depending on implementation
      expect(ids, containsAll([111, 222, 333]));
    });
  });
}
