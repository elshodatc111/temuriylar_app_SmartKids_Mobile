import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get_storage/get_storage.dart';

class NoConnect extends StatelessWidget {
  const NoConnect({super.key});

  @override
  Widget build(BuildContext context) {
    // Tilni build ichida o'qish har doim yangi ma'lumotni kafolatlaydi
    final String lang = GetStorage().read('lang')?.toString() ?? 'uz';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Internet uzilganligini bildiruvchi zamonaviy ikonka
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  size: 100,
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 40),

              // Asosiy xabar
              Text(
                lang == 'uz'
                    ? 'Internet bilan bog‘lanish yo‘q'
                    : "Нет подключения к интернету",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1C1E),
                ),
              ),
              const SizedBox(height: 12),

              // Yordamchi matn
              Text(
                lang == 'uz'
                    ? 'Iltimos, tarmoq ulanishini tekshiring. Aloqa tiklangach, sahifa avtomatik yangilanadi.'
                    : "Пожалуйста, проверьте подключение к сети. Страница обновится автоматически при восстановлении связи.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 60),

              // Loyiha rangidagi zamonaviy yuklanish indikatori
              const SpinKitThreeBounce(
                color: Colors.blue, // deepPurple o'rniga loyiha ko'k rangi
                size: 35,
              ),
              const SizedBox(height: 20),

              // Kutish holati matni
              Text(
                lang == 'uz' ? 'Ulanish kutilmoqda...' : "Ожидание подключения...",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue.shade300,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}