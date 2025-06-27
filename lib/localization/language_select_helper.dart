import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../screens/auth/login_screen.dart';
import 'language_helper.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('welcome'.tr(),
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Text('select_language'.tr(),
                  style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 40),
              _buildLanguageButton(
                context,
                locale: const Locale('en'),
                label: 'english'.tr(),
              ),
              const SizedBox(height: 20),
              _buildLanguageButton(
                context,
                locale: const Locale('ar'),
                label: 'arabic'.tr(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageButton(BuildContext context,
      {required Locale locale, required String label}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: () async {
          await LanguageHelper.saveLanguage(locale);
          context.setLocale(locale);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        },
        child: Text(label),
      ),
    );
  }
}
