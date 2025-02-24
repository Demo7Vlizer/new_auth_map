import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'dart:async';
import '../controllers/auth_controller.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

class MapController extends GetxController {
  final UserService _userService = UserService();
  final RxSet<Marker> markers = <Marker>{}.obs;
  final Rx<LatLng> currentLocation =
      const LatLng(28.7041, 77.1025).obs; // Default to Delhi
  final RxList<UserModel> users = <UserModel>[].obs;
  final Rx<MapType> currentMapType = MapType.normal.obs;
  GoogleMapController? _controller;
  final Rx<double> bearing = 0.0.obs; // Make it public so we can access in view
  late StreamSubscription<CompassEvent> _compassSubscription;
  final RxBool isLoading = false.obs;
  final RxBool isTrackingEnabled = false.obs;
  Timer? _locationTimer;

  @override
  void onInit() {
    super.onInit();
    ever(currentLocation, (_) {
      updateMarkers(); // Update markers whenever the current location changes
    });
    ever(users, (_) {
      updateMarkers();
    });
    _initCompass();

    // Add listener for auth changes
    ever(Get.find<AuthController>().currentUser, (user) {
      if (user != null) {
        startLocationTracking();
        loadUsers();
      } else {
        stopLocationTracking();
      }
    });
  }

  void startLocationTracking() {
    getCurrentLocation(); // Get initial location
    loadUsers();

    // Start periodic updates
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (isTrackingEnabled.value) {
        getCurrentLocation();
        loadUsers();
      }
    });

    isTrackingEnabled.value = true;
  }

  void stopLocationTracking() {
    _locationTimer?.cancel();
    _locationTimer = null;
    isTrackingEnabled.value = false;
  }

  Future<void> getCurrentLocation() async {
    try {
      isLoading.value = true;

      // Check for location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        print(
            'Location permissions are permanently denied, we cannot request permissions.');
        return;
      }

      // If permission is granted, get the current location
      Position position = await Geolocator.getCurrentPosition();
      currentLocation.value = LatLng(position.latitude, position.longitude);

      // Update markers to reflect the new current location
      updateMarkers(); // Ensure this updates the avatar marker position
    } catch (e) {
      print('Error getting location: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadUsers() async {
    try {
      isLoading.value = true;
      final freshUsers = await _userService.getAllUsers();
      if (freshUsers.isNotEmpty) {
        users.value = freshUsers;
      }
    } catch (e) {
      print('Error loading users: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void updateMarkers() async {
    if (users.isEmpty) return;

    try {
      isLoading.value = true;
      final Set<Marker> newMarkers = {};

      // Add current location marker
      newMarkers.add(
        Marker(
          markerId: MarkerId('current_location'),
          position: currentLocation.value,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );

      await Future.wait(users.map((user) async {
        if (user.location.latitude != 0 && user.location.longitude != 0) {
          BitmapDescriptor markerIcon;
          if (user.image != null && user.image!.isNotEmpty) {
            markerIcon = await _createCustomMarkerFromImage(user.image!);
          } else {
            markerIcon =
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
          }

          newMarkers.add(
            Marker(
              markerId: MarkerId(user.id),
              position: LatLng(user.location.latitude, user.location.longitude),
              infoWindow: InfoWindow(
                title: user.name.isEmpty ? 'User' : user.name,
                snippet: user.phone,
              ),
              icon: markerIcon,
            ),
          );
        }
      }));

      markers.value = newMarkers;
    } catch (e) {
      print('Error updating markers: $e');
    } finally {
      isLoading.value = false;
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
    stopLocationTracking();
    _compassSubscription.cancel();
    super.onClose();
  }

  Future<BitmapDescriptor> _createCustomMarkerFromImage(String imageUrl) async {
    try {
      final response =
          await NetworkAssetBundle(Uri.parse(imageUrl)).load(imageUrl);
      final bytes = response.buffer.asUint8List();

      // Reduce the size of the marker
      final codec = await ui.instantiateImageCodec(bytes,
          targetHeight: 80, // Reduced from 150
          targetWidth: 80); // Reduced from 150
      final frame = await codec.getNextFrame();

      // Create a circular frame for the image
      final ui.Image image = frame.image;
      final size = 80.0; // Match the target size

      final pictureRecorder = ui.PictureRecorder();
      final canvas = ui.Canvas(pictureRecorder);

      // Draw circular clipping path
      final paint = ui.Paint()..isAntiAlias = true;

      // Create circular clip
      canvas.clipPath(ui.Path()
        ..addOval(Rect.fromCircle(
          center: Offset(size / 2, size / 2),
          radius: size / 2,
        )));

      // Draw the image
      canvas.drawImage(image, Offset.zero, paint);

      // Convert to image
      final renderedImage = await pictureRecorder.endRecording().toImage(
            size.toInt(),
            size.toInt(),
          );

      final data =
          await renderedImage.toByteData(format: ui.ImageByteFormat.png);

      if (data != null) {
        return BitmapDescriptor.fromBytes(data.buffer.asUint8List());
      }
    } catch (e) {
      print('Error creating custom marker: $e');
    }

    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
  }

  void showLocationTrackingDialog() {
    Get.defaultDialog(
      title: 'Location Tracking',
      middleText:
          'This app will track your location to provide better services. Do you want to allow this?',
      onConfirm: () {
        startLocationTracking(); // Start tracking
        Get.back();
      },
      onCancel: () {
        stopLocationTracking(); // Stop tracking
        print('User declined location tracking.');
      },
    );
  }
}
