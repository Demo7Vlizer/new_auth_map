import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'dart:async';
import '../controllers/auth_controller.dart';

class MapController extends GetxController {
  final UserService _userService = UserService();
  final RxSet<Marker> markers = <Marker>{}.obs;
  final Rx<LatLng> currentLocation =
      const LatLng(28.7041, 77.1025).obs; // Default to Delhi
  final RxBool isLoading = false.obs;
  final RxList<UserModel> users = <UserModel>[].obs;
  final Rx<MapType> currentMapType = MapType.normal.obs;
  GoogleMapController? _controller;
  final Rx<double> bearing = 0.0.obs; // Make it public so we can access in view
  late StreamSubscription<CompassEvent> _compassSubscription;

  @override
  void onInit() {
    super.onInit();
    getCurrentLocation();
    loadUsers();
    _initCompass();
    
    // Add listener for auth changes
    ever(Get.find<AuthController>().currentUser, (_) {
      loadUsers();  // Reload users when current user changes
    });

    // Set up periodic refresh
    Timer.periodic(const Duration(minutes: 1), (_) {
      loadUsers();
    });
  }

  Future<void> getCurrentLocation() async {
    try {
      isLoading.value = true;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      Position position = await Geolocator.getCurrentPosition();
      currentLocation.value = LatLng(position.latitude, position.longitude);
      updateMarkers();
    } catch (e) {
      Get.snackbar('Error', 'Could not get location: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadUsers() async {
    try {
      isLoading.value = true;
      
      // Get fresh data from service
      final freshUsers = await _userService.getAllUsers();
      
      // Update only if we have data
      if (freshUsers.isNotEmpty) {
        users.value = freshUsers;
        updateMarkers();
      }
    } catch (e) {
      print('Error loading users: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void updateMarkers() {
    if (users.isEmpty) return;

    markers.clear();
    for (var user in users) {
      if (user.location.latitude != 0 && user.location.longitude != 0) {
        markers.add(
          Marker(
            markerId: MarkerId(user.id),
            position: LatLng(user.location.latitude, user.location.longitude),
            infoWindow:
                InfoWindow(title: user.name.isEmpty ? 'User' : user.name),
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );
      }
    }
  }

  void focusOnUser(UserModel user, LatLng location, double zoom) {
    if (_controller != null) {
      _controller!.animateCamera(
        CameraUpdate.newLatLngZoom(
          location,
          zoom,
        ),
      );

      // Highlight the user's marker
      markers.clear();
      markers.add(
        Marker(
          markerId: MarkerId(user.id),
          position: location,
          infoWindow: InfoWindow(
            title: user.name.isEmpty ? 'User' : user.name,
            snippet: user.phone,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }
  }

  void onMapCreated(GoogleMapController controller) {
    _controller = controller;
  }

  void updateMapType(MapType type) {
    currentMapType.value = type;
  }

  void zoomIn() {
    _controller?.animateCamera(CameraUpdate.zoomIn());
  }

  void zoomOut() {
    _controller?.animateCamera(CameraUpdate.zoomOut());
  }

  void goToMyLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      final latLng = LatLng(position.latitude, position.longitude);
      _controller?.animateCamera(
        CameraUpdate.newLatLngZoom(latLng, 15),
      );
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  void _initCompass() {
    _compassSubscription = FlutterCompass.events!.listen((event) {
      if (event.heading != null) {
        bearing.value = event.heading!;
      }
    });
  }

  @override
  void onClose() {
    _compassSubscription.cancel();
    super.onClose();
  }
}
