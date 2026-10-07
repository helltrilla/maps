import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/result.dart';
import '../../data/repositories/search_repository_impl.dart';
import '../../domain/entities/reverse_geocode_result.dart';
import '../../domain/entities/search_result.dart';
import '../../domain/repositories/search_repository.dart';
import '../../domain/usecases/search_usecases.dart';

class SearchState {
  final List<SearchResult> results;
  final bool isLoading;
  final String query;
  final bool isSearchOpen;

  const SearchState({
    this.results = const [],
    this.isLoading = false,
    this.query = '',
    this.isSearchOpen = false,
  });

  SearchState copyWith({
    List<SearchResult>? results,
    bool? isLoading,
    String? query,
    bool? isSearchOpen,
  }) {
    return SearchState(
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      query: query ?? this.query,
      isSearchOpen: isSearchOpen ?? this.isSearchOpen,
    );
  }
}

final searchPlacesUseCaseProvider = Provider<SearchPlacesUseCase>((ref) {
  return SearchPlacesUseCase(ref.watch(searchRepositoryProvider));
});

final reverseGeocodeUseCaseProvider = Provider<ReverseGeocodeUseCase>((ref) {
  return ReverseGeocodeUseCase(ref.watch(searchRepositoryProvider));
});

final searchControllerProvider =
    StateNotifierProvider<SearchController, SearchState>((ref) {
  return SearchController.fromUseCases(
    searchPlaces: ref.watch(searchPlacesUseCaseProvider),
    reverseGeocode: ref.watch(reverseGeocodeUseCaseProvider),
  );
});

class SearchController extends StateNotifier<SearchState> {
  final SearchPlacesUseCase _searchPlaces;
  final ReverseGeocodeUseCase _reverseGeocode;
  Timer? _debounceTimer;

  SearchController(SearchRepository repository)
      : _searchPlaces = SearchPlacesUseCase(repository),
        _reverseGeocode = ReverseGeocodeUseCase(repository),
        super(const SearchState());

  SearchController.fromUseCases({
    required SearchPlacesUseCase searchPlaces,
    required ReverseGeocodeUseCase reverseGeocode,
  })  : _searchPlaces = searchPlaces,
        _reverseGeocode = reverseGeocode,
        super(const SearchState());

  void setSearchOpen(bool isOpen) {
    state = state.copyWith(isSearchOpen: isOpen);
    if (!isOpen) {
      clearSearch();
    }
  }

  void onQueryChanged(String query, {LatLng? proximity}) {
    state = state.copyWith(query: query);
    _debounceTimer?.cancel();

    if (query.trim().length < 2) {
      state = state.copyWith(results: const [], isLoading: false);
      return;
    }

    _debounceTimer = Timer(AppConstants.searchDebounce, () {
      executeSearch(query, proximity: proximity);
    });
  }

  Future<void> executeSearch(String query, {LatLng? proximity}) async {
    state = state.copyWith(isLoading: true);
    final result = await _searchPlaces(query, proximity: proximity);
    result.when(
      success: (results) {
        state = state.copyWith(results: results, isLoading: false);
      },
      error: (_) {
        state = state.copyWith(results: const [], isLoading: false);
      },
    );
  }

  Future<Result<ReverseGeocodeResult>> reverseGeocode(LatLng position) {
    return _reverseGeocode(position);
  }

  void clearSearch() {
    _debounceTimer?.cancel();
    state = state.copyWith(query: '', results: const [], isLoading: false);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
