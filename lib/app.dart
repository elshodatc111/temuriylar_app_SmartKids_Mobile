import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_kids_app_end/screen/splash/splash_page.dart';
import 'package:smart_kids_app_end/services/internet_service.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Internet xizmatini ishga tushirish
    InternetService().startListening();

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Kids CRM',
      // CRM Tizimiga moslashtirilgan Global Mavzu
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F7F9), // CRM uchun standart fon

        // Ilovaning asosiy ranglar gammasi
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
          primary: const Color(0xFF2196F3),
          surface: Colors.white,
        ),

        // AppBar dizayni (Proyekt matn va ikonka ranglari to'g'irlangan)
        appBarTheme: const AppBarTheme(
          centerTitle: false, // Barcha sahifalarda sarlavha chapda bo'ladi (Professional uslub)
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(
              color: Color(0xFF1A1C1E),
              size: 22
          ),
          actionsIconTheme: IconThemeData(
              color: Color(0xFF1A1C1E),
              size: 22
          ),
          titleTextStyle: TextStyle(
            color: Color(0xFF1A1C1E),
            fontWeight: FontWeight.bold,
            fontSize: 20, // Sarlavha biroz aniqroq ko'rinishi uchun
            letterSpacing: 0.5,
          ),
        ),

        // Karta (Card) dizayni - CRM dagi bloklar uchun
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.black.withOpacity(0.05)),
          ),
        ),

        // Input (TextField) dizayni - Parol va Profil tahrirlash uchun
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blue, width: 2),
          ),
          labelStyle: const TextStyle(color: Colors.blueGrey),
        ),

        // Asosiy tugmalar dizayni
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2196F3),
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),

        // Ro'yxat elementlari (ListTile)
        listTileTheme: const ListTileThemeData(
          iconColor: Colors.blueGrey,
          titleTextStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: Color(0xFF1A1C1E),
          ),
        ),
      ),
      home: const SplashPage(),
    );
  }
}