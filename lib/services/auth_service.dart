// lib/services/auth_service.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  bool get isAuthenticated => _auth.currentUser != null;
  bool get isAdmin => _currentUser?.userType == 'admin';

  // Initialize auth state listener
  AuthService() {
    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        await _loadUserData(user.uid);
      } else {
        _currentUser = null;
        notifyListeners();
      }
    });
  }

  Future<void> signIn(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user != null) {
        await _loadUserData(credential.user!.uid);
      }
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors
      switch (e.code) {
        case 'user-not-found':
          throw Exception('No user found with this email');
        case 'wrong-password':
          throw Exception('Incorrect password');
        case 'invalid-email':
          throw Exception('Invalid email address');
        case 'user-disabled':
          throw Exception('This account has been disabled');
        default:
          throw Exception('Failed to sign in: ${e.message}');
      }
    } catch (e) {
      // Handle other errors
      throw Exception('Failed to sign in: ${e.toString()}');
    }
  }

  Future<void> _loadUserData(String uid) async {
    try {
      // Get specific document, not a query
      final DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();

      if (doc.exists && doc.data() != null) {
        // Safely cast the data
        final data = doc.data() as Map<String, dynamic>;
        _currentUser = UserModel.fromMap({
          ...data,
          'uid': uid, // Ensure UID is included
        });
        notifyListeners();
      } else {
        // If user document doesn't exist, create it
        final user = _auth.currentUser;
        if (user != null) {
          final newUser = UserModel(
            uid: user.uid,
            email: user.email ?? '',
            fullName: user.displayName ?? 'User',
            idNumber: '',
            mobileNumber: '',
            userType: 'buyer',
            createdAt: DateTime.now(),
          );

          await _firestore
              .collection('users')
              .doc(user.uid)
              .set(newUser.toMap());
          _currentUser = newUser;
          notifyListeners();
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      throw Exception('Failed to load user data: ${e.toString()}');
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String idNumber,
    required String mobileNumber,
    required String userType,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user != null) {
        // Update display name
        await credential.user!.updateDisplayName(fullName);

        final user = UserModel(
          uid: credential.user!.uid,
          email: email,
          fullName: fullName,
          idNumber: idNumber,
          mobileNumber: mobileNumber,
          userType: userType,
          createdAt: DateTime.now(),
        );

        // Create user document
        await _firestore.collection('users').doc(user.uid).set(user.toMap());

        _currentUser = user;
        notifyListeners();
      }
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'weak-password':
          throw Exception('The password is too weak');
        case 'email-already-in-use':
          throw Exception('An account already exists with this email');
        case 'invalid-email':
          throw Exception('Invalid email address');
        default:
          throw Exception('Failed to sign up: ${e.message}');
      }
    } catch (e) {
      throw Exception('Failed to sign up: ${e.toString()}');
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to sign out: ${e.toString()}');
    }
  }

  Future<void> sendVerificationOTP(String contractId) async {
    // TODO: Implement OTP verification
    // This would integrate with your SMS service
    await Future.delayed(const Duration(seconds: 2)); // Simulate API call
  }

  Future<bool> verifyOTP(String contractId, String otp) async {
    // TODO: Implement OTP verification
    // For testing, accept "123456" as valid OTP
    await Future.delayed(const Duration(seconds: 1)); // Simulate API call
    return otp == '123456';
  }
}
