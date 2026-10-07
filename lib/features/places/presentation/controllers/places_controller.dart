import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../data/repositories/places_repository_impl.dart';
import '../../domain/models/place.dart';
import '../../domain/repositories/places_repository.dart';

class PlacesState {
  final List<Place> places;
  final String selectedCategory;
  final bool isLoading;

  const PlacesState({
    this.places = const [],
    this.selectedCategory = 'Все',
    this.isLoading = false,
  });

  PlacesState copyWith({
    List<Place>? places,
    String? selectedCategory,
    bool? isLoading,
  }) {
    return PlacesState(
      places: places ?? this.places,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final placesControllerProvider =
    StateNotifierProvider<PlacesController, PlacesState>((ref) {
  final repo = ref.watch(placesRepositoryProvider);
  return PlacesController(repo);
});

class PlacesController extends StateNotifier<PlacesState> {
  final PlacesRepository _repository;

  PlacesController(this._repository) : super(const PlacesState());

  Future<void> loadNearbyPlaces(LatLng location, {String? category}) async {
    final cat = category ?? state.selectedCategory;
    state = state.copyWith(isLoading: true, selectedCategory: cat);

    final result = await _repository.getNearbyPlaces(location, category: cat);
    result.when(
      success: (places) {
        state = state.copyWith(places: places, isLoading: false);
      },
      error: (_) {
        state = state.copyWith(places: const [], isLoading: false);
      },
    );
  }

  void selectCategory(LatLng location, String category) {
    if (state.selectedCategory == category) {
      loadNearbyPlaces(location, category: 'Все');
    } else {
      loadNearbyPlaces(location, category: category);
    }
  }
}
