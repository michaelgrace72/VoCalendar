import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutterapi/providers/user_provider.dart';
import 'package:flutterapi/view/pages/welcome_page.dart';
import 'package:flutterapi/view/widgets/navigation_menu.dart';
import 'package:flutterapi/viewmodels/schedule_viewmodel.dart';
import 'package:provider/provider.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // if still loading, show a loading indicator
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.connectionState == ConnectionState.active) {
            final user = snapshot.data;
            if (user != null) {
              // Load user data by email or uid from Firestore
              Future.microtask(() {
                final userProvider = Provider.of<UserProvider>(
                  context,
                  listen: false,
                );
                userProvider.loadUserDataByEmail(user.email ?? '');
              });
              return ChangeNotifierProvider(
                create: (_) => ScheduleViewModel(user.uid),
                child: const NavigationMenu(),
              );
            } else {
              return const WelcomePage();
            }
          }
          // loading indicator while checking auth state
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
