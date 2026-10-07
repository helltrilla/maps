import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../data/repositories/location_repository_impl.dart';
import '../../domain/entities/location_update.dart';
import '../../domain/entities/map_tile_style.dart';
import '../../domain/repositories/location_repository.dart';
import '../../domain/usecases/location_usecases.dart';

class UserLocationState {
  final LatLng? location;
  final double heading;
  final double speed;
  final bool isFollowingUser;

  const UserLocationState({
    this.location,
    this.heading = 0.0,
    this.speed = 0.0,
    this.isFollowingUser = false,
  });

  UserLocationState copyWith({
    LatLng? location,
    double? heading,
    double? speed,
    bool? isFollowingUser,
  }) {
    return UserLocationState(
      location: location ?? this.location,
      heading: heading ?? this.heading,
      speed: speed ?? this.speed,
      isFollowingUser: isFollowingUser ?? this.isFollowingUser,
    );
  }
}

final selectedTileStyleProvider = StateProvider<MapTileStyle>((ref) {
  return MapTileStyle.availableStyles[0];
});

final getCurrentLocationUseCaseProvider =
    Provider<GetCurrentLocationUseCase>((ref) {
  return GetCurrentLocationUseCase(ref.watch(locationRepositoryProvider));
});

final getLocationStreamUseCaseProvider =
    Provider<GetLocationStreamUseCase>((ref) {
  return GetLocationStreamUseCase(ref.watch(locationRepositoryProvider));
});

final userLocationControllerProvider =
    StateNotifierProvider<UserLocationController, UserLocationState>((ref) {
  return UserLocationController.fromUseCases(
    getCurrentLocation: ref.watch(getCurrentLocationUseCaseProvider),
    getLocationStream: ref.watch(getLocationStreamUseCaseProvider),
  );
});

class UserLocationController extends StateNotifier<UserLocationState> {
  final GetCurrentLocationUseCase _getCurrentLocation;
  final GetLocationStreamUseCase _getLocationStream;
  StreamSubscription<LocationUpdate>? _positionSub;

  UserLocationController(LocationRepository repository)
      : _getCurrentLocation = GetCurrentLocationUseCase(repository),
        _getLocationStream = GetLocationStreamUseCase(repository),
        super(const UserLocationState()) {
    _initTracking();
  }

  UserLocationController.fromUseCases({
    required GetCurrentLocationUseCase getCurrentLocation,
    required GetLocationStreamUseCase getLocationStream,
  })  : _getCurrentLocation = getCurrentLocation,
        _getLocationStream = getLocationStream,
        super(const UserLocationState()) {
    _initTracking();
  }

  void _initTracking() {
    _getCurrentLocation().then((res) {
      res.when(
        success: (pos) => state = state.copyWith(location: pos),
        error: (_) {},
      );
    });

    _positionSub = _getLocationStream().listen((update) {
      state = state.copyWith(
        location: update.position,
        heading: update.heading > 0 ? update.heading : state.heading,
        speed: update.speed,
      );
    });
  }

  void setFollowingUser(bool follow) {
    if (state.isFollowingUser != follow) {
      state = state.copyWith(isFollowingUser: follow);
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }
}
