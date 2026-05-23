import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import 'connexion_screen.dart';
import 'verification_screen.dart';
import 'complete_profile_screen.dart';
import '../../shared/navigation/main_shell.dart';
import '../driver/driver_main_screen.dart';
import '../admin/admin_dashboard_shell.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  User? _user;
  bool _isStreamReady = false;
  StreamSubscription<User?>? _authSub;
  StreamSubscription<User?>? _tokenSub;

  // Cached profile future to avoid redundant .get() on rebuild.
  String? _lastUid;
  Future<DocumentSnapshot>? _profileFuture;

  @override
  void initState() {
    super.initState();
    final current = FirebaseAuth.instance.currentUser;
    _user = current;
    _isStreamReady = current != null;

    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted) {
        setState(() {
          _user = user;
          _isStreamReady = true;
        });
      }
    });

    // idTokenChanges fires on token refresh — catches mobile edge cases.
    _tokenSub = FirebaseAuth.instance.idTokenChanges().listen((user) {
      if (!mounted) return;
      if (user != null && _user?.uid != user.uid) {
        setState(() => _user = user);
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _tokenSub?.cancel();
    super.dispose();
  }

  /// Called by ConnexionScreen after a successful sign-in.
  /// Forces an immediate rebuild so [currentUser] is read synchronously
  /// without waiting for the mobile-native stream emission.
  void _onLoginSuccess() {
    if (mounted) {
      setState(() {
        final current = FirebaseAuth.instance.currentUser;
        if (current != null) {
          _user = current;
          _isStreamReady = true;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Synchronous fallback: read currentUser directly every build.
    final user = _user ?? FirebaseAuth.instance.currentUser;

    // Only show the splash loader when we genuinely don't know the state.
    if (user == null && !_isStreamReady) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (user == null) {
      return ConnexionScreen(onLoginSuccess: _onLoginSuccess);
    }

    // Cache the profile Future so the inner FutureBuilder doesn't
    // restart on every parent rebuild for the same uid.
    if (user.uid != _lastUid) {
      _lastUid = user.uid;
      _profileFuture = FirebaseFirestore.instance
          .collection('citoyens')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 10));
    }

    return FutureBuilder<DocumentSnapshot>(
      future: _profileFuture,
      builder: (context, profileSnapshot) {
        if (profileSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        if (profileSnapshot.hasError) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Text(
                "Erreur: ${profileSnapshot.error}",
                style: const TextStyle(color: AppColors.onSurfaceVariant),
              ),
            ),
          );
        }

        if (!profileSnapshot.hasData || !profileSnapshot.data!.exists) {
          if (user.emailVerified) {
            Future.microtask(() => FirebaseAuth.instance.signOut());
            return const Scaffold(
              backgroundColor: AppColors.background,
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 16),
                    Text(
                      "Compte supprimé — Déconnexion…",
                      style: TextStyle(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            );
          }
          return const CompleteProfileScreen();
        }

        final data = profileSnapshot.data!.data() as Map<String, dynamic>?;
        final role = data?['role'] ?? 'citoyen';

        if (role == 'admin') {
          return const AdminDashboardShell();
        }
        if (role == 'chauffeur') {
          return const DriverMainScreen();
        }
        if (!user.emailVerified) {
          return const VerificationScreen();
        }
        return const MainShell();
      },
    );
  }
}
