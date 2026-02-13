import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:smart_kids_app_end/screen/splash/welcome_page.dart';

class LangPage extends StatelessWidget {
  const LangPage({super.key});

  void _changeLang(String lang) {
    GetStorage().write('lang', lang);
    Get.offAll(() => const WelcomePage());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo qismi
              Hero(
                tag: 'logo',
                child: Image.asset(
                  'lib/assets/images/logo.png',
                  height: 220,
                  errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.school_outlined, size: 80, color: Colors.blue),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Smart Kids",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Color(0xFF1A1C1E),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Tilni tanlang · Выберите язык",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 40),

              // O'zbek tili
              _langButton(
                title: "O'zbekcha",
                flagPath: 'lib/assets/images/uz.png',
                onTap: () => _changeLang('uz'),
              ),

              const SizedBox(height: 16),

              // Rus tili
              _langButton(
                title: "Русский",
                flagPath: 'lib/assets/images/ru.png',
                onTap: () => _changeLang('ru'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Takrorlanuvchi tugmalar uchun alohida Widget
  Widget _langButton({
    required String title,
    required String flagPath,
    required VoidCallback onTap
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withOpacity(0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.asset(
                  flagPath,
                  width: 32,
                  height: 24,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => const Icon(Icons.flag_outlined),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
              const Spacer(),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}