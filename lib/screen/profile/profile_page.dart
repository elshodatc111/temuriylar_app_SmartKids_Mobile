import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:smart_kids_app_end/const/api_const.dart';
import 'package:smart_kids_app_end/screen/login/login_page.dart';
import 'package:smart_kids_app_end/screen/splash/splash_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final box = GetStorage();
  bool isLoading = false;
  bool isActionLoading = false;
  Map<String, dynamic>? profile;
  String imageCacheKey = DateTime.now().millisecondsSinceEpoch.toString();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null || dateStr.toString().isEmpty) return '-';
    try {
      DateTime dt = DateTime.parse(dateStr.toString());
      return DateFormat('yyyy-MM-dd').format(dt);
    } catch (e) {
      return dateStr.toString();
    }
  }

  String _formatSalary(dynamic salary) {
    if (salary == null) return '0';
    final formatter = NumberFormat("#,###", "uz_UZ");
    try {
      return formatter.format(double.parse(salary.toString())).replaceAll(',', ' ');
    } catch (e) {
      return salary.toString();
    }
  }

  Future<void> _loadProfile({bool forceRefresh = false}) async {
    final lang = box.read('lang') ?? 'uz';
    if (mounted) setState(() => isLoading = true);
    try {
      if (!forceRefresh && box.hasData('profile')) {
        profile = Map<String, dynamic>.from(box.read('profile'));
        if (mounted) setState(() => isLoading = false);
        return;
      }
      final String? token = box.read('token');
      final response = await http.get(
        Uri.parse('${ApiConst.apiUrl}/profile'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        setState(() {
          profile = body['data'];
          box.write('profile', profile);
        });
      } else if (response.statusCode == 401) {
        _logoutForce();
      }
    } catch (e) {
      _showError(lang == 'uz' ? 'Maʼlumot yuklashda xatolik yuz berdi' : "Ошибка при загрузке данных");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _updatePassword(String current, String newP, String confirm) async {
    final lang = box.read('lang') ?? 'uz';
    if (newP != confirm) return _showError(lang == 'uz' ? 'Yangi parollar mos kelmadi' : "Новые пароли не совпадают");
    if (current.isEmpty || newP.isEmpty) return _showError(lang == 'uz' ? 'Barcha maydonlarni to\'ldiring' : "Заполните все поля");

    setState(() => isActionLoading = true);
    try {
      final String? token = box.read('token');
      final response = await http.post(
        Uri.parse('${ApiConst.apiUrl}/profile/password'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'current_password': current,
          'new_password': newP,
          'new_password_confirmation': confirm,
        }),
      );
      if (response.statusCode == 200) {
        Get.back();
        Get.snackbar(
          lang == 'uz' ? 'Muvaffaqiyatli' : "Успешно",
          lang == 'uz' ? 'Parol muvaffaqiyatli yangilandi' : "Пароль успешно обновлен",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        final error = jsonDecode(response.body);
        _showError(error['message'] ?? (lang == "uz" ? 'Xatolik yuz berdi' : "Произошла ошибка"));
      }
    } catch (e) {
      _showError(lang == "uz" ? 'Server bilan bog‘lanishda xatolik' : "Ошибка подключения к серверу");
    } finally {
      setState(() => isActionLoading = false);
    }
  }

  Future<void> _updateProfile(String name, String birth, String series) async {
    final lang = box.read('lang') ?? 'uz';
    if (name.isEmpty || birth.isEmpty || series.isEmpty) return _showError(lang == 'uz' ? 'Barcha maydonlarni to\'ldiring' : "Заполните все поля");

    setState(() => isActionLoading = true);
    try {
      final String? token = box.read('token');
      final response = await http.post(
        Uri.parse('${ApiConst.apiUrl}/profile/update'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'name': name, 'birth': birth, 'series': series}),
      );
      if (response.statusCode == 200) {
        Get.back();
        Get.snackbar(
          lang == 'uz' ? 'Muvaffaqiyatli' : "Успешно",
          lang == 'uz' ? 'Profil maʼlumotlari yangilandi' : "Данные профиля обновлены",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        _loadProfile(forceRefresh: true);
      } else {
        _showError(lang == 'uz' ? 'Tahrirlashda xatolik yuz berdi' : "Ошибка при редактировании");
      }
    } catch (e) {
      _showError(lang == 'uz' ? 'Aloqa xatosi' : "Ошибка связи");
    } finally {
      setState(() => isActionLoading = false);
    }
  }

  Future<void> _uploadImage(String filePath) async {
    final lang = box.read('lang') ?? 'uz';
    setState(() => isLoading = true);
    try {
      String? token = box.read('token');
      var request = http.MultipartRequest('POST', Uri.parse('${ApiConst.apiUrl}/profile/image'));
      request.headers.addAll({'Authorization': 'Bearer $token', 'Accept': 'application/json'});
      request.files.add(await http.MultipartFile.fromPath('image', filePath));
      var response = await request.send();
      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() => imageCacheKey = DateTime.now().millisecondsSinceEpoch.toString());
        Get.snackbar(
          lang == 'uz' ? 'Muvaffaqiyatli' : "Успешно",
          lang == 'uz' ? 'Profil rasmi yangilandi' : "Фото профиля обновлено",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        _loadProfile(forceRefresh: true);
      }
    } catch (e) {
      _showError(lang == 'uz' ? 'Rasmni yuklashda xatolik' : "Ошибка при загрузке изображения");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showPasswordDialog(String lang) {
    final current = TextEditingController();
    final newP = TextEditingController();
    final confirm = TextEditingController();
    Get.bottomSheet(
      StatefulBuilder(builder: (context, setModalState) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(lang == 'uz' ? 'Parolni yangilash' : 'Сменить пароль', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _textField(current, lang == 'uz' ? 'Joriy parol' : 'Текущий parol', isPass: true),
                _textField(newP, lang == 'uz' ? 'Yangi parol' : 'Новый parol', isPass: true),
                _textField(confirm, lang == 'uz' ? 'Parolni tasdiqlang' : 'Подтвердите parol', isPass: true),
                const SizedBox(height: 20),
                isActionLoading
                    ? const SpinKitThreeBounce(color: Colors.blue, size: 30)
                    : ElevatedButton(
                  onPressed: () async {
                    setModalState(() => isActionLoading = true);
                    await _updatePassword(current.text, newP.text, confirm.text);
                    if (mounted) setModalState(() => isActionLoading = false);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text(lang == 'uz' ? 'Saqlash' : 'Сохранить', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      }),
      isScrollControlled: true,
    );
  }

  void _showEditProfileDialog(String lang) {
    final name = TextEditingController(text: profile?['name']);
    final series = TextEditingController(text: profile?['series']);
    String selectedDate = profile?['birth'] ?? '';
    Get.bottomSheet(
      StatefulBuilder(builder: (context, setModalState) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(lang == 'uz' ? 'Profilni tahrirlash' : 'Редактировать профиль', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _textField(name, lang == 'uz' ? 'Ism sharif' : 'ФИО'),
                _textField(series, lang == 'uz' ? 'Passport seriyasi' : 'Серия паспорта'),
                GestureDetector(
                  onTap: () async {
                    DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: profile?['birth'] != null ? DateTime.parse(profile!['birth']) : DateTime.now(),
                        firstDate: DateTime(1950),
                        lastDate: DateTime.now()
                    );
                    if (picked != null) setModalState(() => selectedDate = DateFormat('yyyy-MM-dd').format(picked));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(selectedDate.isEmpty ? (lang == 'uz' ? 'Tug‘ilgan sana' : 'Дата рождения') : selectedDate, style: TextStyle(color: selectedDate.isEmpty ? Colors.grey[600] : Colors.black, fontSize: 16)),
                        const Icon(Icons.calendar_month, color: Colors.blueGrey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                isActionLoading
                    ? const SpinKitThreeBounce(color: Colors.blue, size: 30)
                    : ElevatedButton(
                  onPressed: () async {
                    setModalState(() => isActionLoading = true);
                    await _updateProfile(name.text, selectedDate, series.text);
                    if (mounted) setModalState(() => isActionLoading = false);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text(lang == 'uz' ? 'Yangilash' : 'Обновить', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      }),
      isScrollControlled: true,
    );
  }

  Widget _textField(TextEditingController controller, String label, {bool isPass = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        obscureText: isPass,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.blueGrey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blue, width: 2)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = box.read('lang') ?? 'uz';
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(lang == 'uz' ? 'Profil' : 'Профиль', style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: () => _loadProfile(forceRefresh: true),
            icon: isLoading ? const SpinKitRing(color: Colors.blue, size: 20, lineWidth: 2) : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          profile == null && isLoading ? const Center(child: SpinKitDoubleBounce(color: Colors.blue, size: 50)) : (profile == null ? _buildEmpty(lang) : _buildProfile(lang)),
          if (profile != null && isLoading)
            Container(color: Colors.black12, child: const Center(child: SpinKitFadingCircle(color: Colors.blue, size: 50))),
        ],
      ),
    );
  }

  Widget _buildProfile(String lang) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))]),
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(60),
                      child: CachedNetworkImage(
                        imageUrl: "${profile?['image']}?v=$imageCacheKey",
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorWidget: (c, u, e) => const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
                      ),
                    ),
                  ),
                  Positioned(bottom: 0, right: 0, child: GestureDetector(onTap: () => _showImagePickerOptions(context, lang), child: const CircleAvatar(radius: 18, backgroundColor: Colors.white, child: Icon(Icons.camera_alt, color: Colors.blue, size: 18)))),
                ],
              ),
              const SizedBox(height: 15),
              Text(profile?['name'] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              Text(profile?['phone'] ?? '', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _sectionTitle(lang == 'uz' ? 'Maʼlumotlar' : 'Информация'),
        _infoTile(Icons.payments_rounded, lang == 'uz' ? 'Oylik ish haqi' : 'Заработная плата', '${_formatSalary(profile?['salary_amount'])} UZS'),
        _infoTile(Icons.event_note_rounded, lang == 'uz' ? 'Tug‘ilgan sana' : 'Дата рождения', _formatDate(profile?['birth'])),
        _infoTile(Icons.badge_rounded, lang == 'uz' ? 'Passport seriyasi' : 'Серия паспорта', profile?['series'] ?? '-'),
        _infoTile(Icons.assignment_ind_rounded, lang == 'uz' ? 'Lavozim' : 'Тип', profile?['type']?.toString().toUpperCase() ?? '-'),
        const SizedBox(height: 24),
        _sectionTitle(lang == 'uz' ? 'Sozlamalar' : 'Настройки'),
        _actionTile(Icons.lock_reset_rounded, lang == 'uz' ? 'Parolni yangilash' : 'Сменить parol', () => _showPasswordDialog(lang)),
        _actionTile(Icons.person_outline_rounded, lang == 'uz' ? 'Profilni tahrirlash' : 'Редактировать profil', () => _showEditProfileDialog(lang)),
        _actionTile(Icons.translate_rounded, lang == 'uz' ? 'Ilova tili' : 'Язык приложения', () => _showLanguageDialog(lang), suffix: Text(lang == 'uz' ? "O'zbekcha" : "Русский", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
        const SizedBox(height: 32),
        _logoutButton(lang),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _infoTile(IconData icon, String title, String value) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.black.withOpacity(0.05))),
    child: ListTile(
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: Colors.blue, size: 22)),
      title: Text(title, style: TextStyle(color: Colors.grey[700], fontSize: 14)),
      trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
    ),
  );

  Widget _actionTile(IconData icon, String title, VoidCallback onTap, {Widget? suffix}) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.black.withOpacity(0.05))),
    child: ListTile(
      onTap: onTap,
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: Colors.blueGrey, size: 22)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      trailing: suffix ?? const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
    ),
  );

  Widget _sectionTitle(String title) => Padding(padding: const EdgeInsets.only(left: 8, bottom: 10), child: Text(title.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[600], fontSize: 12, letterSpacing: 1)));

  Widget _logoutButton(String lang) => InkWell(
    onTap: () => _logout(lang),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.red.withOpacity(0.2))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.power_settings_new_rounded, color: Colors.red),
          const SizedBox(width: 10),
          Text(lang == 'uz' ? 'Tizimdan chiqish' : 'Выйти из системы', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    ),
  );

  void _showError(String message) {
    final lang = box.read('lang') ?? 'uz';
    Get.snackbar(lang == 'uz' ? 'Xatolik' : "Ошибка", message, backgroundColor: Colors.redAccent, colorText: Colors.white, snackPosition: SnackPosition.TOP, margin: const EdgeInsets.all(15), borderRadius: 10);
  }

  void _logoutForce() {
    box.remove('token');
    box.remove('profile');
    Get.offAll(() => const LoginPage());
  }

  // Yaxshilangan va tugmalari yonma-yon turadigan Logout dialog
  void _logout(String lang) {
    Get.dialog(
      BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: const CircleAvatar(backgroundColor: Color(0xFFFFEBEE), radius: 25, child: Icon(Icons.logout_rounded, color: Colors.redAccent)),
          title: Text(lang == 'uz' ? 'Chiqish' : 'Выход', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                lang == 'uz' ? 'Hisobdan chiqishni xohlaysizmi?' : 'Вы действительно хотите выйти?',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  // Yo'q tugmasi
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade300)),
                      ),
                      child: Text(lang == 'uz' ? 'Yo\'q' : 'Нет', style: const TextStyle(color: Colors.black87)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Ha, chiqish tugmasi
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _logoutForce,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(lang == 'uz' ? 'Ha, chiqish' : 'Да, выйти', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImagePickerOptions(BuildContext context, String lang) {
    Get.bottomSheet(Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(lang == 'uz' ? 'Profil rasmini yangilash' : 'Обновить фото профиля', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(lang == 'uz' ? 'Rasm yuklash usulini tanlang' : 'Выберите способ загрузки фото', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          ListTile(leading: const Icon(Icons.photo_library_rounded, color: Colors.blue), title: Text(lang == 'uz' ? 'Galereyadan tanlash' : 'Выбрать из галереи'), onTap: () { Get.back(); _pickImage(ImageSource.gallery); }),
          ListTile(leading: const Icon(Icons.camera_alt_rounded, color: Colors.green), title: Text(lang == 'uz' ? 'Kamera orqali olish' : 'Сделать фото с камеры'), onTap: () { Get.back(); _pickImage(ImageSource.camera); }),
          const SizedBox(height: 10),
        ])));
  }

  void _showLanguageDialog(String currentLang) {
    Get.bottomSheet(Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(currentLang == 'uz' ? 'Ilova tilini tanlang' : 'Выберите язык приложения', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _langOption("O'zbekcha", 'uz', currentLang == 'uz'),
          const Divider(height: 1),
          _langOption("Русский", 'ru', currentLang == 'ru'),
          const SizedBox(height: 10),
        ])));
  }

  Widget _langOption(String name, String code, bool isSelected) => ListTile(title: Text(name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.blue : Colors.black)), trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: Colors.blue) : null, onTap: () { box.write('lang', code); Get.offAll(() => const SplashPage()); });

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source, imageQuality: 50);
    if (image != null) await _uploadImage(image.path);
  }

  Widget _buildEmpty(String lang) => Center(child: Text(lang == 'uz' ? 'Maʼlumot topilmadi' : 'Данные не найдены'));
}