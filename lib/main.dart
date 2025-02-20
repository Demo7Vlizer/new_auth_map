import 'package:auth_map/presentation/screens/splash/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as dotenv;
import 'models/user_model.dart';
import 'bindings/initial_binding.dart';
import 'core/services/session_service.dart';
import 'presentation/screens/users/user_list_screen.dart';
import 'screens/map_screen.dart';
import 'presentation/screens/auth/welcome_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/register_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive first
  await Hive.initFlutter();

  // Register adapters only if not already registered
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(UserModelAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(LocationAdapter());
  }

  // Load environment variables
  await dotenv.dotenv.load(fileName: ".env");

  // Initialize SessionService and wait for it
  final sessionService = SessionService();
  await sessionService.init();

  runApp(MyApp(sessionService: sessionService));
}

class MyApp extends StatelessWidget {
  final SessionService sessionService;
  
  const MyApp({super.key, required this.sessionService});

  @override
  Widget build(BuildContext context) {
    // Initialize GetX bindings with session service
    Get.put(sessionService, permanent: true);
    InitialBinding().dependencies();

    return GetMaterialApp(
      title: 'Location Tracker',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => const SplashScreen()),
        GetPage(name: '/welcome', page: () => const WelcomeScreen()),
        GetPage(name: '/login', page: () => LoginScreen()),
        GetPage(name: '/register', page: () => RegisterScreen()),
        GetPage(name: '/map', page: () => const MapScreen()),
        GetPage(name: '/users', page: () => const UserListScreen()),
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
    );
  }
}
