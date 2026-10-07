import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/network/http_client_provider.dart';
import '../../domain/models/search_result.dart';
import '../../domain/repositories/search_repository.dart';
import '../datasources/photon_datasource.dart';

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  final client = ref.watch(httpClientProvider);
  return SearchRepositoryImpl(dataSource: PhotonDataSourceImpl(client: client));
});

class SearchRepositoryImpl implements SearchRepository {
  final SearchDataSource _dataSource;

  SearchRepositoryImpl({required SearchDataSource dataSource})
      : _dataSource = dataSource;

  @override
  Future<Result<List<SearchResult>>> search(
    String query, {
    LatLng? proximity,
    int limit = 10,
  }) {
    return _dataSource.search(
      query,
      proximity: proximity ?? AppConstants.defaultLocation,
      limit: limit,
    );
  }
}
