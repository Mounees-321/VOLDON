import 'package:flutter/material.dart';
import 'package:voldon/profile_setup.dart';
import 'package:voldon/profile_view.dart';
import 'splash_screen.dart';
import 'home_page.dart';
import 'sign_in_page.dart';
import 'sign_up_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'donor.dart';
import 'role_select.dart';
import 'volunteer.dart';
import 'receiver.dart'; // This should contain ReceiverPage

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      
      // ✅ Named Routes
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/home': (context) => const HomePage(),
        '/signin': (context) => const SignInPage(),
        '/signup': (context) => const SignUpPage(),
        '/donor': (context) => const DonorPage(),
        '/role_select': (context) => const RoleSelectPage(),
        '/volunteer': (context) => const VolunteerPage(),
        '/profile_setup': (context) => ProfileSetupPage(
          uid: ModalRoute.of(context)!.settings.arguments as String,
        ),
        '/profile_view': (context) => ProfileViewPage(
  uid: ModalRoute.of(context)!.settings.arguments as String,
),

      },
      
      // ✅ Use onGenerateRoute for routes that need arguments
      onGenerateRoute: (settings) {
        // Handle receiver route with arguments
        if (settings.name == '/receiver') {
          final args = settings.arguments as Map<String, String>?;
          
          if (args != null) {
            return MaterialPageRoute(
              builder: (context) => ReceiverPage.fromParams(
                receiverId: args['receiverId'] ?? '',
                receiverName: args['receiverName'] ?? '',
                receiverPhone: args['receiverPhone'] ?? '',
                receiverAddress: args['receiverAddress'] ?? '',
              ),
            );
          }
          
          // Default empty receiver page if no args provided
          return MaterialPageRoute(
            builder: (context) => ReceiverPage.fromParams(
              receiverId: '',
              receiverName: '',
              receiverPhone: '',
              receiverAddress: '',
            ),
          );
        }
        
        return null;
      },
    );
  }
}