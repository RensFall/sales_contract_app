// lib/screens/auth/register_screen.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _mobileController = TextEditingController();

  String _userType = 'buyer';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A3A6F)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Create Account".tr(),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A3A6F),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Sign up to get started".tr(),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 32),

                // Full Name Field
                TextFormField(
                  controller: _fullNameController,
                  decoration: InputDecoration(
                    labelText: "Full Name".tr(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return "Please enter your full name".tr();
                    }
                    if (value!.trim().split(' ').length < 2) {
                      return "Please enter your full name (first and last name)"
                          .tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "Email".tr(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return "Please enter your email".tr();
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value!)) {
                      return "Please enter a valid email".tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: "Password".tr(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    helperText:
                        "Must be 8+ characters with uppercase, lowercase, and numbers"
                            .tr(),
                    helperStyle: const TextStyle(fontSize: 12),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return "Please enter your password".tr();
                    }
                    if (value!.length < 8) {
                      return "Password must be at least 8 characters".tr();
                    }
                    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).+$')
                        .hasMatch(value)) {
                      return "Password must contain uppercase, lowercase, and numbers"
                          .tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // ID Number Field
                TextFormField(
                  controller: _idNumberController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: InputDecoration(
                    labelText: "ID/Iqama Number".tr(),
                    prefixIcon: Icon(Icons.badge_outlined),
                    hintText: "10 digits".tr(),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return "Please enter your ID/Iqama number".tr();
                    }
                    if (value!.length != 10) {
                      return "ID/Iqama number must be 10 digits".tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Mobile Number Field
                TextFormField(
                  controller: _mobileController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: InputDecoration(
                    labelText: "Mobile Number".tr(),
                    prefixIcon: Icon(Icons.phone_outlined),
                    hintText: "05XXXXXXXX".tr(),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return "Please enter your mobile number".tr();
                    }
                    if (value!.length != 10) {
                      return "Mobile number must be 10 digits".tr();
                    }
                    if (!value.startsWith('05')) {
                      return "Mobile number must start with 05".tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                // Terms and Conditions Checkbox
                CheckboxListTile(
                  value: _acceptTerms,
                  onChanged: (value) => setState(() => _acceptTerms = value!),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    "I accept the Terms of Service and Privacy Policy".tr(),
                    style: TextStyle(fontSize: 14),
                  ),
                  subtitle: Text(
                    "You must accept the terms to continue".tr(),
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(height: 32),

                // Register Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed:
                        (_isLoading || !_acceptTerms) ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A3A6F),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // Sign In Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(color: Colors.grey),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          color: Color(0xFF1A3A6F),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleRegister() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Start loading
    setState(() => _isLoading = true);

    try {
      // Call auth service to create account
      await context.read<AuthService>().signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            fullName: _fullNameController.text.trim(),
            idNumber: _idNumberController.text,
            mobileNumber: _mobileController.text,
            userType: _userType,
          );

      // Show success dialog if mounted
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            icon: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 64,
            ),
            title: const Text('Registration Successful'),
            content: const Text(
              'Your account has been created successfully. '
              'You can now start using Marine Contracts.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pushReplacementNamed(context, '/home');
                },
                child: const Text('Continue'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Show error message if mounted
      if (mounted) {
        String errorMessage = 'Registration failed';

        // Parse Firebase error messages
        if (e.toString().contains('email-already-in-use')) {
          errorMessage = 'This email is already registered';
        } else if (e.toString().contains('weak-password')) {
          errorMessage = 'Password is too weak';
        } else if (e.toString().contains('invalid-email')) {
          errorMessage = 'Invalid email address';
        } else if (e.toString().contains('network-request-failed')) {
          errorMessage = 'Network error. Please check your connection';
        }

        // Show error snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } finally {
      // Stop loading if mounted
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _idNumberController.dispose();
    _mobileController.dispose();
    super.dispose();
  }
}
