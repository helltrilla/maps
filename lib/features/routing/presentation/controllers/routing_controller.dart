import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../data/repositories/routing_repository_impl.dart';
import '../../domain/entities/route_info.dart';
import '../../domain/repositories/routing_repository.dart';
import '../../domain/usecases/get_route_usecase.dart';

class RoutingState {
  final RouteInfo? currentRoute;
  final bool isLoading;
  final String? errorMessage;
  final bool isPickingPointOnMap;
  final bool pickingForStart;

  const RoutingState({
    this.currentRoute,
    this.isLoading = false,
    this.errorMessage,
    this.isPickingPointOnMap = false,
    this.pickingForStart = false,
  });

  RoutingState copyWith({
    RouteInfo? Function()? currentRoute,
    bool? isLoading,
    String? Function()? errorMessage,
    bool? isPickingPointOnMap,
    bool? pickingForStart,
  }) {
    return RoutingState(
      currentRoute: currentRoute != null ? currentRoute() : this.currentRoute,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      isPickingPointOnMap: isPickingPointOnMap ?? this.isPickingPointOnMap,
      pickingForStart: pickingForStart ?? this.pickingForStart,
    );
  }
}

final getRouteUseCaseProvider = Provider<GetRouteUseCase>((ref) {
  return GetRouteUseCase(ref.watch(routingRepositoryProvider));
});

final routingControllerProvider =
    StateNotifierProvider<RoutingController, RoutingState>((ref) {
  final useCase = ref.watch(getRouteUseCaseProvider);
  return RoutingController.fromUseCase(useCase);
});

class RoutingController extends StateNotifier<RoutingState> {
  final GetRouteUseCase _getRoute;

  RoutingController(RoutingRepository repository)
      : _getRoute = GetRouteUseCase(repository),
        super(const RoutingState());

  RoutingController.fromUseCase(this._getRoute) : super(const RoutingState());

  void startPickingPoint({required bool forStart}) {
    state = state.copyWith(
      isPickingPointOnMap: true,
      pickingForStart: forStart,
    );
  }

  void stopPickingPoint() {
    state = state.copyWith(
      isPickingPointOnMap: false,
    );
  }

  Future<bool> buildRoute({
    required LatLng start,
    required LatLng destination,
    String startName = 'Моё местоположение',
    String destinationName = 'Точка назначения',
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);

    final result = await _getRoute(
      start,
      destination,
      startName: startName,
      destinationName: destinationName,
    );

    return result.when(
      success: (route) {
        state = state.copyWith(
          currentRoute: () => route,
          isLoading: false,
        );
        return true;
      },
      error: (f) {
        state = state.copyWith(
          currentRoute: () => null,
          isLoading: false,
          errorMessage: () => f.message,
        );
        return false;
      },
    );
  }

  void clearRoute() {
    state = state.copyWith(
      currentRoute: () => null,
      errorMessage: () => null,
    );
  }
}
