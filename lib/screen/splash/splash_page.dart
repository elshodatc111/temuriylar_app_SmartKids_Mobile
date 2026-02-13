import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:smart_kids_app_end/const/api_const.dart';
import 'package:smart_kids_app_end/screen/main_page.dart';
import 'package:smart_kids_app_end/screen/splash/lang_page.dart';
import '../login/login_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final box = GetStorage();

  @override
  void initState() {
    super.initState();
    _startApp();
  }

  // Ilovani boshlash mantig'i
  Future<void> _startApp() async {
    // Splash ekranda biroz ushlab turish (brending uchun)
    await Future.delayed(const Duration(seconds: 3));

    final String? lang = box.read('lang');
    final String? token = box.read('token');

    // 1. Til tanlanmagan bo'lsa, til tanlash sahifasiga
    if (lang == null) {
      Get.offAll(() => const LangPage());
      return;
    }

    // 2. Token bo'lmasa, login sahifasiga
    if (token == null || token.isEmpty) {
      Get.offAll(() => const LoginPage());
      return;
    }

    // 3. Token bo'lsa, uning haqiqiyligini tekshirish
    final bool isValid = await _checkProfile(token);
    if (isValid) {
      Get.offAll(() => const MainPage());
    } else {
      // Token muddati o'tgan yoki noto'g'ri bo'lsa
      await box.remove('token');
      await box.remove('profile');
      Get.offAll(() => const LoginPage());
    }
  }

  // Profil orqali tokenni tekshirish
  Future<bool> _checkProfile(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConst.apiUrl}/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10)); // Timeout qo'shish shart

      if (response.statusCode == 200) {
        // Yangi ma'lumotlarni keshga saqlab qo'yish (ixtiyoriy)
        final body = jsonDecode(response.body);
        box.write('profile', body['data']);
        return true;
      }
      return false;
    } catch (e) {
      // Internet uzilgan bo'lsa ham keshdagi ma'lumot bilan kirishga ruxsat berish mumkin
      // Lekin xavfsizlik uchun false qaytaramiz yoki keshni tekshiramiz
      return box.hasData('profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo qismi (Hero widgeti bilan)
            Hero(
              tag: 'logo',
              child: Image.asset(
                'lib/assets/images/logo.png',
                width: 220,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 50),
            // CRM rangiga mos yuklanish belgisi
            const SpinKitFadingCircle(
              color: Colors.blue, // deepPurple o'rniga loyiha rangi (ko'k)
              size: 45.0,
            ),
          ],
        ),
      ),
    );
  }
}