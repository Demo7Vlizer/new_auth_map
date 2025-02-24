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
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import '../presentation/screens/full_image_viewer.dart';

class MapController extends GetxController {
  final UserService _userService = UserService();
  final RxSet<Marker> markers = <Marker>{}.obs;
  final Rx<LatLng> currentLocation =
      const LatLng(28.7041, 77.1025).obs; // Default to Delhi
  final RxList<UserModel> users = <UserModel>[].obs;
  final Rx<MapType> currentMapType = MapType.normal.obs;
  GoogleMapController? _controller;
  final Rx<double> bearing = 0.0.obs; // Make it public so we can access in view
  StreamSubscription<CompassEvent>? _compassSubscription;
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

      await Future.wait(users.map((user) async {
        if (user.location.latitude != 0 && user.location.longitude != 0) {
          BitmapDescriptor markerIcon;

          if (user.image != null && user.image!.isNotEmpty) {
            markerIcon = await _createCustomMarkerFromImage(user.image!);
          } else {
            markerIcon = await _createDefaultPersonMarker();
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
              onTap: () {
                // Show brief info on tap and detailed info on long press
                _showUserInfoSnackbar(user);
                _showUserDetailDialog(user);
              },
            ),
          );
        }
      }));

      // --

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
    try {
      if (FlutterCompass.events != null) {
        _compassSubscription = FlutterCompass.events!.listen(
          (event) {
            if (event.heading != null) {
              bearing.value = event.heading!;
            }
          },
          onError: (e) {
            print('Error reading compass: $e');
            bearing.value = 0.0;
          },
          cancelOnError: false,
        );
      } else {
        print('Compass events not available on this device');
        bearing.value = 0.0;
      }
    } catch (e) {
      print('Error initializing compass: $e');
      bearing.value = 0.0;
    }
  }

  @override
  void onClose() {
    stopLocationTracking();
    if (_compassSubscription != null) {
      try {
        _compassSubscription?.cancel();
      } catch (e) {
        print('Error canceling compass subscription: $e');
      }
    }
    super.onClose();
  }

  Future<BitmapDescriptor> _createCustomMarkerFromImage(String imageUrl) async {
    try {
      final response =
          await NetworkAssetBundle(Uri.parse(imageUrl)).load(imageUrl);
      final bytes = response.buffer.asUint8List();

      // Increase the size of the marker
      final size = 120.0; // Increased from 80
      final codec = await ui.instantiateImageCodec(bytes,
          targetHeight: size.toInt(), targetWidth: size.toInt());
      final frame = await codec.getNextFrame();

      // Create a circular frame for the image
      final ui.Image image = frame.image;

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

  Future<BitmapDescriptor> _createDefaultPersonMarker() async {
    // Create a custom marker with person icon
    final size = 120.0; // Increased from 80
    final pictureRecorder = ui.PictureRecorder();
    final canvas = ui.Canvas(pictureRecorder);
    final paint = ui.Paint()
      ..color = Colors.blue.shade100
      ..style = ui.PaintingStyle.fill;

    // Draw circle background
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2,
      paint,
    );

    // Draw person icon
    final iconPaint = ui.Paint()
      ..color = Colors.blue.shade700
      ..style = ui.PaintingStyle.fill;

    // Simple person icon shape - scaled up for larger size
    final path = ui.Path()
      ..addOval(Rect.fromCircle(
        center: Offset(size / 2, size / 3),
        radius: size / 4, // Increased from size/6
      ))
      ..addRect(Rect.fromLTWH(
        size / 3,
        size / 2,
        size / 3,
        size / 2.5, // Adjusted for better proportions
      ));

    canvas.drawPath(path, iconPaint);

    final image = await pictureRecorder
        .endRecording()
        .toImage(size.toInt(), size.toInt());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
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

  //--

  void _showUserInfoSnackbar(UserModel user) {
    Get.snackbar(
      user.name.isEmpty ? 'User' : user.name,
      'Phone: ${user.phone}',
      backgroundColor: Colors.white,
      duration: const Duration(seconds: 2),
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 16,
      icon: Icon(Icons.person, color: Colors.blue.shade700),
    );
  }

  Future<String> _getAddressFromLatLng(double lat, double long) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, long);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return '${place.street}, ${place.locality}, ${place.postalCode}';
      }
    } catch (e) {
      print('Error getting address: $e');
    }
    return 'Location not found';
  }

  void _showUserDetailDialog(UserModel user) async {
    String address = await _getAddressFromLatLng(
      user.location.latitude,
      user.location.longitude,
    );

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        child: Container(
          width: 320,
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  if (user.image != null && user.image!.isNotEmpty) {
                    Get.to(() => FullImageViewer(imageUrl: user.image!));
                  }
                },
                child: CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: user.image != null && user.image!.isNotEmpty
                      ? NetworkImage(user.image!)
                      : null,
                  child: user.image == null || user.image!.isEmpty
                      ? Icon(Icons.person, size: 45, color: Colors.grey[400])
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                user.name.isEmpty ? 'User' : user.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '+${user.phone}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Location',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              Text(
                address,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              // const SizedBox(height: 24),
              // TextButton(
              //   onPressed: () => Get.back(),
              //   child: Text(
              //     'Close',
              //     style: TextStyle(
              //       color: Colors.blue[600],
              //       fontSize: 14,
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }
}
