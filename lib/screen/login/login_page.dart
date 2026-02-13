import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:smart_kids_app_end/const/api_const.dart';
import 'package:smart_kids_app_end/screen/main_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final box = GetStorage();

  final TextEditingController phoneController = TextEditingController(text: '+998 ');
  final TextEditingController passwordController = TextEditingController();

  // Telefon maskasi (Faqat raqamlar va formatlash)
  final phoneMaskFormatter = MaskTextInputFormatter(
    mask: '+998 ## ### ####',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  bool obscurePassword = true;
  bool isLoading = false;

  // Umumiy border dizayni (CRM uslubida)
  OutlineInputBorder _border(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: 1.5),
    );
  }

  // --- LOGIN LOGIC ---
  Future<void> _login() async {
    // 1. Formalarni tekshirish
    if (!_formKey.currentState!.validate()) return;
    if (isLoading) return;

    setState(() => isLoading = true);

    // Xavfsizlik: Raqamni faqat formatlanmagan holda yuboramiz (998901234567)
    final String phone = phoneMaskFormatter.getUnmaskedText();
    final String password = passwordController.text.trim();

    try {
      final response = await http.post(
        Uri.parse('${ApiConst.apiUrl}/login'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "phone": "998$phone", // Davlat kodi bilan birga
          "password": password
        }),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data['token'] != null) {
          await box.write('token', data['token']);
          // Profil ma'lumotlarini ham keshga yozish xavfsizlik uchun foydali
          if (data['user'] != null) {
            await box.write('profile', data['user']);
          }
          Get.offAll(() => const MainPage());
        }
      } else {
        // Serverdan kelgan xabar yoki standart xatolik
        _showError(
          data['message'] ?? (box.read('lang') == 'uz'
              ? 'Telefon raqami yoki parol noto‘g‘ri'
              : 'Неверный номер телефона или пароль'),
        );
      }
    } catch (e) {
      _showError(
        box.read('lang') == 'uz'
            ? 'Server bilan bog‘lanib bo‘lmadi. Internetni tekshiring.'
            : 'Не удалось подключиться к серверу. Проверьте интернет.',
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showError(String message) {
    Get.snackbar(
      box.read('lang') == 'uz' ? 'Xatolik' : 'Ошибка',
      message,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = box.read('lang') ?? 'uz';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 120),
                Hero(tag: 'logo', child: Image.asset('lib/assets/images/logo.png', height: 220)),
                const SizedBox(height: 24),
                Text(
                  lang == 'uz' ? 'Tizimga kirish' : 'Вход в систему',
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1A1C1E)),
                ),
                const SizedBox(height: 40),

                // --- PHONE INPUT ---
                _inputLabel(lang == 'uz' ? 'Telefon raqami' : 'Номер телефона'),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [phoneMaskFormatter],
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: '+998 __ ___ ____',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    enabledBorder: _border(Colors.grey.shade200),
                    focusedBorder: _border(Colors.blue),
                    errorBorder: _border(Colors.red.shade300),
                    focusedErrorBorder: _border(Colors.red),
                  ),
                  validator: (value) {
                    if (!phoneMaskFormatter.isFill()) {
                      return lang == 'uz' ? 'Raqamni to‘liq kiriting' : 'Введите номер полностью';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // --- PASSWORD INPUT ---
                _inputLabel(lang == 'uz' ? 'Parol' : 'Пароль'),
                TextFormField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    suffixIcon: IconButton(
                      icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                      onPressed: () => setState(() => obscurePassword = !obscurePassword),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    enabledBorder: _border(Colors.grey.shade200),
                    focusedBorder: _border(Colors.blue),
                    errorBorder: _border(Colors.red.shade300),
                    focusedErrorBorder: _border(Colors.red),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return lang == 'uz' ? 'Parolni kiriting' : 'Введите пароль';
                    }
                    if (value.length < 8) {
                      return lang == 'uz' ? 'Parol juda qisqa' : 'Пароль слишком короткий';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 40),

                // --- LOGIN BUTTON ---
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      disabledBackgroundColor: Colors.blue.shade200,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? const SpinKitThreeBounce(color: Colors.white, size: 24)
                        : Text(
                      lang == 'uz' ? 'Kirish' : 'Войти',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.blueGrey.shade700)),
      ),
    );
  }
}