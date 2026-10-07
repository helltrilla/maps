import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../data/repositories/location_repository_impl.dart';
import '../../domain/models/map_tile_style.dart';
import '../../domain/repositories/location_repository.dart';

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

final userLocationControllerProvider =
    StateNotifierProvider<UserLocationController, UserLocationState>((ref) {
  final repo = ref.watch(locationRepositoryProvider);
  return UserLocationController(repo);
});

class UserLocationController extends StateNotifier<UserLocationState> {
  final LocationRepository _repository;
  StreamSubscription<Position>? _positionSub;

  UserLocationController(this._repository) : super(const UserLocationState()) {
    _initTracking();
  }

  void _initTracking() {
    _repository.getCurrentLocation().then((res) {
      res.when(
        success: (pos) => state = state.copyWith(location: pos),
        error: (_) {},
      );
    });

    _positionSub = _repository.getPositionStream().listen((pos) {
      final loc = LatLng(pos.latitude, pos.longitude);
      state = state.copyWith(
        location: loc,
        heading: pos.heading > 0 ? pos.heading : state.heading,
        speed: pos.speed,
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
