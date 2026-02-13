import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/xtream_models.dart';
import '../services/xtream_api_service.dart';

final liveCategoriesProvider = FutureProvider<List<LiveCategory>>((ref) async {
  final api = ref.watch(xtreamAPIProvider);
  return api.getLiveCategories();
});

final vodCategoriesProvider = FutureProvider<List<VODCategory>>((ref) async {
  final api = ref.watch(xtreamAPIProvider);
  return api.getVODCategories();
});

final seriesCategoriesProvider = FutureProvider<List<SeriesCategory>>((ref) async {
  final api = ref.watch(xtreamAPIProvider);
  return api.getSeriesCategories();
});
