import 'package:Temuriylar/screen/login/login_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = GetStorage().read('lang') ?? 'uz';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Yuqoridagi bo'shliqni kengaytirish uchun spacer
              const Spacer(flex: 2),

              // Logo qismi
              Hero(
                tag: 'logo',
                child: Image.asset(
                  'lib/assets/images/logo.png',
                  height: 220,
                  errorBuilder: (c, e, s) => const Icon(Icons.auto_awesome_mosaic_rounded, size: 80, color: Colors.blue),
                ),
              ),
              const SizedBox(height: 24),

              // Tavsif matni (Imlo xatolari to'g'irlangan)
              Text(
                lang == 'uz'
                    ? "Bog‘cha boshqaruv tizimi.\nBolalar bog‘chasini zamonaviy, qulay va ishonchli tarzda boshqaring."
                    : "Система управления детским садом.\nУправляйте детским садом современно, удобно и надёжно.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Colors.blueGrey.shade600,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const Spacer(flex: 2),

              // Kirish tugmasi
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Get.offAll(() => const LoginPage());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600, // CRM rangiga moslandi
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0, // Zamonaviy tekis dizayn
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        lang == 'uz' ? 'Boshlash' : 'Начать',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40), // Pastdan masofa
            ],
          ),
        ),
      ),
    );
  }
}