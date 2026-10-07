import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../features/search/data/datasources/photon_datasource.dart';
import '../features/search/data/repositories/search_repository_impl.dart';
import '../features/search/domain/models/search_result.dart';
import '../features/search/domain/repositories/search_repository.dart';

class SearchService {
  static SearchRepository _repo = SearchRepositoryImpl(
    dataSource: PhotonDataSourceImpl(client: http.Client()),
  );

  @visibleForTesting
  static void setRepositoryForTesting(SearchRepository repo) {
    _repo = repo;
  }

  @visibleForTesting
  static void resetRepositoryForTesting() {
    _repo = SearchRepositoryImpl(
      dataSource: PhotonDataSourceImpl(client: http.Client()),
    );
  }

  static Future<List<SearchResult>> search(
    String query, {
    LatLng? proximity,
    int limit = 10,
  }) async {
    final result =
        await _repo.search(query, proximity: proximity, limit: limit);
    return result.dataOrNull ?? [];
  }
}
