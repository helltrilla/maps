import 'package:latlong2/latlong.dart';
import '../../../../core/errors/result.dart';
import '../models/search_result.dart';

abstract class SearchRepository {
  Future<Result<List<SearchResult>>> search(
    String query, {
    LatLng? proximity,
    int limit = 10,
  });
}
