import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/repositories/search_repository_impl.dart';
import '../../domain/models/search_result.dart';
import '../../domain/repositories/search_repository.dart';

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

final searchControllerProvider =
    StateNotifierProvider<SearchController, SearchState>((ref) {
  final repo = ref.watch(searchRepositoryProvider);
  return SearchController(repo);
});

class SearchController extends StateNotifier<SearchState> {
  final SearchRepository _repository;
  Timer? _debounceTimer;

  SearchController(this._repository) : super(const SearchState());

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
    final result = await _repository.search(query, proximity: proximity);
    result.when(
      success: (results) {
        state = state.copyWith(results: results, isLoading: false);
      },
      error: (_) {
        state = state.copyWith(results: const [], isLoading: false);
      },
    );
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
