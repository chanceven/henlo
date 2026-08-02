import 'dart:async';
import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_screen.dart';
import 'screens/signin_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/furrent_signup_screen.dart';
import 'screens/pawtner_signup_screen.dart';
import 'screens/furrent_dashboard_screen.dart';
import 'screens/pawtner_dashboard_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/terms_and_conditions_screen.dart';
import 'screens/furrent_search_screen.dart';
import 'screens/reset_password_screen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
    };

    ErrorWidget.builder = (details) {
      return Material(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'ERROR:\n${details.exception}',
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
          ),
        ),
      );
    };

    String? errorMessage;

    try {
      await Supabase.initialize(
        url: 'https://lyjxzdcapqdvwxyamcbz.supabase.co',
        anonKey:
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx5anh6ZGNhcHFkdnd4eWFtY2J6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE4ODk3OTgsImV4cCI6MjA3NzQ2NTc5OH0.3Gik4uMpKD5rztuFkFsLX6MeDqsRQp0rC02F4Ug4EmY',
      ).timeout(const Duration(seconds: 8));
    } catch (e) {
      errorMessage = 'Supabase failed: $e';
    }

    if (errorMessage == null) {
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ).timeout(const Duration(seconds: 8));
      } catch (e) {
        errorMessage = 'Firebase failed: $e';
      }
    }

    if (errorMessage != null) {
      runApp(MaterialApp(
        home: Scaffold(
            body:
                Center(child: Text(errorMessage, textAlign: TextAlign.center))),
      ));
      return;
    }

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'Used for chat message notifications',
      importance: Importance.max,
      playSound: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    runApp(const MyApp());
  }, (error, stack) {
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'FATAL ERROR:\n$error',
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
          ),
        ),
      ),
    ));
  });
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Background message: ${message.messageId}");
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FirebaseMessaging messaging = FirebaseMessaging.instance;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _initFCM();
    _initAuthListener();
  }

  void _initAuthListener() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.passwordRecovery) {
        navigatorKey.currentState?.pushReplacement(
          MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
        );
      }
    });
  }

  Future<void> _initFCM() async {
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('FCM permission status: ${settings.authorizationStatus}');

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;

      if (notification != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'High Importance Notifications',
              importance: Importance.max,
              priority: Priority.high,
              playSound: true,
            ),
          ),
        );
      }
    });

    if (Platform.isIOS) {
      String? apnsToken = await messaging.getAPNSToken();
      int attempts = 0;
      while (apnsToken == null && attempts < 10) {
        await Future.delayed(const Duration(seconds: 1));
        apnsToken = await messaging.getAPNSToken();
        attempts++;
      }
      debugPrint('APNS token: $apnsToken');
    }

    String? token = await messaging.getToken();
    debugPrint('FCM token: $token');
    if (token != null) {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        await Supabase.instance.client
            .from('furrents')
            .update({'fcm_token': token}).eq('id', userId);

        await Supabase.instance.client
            .from('pawtners')
            .update({'fcm_token': token}).eq('id', userId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'henlo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF6E4B3A),
        scaffoldBackgroundColor: const Color(0xFFF8F8F8),
      ),
      home: const SplashScreen(),
      routes: {
        '/sign_in': (_) => const SignInScreen(),
        '/onboarding': (_) => const OnboardingScreen(),
        '/furrent_signup': (_) => const FurrentSignUpScreen(),
        '/pawtner_signup': (_) => const PawtnerSignUpScreen(),
        '/furrent_dashboard': (_) => const FurrentDashboardScreen(),
        '/pawtner_dashboard': (_) => const PawtnerDashboardScreen(),
        '/forgot_password': (_) => const ForgotPasswordScreen(),
        '/terms': (_) => const TermsAndConditionsScreen(),
        '/search': (_) => const FurrentSearchScreen(),
        '/reset_password': (_) => const ResetPasswordScreen(),
      },
      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (_) => const SplashScreen(),
      ),
    );
  }
}
