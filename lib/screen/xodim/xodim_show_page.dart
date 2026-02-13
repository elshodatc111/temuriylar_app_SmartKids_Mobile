import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smart_kids_app_end/screen/xodim/hodim_davomad_tarixi.dart';
import 'package:smart_kids_app_end/screen/xodim/hodim_guruhlar_tarixi.dart';
import 'package:smart_kids_app_end/screen/xodim/ish_haqi_tulovlari.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:smart_kids_app_end/const/api_const.dart';

class XodimShowPage extends StatefulWidget {
  final int id;

  const XodimShowPage({super.key, required this.id});

  @override
  State<XodimShowPage> createState() => _XodimShowPageState();
}

class _XodimShowPageState extends State<XodimShowPage> {
  final box = GetStorage();
  bool isLoading = true;
  bool isSaving = false;
  bool isPasswordUpdating = false;
  bool isPaymentLoading = false;
  Map<String, dynamic>? userData;
  final f = NumberFormat("#,###", "uz_UZ");

  Map<String, dynamic> get profile => box.read('profile') ?? {};

  String get currentUserType => profile['type']?.toString() ?? 'user';

  String get lang => box.read('lang') ?? 'uz';

  @override
  void initState() {
    super.initState();
    fetchUserInfo();
  }

  // --- API: MA'LUMOTLARNI YUKLASH ---
  Future<void> fetchUserInfo() async {
    setState(() => isLoading = true);
    String? token = box.read('token');
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConst.apiUrl}/emploes/shows/${widget.id}'),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));
      print(response.statusCode);
      if (response.statusCode == 200) {
        var decoded = jsonDecode(response.body);
        if (decoded['status'] == true) {
          setState(() {
            userData = decoded['user'];
            isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Xodim Show Error: $e");
    }
  }

  // --- API: MA'LUMOTLARNI YANGILASH ---
  Future<void> _updateEmployee(Map<String, dynamic> data) async {
    setState(() => isSaving = true);
    String? token = box.read('token');
    try {
      final response = await http.post(
        Uri.parse('${ApiConst.apiUrl}/emploes/update/${widget.id}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pop(context);
        fetchUserInfo();
        Get.snackbar(
          lang == 'uz' ? "Muvaffaqiyatli" : "Успешно",
          lang == 'uz' ? "Ma'lumotlar yangilandi" : "Данные обновлены",
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(15),
        );
      }
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      setState(() => isSaving = false);
    }
  }

  // --- API: ISH HAQI TO'LOVINI AMALGA OSHIRISH ---
  Future<void> _submitPayment(Map<String, dynamic> data) async {
    setState(() => isPaymentLoading = true);
    String? token = box.read('token');
    try {
      final response = await http.post(
        Uri.parse('${ApiConst.apiUrl}/emploes/create/paymart/${widget.id}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pop(context);
        fetchUserInfo();
        Get.snackbar(
          lang == 'uz' ? "Muvaffaqiyatli" : "Успешно",
          lang == 'uz' ? "To'lov bajarildi" : "Оплата произведена",
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(15),
        );
      }
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      setState(() => isPaymentLoading = false);
    }
  }

  // --- API: PAROLNI YANGILASH ---
  Future<void> _updatePassword() async {
    setState(() => isPasswordUpdating = true);
    String? token = box.read('token');
    try {
      final response = await http.post(
        Uri.parse('${ApiConst.apiUrl}/emploes/update/password/${widget.id}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        Navigator.pop(context);
        Get.snackbar(
          lang == 'uz' ? "Muvaffaqiyatli" : "Успешно",
          lang == 'uz' ? "Parol yangilandi" : "Пароль обновлен",
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(15),
        );
      }
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      setState(() => isPasswordUpdating = false);
    }
  }

  Future<void> _makeCall(String phoneNumber) async {
    final String cleanPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
    final Uri launchUri = Uri(scheme: 'tel', path: "+$cleanPhone");
    try {
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      Get.snackbar(
        lang == 'uz' ? "Xatolik" : "Ошибка",
        "Dialer error",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(" "),
        actions: [
          IconButton(
            onPressed: fetchUserInfo,
            icon: const Icon(Icons.sync_rounded, color: Colors.blue),
          ),
        ],
      ),
      body: isLoading ? _buildShimmerLoader() : _buildProfileBody(),
    );
  }

  Widget _buildProfileBody() {
    if (userData == null) return const Center(child: Text("Data not found"));
    bool isTarbiyachi =
        userData!['type'].toString().toLowerCase() == 'tarbiyachi';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildHeaderSection(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _infoCard(
                  title: lang == 'uz'
                      ? "Aloqa va Shaxsiy"
                      : "Связь и Личные данные",
                  footerButtons: [
                    if (currentUserType == 'admin')
                      _smallActionBtn(
                        Icons.account_balance_wallet_rounded,
                        lang == 'uz' ? "To'lov" : "Оплата",
                        Colors.teal,
                        () => _showPaymentModal(),
                      ),
                    if (currentUserType == 'admin') const SizedBox(width: 10),
                    _smallActionBtn(
                      Icons.edit_square,
                      lang == 'uz' ? "Tahrirlash" : "Изменить",
                      Colors.indigo,
                      () => _showEditModal(),
                    ),
                    const SizedBox(width: 10),
                    _smallActionBtn(
                      Icons.key_rounded,
                      lang == 'uz' ? "Parol" : "Пароль",
                      Colors.blueGrey,
                      () => _showPasswordUpdateModal(),
                    ),
                  ],
                  items: [
                    _infoRow(
                      Icons.phone_iphone_rounded,
                      lang == 'uz' ? "Telefon" : "Телефон",
                      userData!['phone'] ?? '-',
                      isPhone: true,
                      onPhoneTap: () => _makeCall(userData!['phone'] ?? ''),
                    ),
                    _infoRow(
                      Icons.assignment_ind_rounded,
                      lang == 'uz' ? "Pasport seriyasi" : "Серия паспорта",
                      userData!['series'] ?? '-',
                    ),
                    _infoRow(
                      Icons.cake_rounded,
                      lang == 'uz' ? "Tug'ilgan sana" : "Дата рождения",
                      _formatDate(userData!['birth']),
                    ),
                  ],
                ),
                _infoCard(
                  title: lang == 'uz'
                      ? "Moliyaviy holat"
                      : "Финансовое состояние",
                  footerButtons: [
                    _smallActionBtn(
                      Icons.fact_check_rounded,
                      lang == 'uz' ? "Davomad" : "Посещаемость",
                      Colors.deepPurple,
                      () => Get.to(() => HodimDavomadTarixi(id: widget.id)),
                    ),
                    const SizedBox(width: 10),
                    _smallActionBtn(
                      Icons.receipt_long_rounded,
                      lang == 'uz' ? "To'lovlar tarixi" : "История платежей",
                      Colors.blueGrey,
                      () => Get.to(() => IshHaqiTulovlari(id: widget.id)),
                    ),
                    if (isTarbiyachi) const SizedBox(width: 10),
                    if (isTarbiyachi)
                      _smallActionBtn(
                        Icons.groups_rounded,
                        lang == 'uz' ? "Guruhlar" : "Группы",
                        Colors.orange,
                        () => Get.to(() => HodimGuruhlarTarixi(id: widget.id)),
                      ),
                  ],
                  items: [
                    _infoRow(
                      Icons.payments_rounded,
                      lang == 'uz' ? "Oylik maoshi" : "Зарплата",
                      "${f.format(userData!['salary_amount'] ?? 0)} UZS",
                      color: Colors.teal,
                    ),
                    _infoRow(
                      Icons.calendar_today_rounded,
                      lang == 'uz'
                          ? "Ish boshlagan sana"
                          : "Дата начала работы",
                      _formatDate(userData!['created_at']),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    bool isActive = userData!['is_active'] == true;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      child: Column(
        children: [
          Hero(
            tag: 'avatar_${widget.id}',
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 55,
                    backgroundColor: const Color(0xFFF1F5F9),
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: userData!['image'] ?? '',
                        placeholder: (context, url) =>
                            const SpinKitPulse(color: Colors.blue, size: 30),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.person_rounded,
                          size: 60,
                          color: Colors.blueGrey,
                        ),
                        fit: BoxFit.cover,
                        width: 110,
                        height: 110,
                      ),
                    ),
                  ),
                ),
                Container(
                  height: 28,
                  width: 28,
                  decoration: BoxDecoration(
                    color: isActive ? Colors.teal : Colors.redAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            userData!['name'] ?? '-',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.shield_rounded,
                  size: 14,
                  color: Colors.blue.shade700,
                ),
                const SizedBox(width: 6),
                Text(
                  userData!['type'].toString().toUpperCase(),
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- REUSABLE COMPONENTS ---
  Widget _modalContainer({required Widget child}) => Container(
    padding: EdgeInsets.fromLTRB(
      24,
      12,
      24,
      24 + MediaQuery.of(context).viewInsets.bottom,
    ),
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 5,
          decoration: BoxDecoration(
            color: Colors.blueGrey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(height: 20),
        child,
      ],
    ),
  );

  Widget _modalHeader(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: Color(0xFF1E293B),
      ),
    ),
  );

  Widget _primaryBtn({
    required VoidCallback onPressed,
    required bool isLoading,
    required String text,
    required Color color,
  }) => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      child: isLoading
          ? const SpinKitThreeBounce(color: Colors.white, size: 20)
          : Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
    ),
  );

  Widget _smallActionBtn(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) => Material(
    color: color.withOpacity(0.08),
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _infoCard({
    required String title,
    required List<Widget> items,
    List<Widget>? footerButtons,
  }) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(top: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Colors.blueGrey.shade400,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        ...items,
        if (footerButtons != null) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),
          Row(children: footerButtons),
        ],
      ],
    ),
  );

  Widget _infoRow(
    IconData icon,
    String label,
    String value, {
    bool isPhone = false,
    VoidCallback? onPhoneTap,
    Color? color,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (color ?? Colors.indigo).withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: color ?? Colors.indigo.shade400),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.blueGrey.shade500,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: color ?? const Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
        if (isPhone)
          IconButton(
            onPressed: onPhoneTap,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.teal,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.call_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
      ],
    ),
  );

  Widget _customDropdown({
    required String value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        items: items,
        onChanged: onChanged,
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: Colors.blueGrey,
        ),
      ),
    ),
  );

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 4),
    child: Text(
      t,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color(0xFF475569),
      ),
    ),
  );

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Colors.blue, width: 1.5),
    ),
  );

  Widget _buildShimmerLoader() => Shimmer.fromColors(
    baseColor: Colors.grey.shade200,
    highlightColor: Colors.white,
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const CircleAvatar(radius: 55),
          const SizedBox(height: 30),
          ...List.generate(
            3,
            (i) => Container(
              margin: const EdgeInsets.only(bottom: 20),
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  String _formatDate(String? dateStr) {
    if (dateStr == null) return "-";
    try {
      DateTime dt = DateTime.parse(dateStr);
      return DateFormat("dd.MM.yyyy").format(dt);
    } catch (e) {
      return dateStr.split("T")[0];
    }
  }

  // --- MODALLAR ---
  void _showPasswordUpdateModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => _modalContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_reset_rounded,
                  color: Colors.redAccent,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                lang == 'uz' ? "Parolni yangilash" : "Сброс пароля",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                lang == 'uz'
                    ? "Foydalanuvchi paroli 'password' so'ziga yangilanadi. Davom etasizmi?"
                    : "Пароль пользователя будет сброшен на 'password'. Продолжить?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.blueGrey.shade600,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: _smallActionBtn(
                      Icons.close_rounded,
                      lang == 'uz' ? "Yo'q" : "Нет",
                      Colors.blueGrey,
                      () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _primaryBtn(
                      onPressed: () async {
                        setModalState(() => isPasswordUpdating = true);
                        await _updatePassword();
                        if (mounted)
                          setModalState(() => isPasswordUpdating = false);
                      },
                      isLoading: isPasswordUpdating,
                      text: lang == 'uz' ? "Ha" : "Да",
                      color: Colors.redAccent,
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

  void _showPaymentModal() {
    final payFormKey = GlobalKey<FormState>();
    final amountC = TextEditingController();
    final descC = TextEditingController();
    String selectedPayType = 'cash';
    Map<String, dynamic> balance = {"cash": 0, "card": 0, "bank": 0};
    bool isDataLoading = true;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setPayState) {
          Future<void> getBalance() async {
            String? token = box.read('token');
            try {
              final res = await http.get(
                Uri.parse('${ApiConst.apiUrl}/finance'),
                headers: {'Authorization': 'Bearer $token'},
              );
              if (res.statusCode == 200) {
                final decoded = jsonDecode(res.body);
                setPayState(() {
                  balance = decoded['data'];
                  isDataLoading = false;
                });
              }
            } catch (e) {
              debugPrint(e.toString());
            }
          }

          if (isDataLoading) {
            getBalance();
            return _modalContainer(
              child: const SizedBox(
                height: 200,
                child: Center(
                  child: SpinKitFadingFour(color: Colors.teal, size: 40),
                ),
              ),
            );
          }
          return _modalContainer(
            child: Form(
              key: payFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _modalHeader(
                    lang == 'uz' ? "Ish haqi to'lash" : "Выплата зарплаты",
                  ),
                  _label(lang == 'uz' ? "To'lov turi" : "Тип оплаты"),
                  _customDropdown(
                    value: selectedPayType,
                    items: [
                      DropdownMenuItem(
                        value: 'cash',
                        child: Text(
                          "💵 ${lang == 'uz' ? 'Naqd' : 'Наличные'} (${f.format(balance['cash'])})",
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'card',
                        child: Text(
                          "💳 ${lang == 'uz' ? 'Karta' : 'Карта'} (${f.format(balance['card'])})",
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'bank',
                        child: Text(
                          "🏦 ${lang == 'uz' ? 'Bank' : 'Банк'} (${f.format(balance['bank'])})",
                        ),
                      ),
                    ],
                    onChanged: (v) => setPayState(() => selectedPayType = v!),
                  ),
                  const SizedBox(height: 16),
                  _label(lang == 'uz' ? "Summa" : "Сумма"),
                  TextFormField(
                    controller: amountC,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      ThousandSeparatorFormatter(),
                    ],
                    decoration: _inputDeco("0").copyWith(
                      suffixText: "UZS",
                      suffixStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return "!";
                      int inputVal = int.parse(v.replaceAll(RegExp(r'\D'), ''));
                      if (inputVal <= 0)
                        return lang == 'uz' ? "Xato" : "Ошибка";
                      if (inputVal > balance[selectedPayType])
                        return lang == 'uz'
                            ? "Balans yetarli emas"
                            : "Недостаточно средств";
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _label(lang == 'uz' ? "Ma'lumot" : "Описание"),
                  TextFormField(
                    controller: descC,
                    decoration: _inputDeco("..."),
                    validator: (v) => v!.isEmpty ? "!" : null,
                  ),
                  const SizedBox(height: 24),
                  _primaryBtn(
                    onPressed: () async {
                      if (payFormKey.currentState!.validate()) {
                        setPayState(() => isPaymentLoading = true);
                        await _submitPayment({
                          "amount": int.parse(
                            amountC.text.replaceAll(RegExp(r'\D'), ''),
                          ),
                          "type": selectedPayType,
                          "description": descC.text,
                          "reason": "ish_haqi",
                        });
                        if (mounted)
                          setPayState(() => isPaymentLoading = false);
                      }
                    },
                    isLoading: isPaymentLoading,
                    text: lang == 'uz' ? "TO'LOVNI TASDIQLASH" : "ПОДТВЕРДИТЬ",
                    color: Colors.teal,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showEditModal() {
    final editFormKey = GlobalKey<FormState>();
    final nameC = TextEditingController(text: userData!['name']);
    final salaryC = TextEditingController(
      text: f.format(userData!['salary_amount'] ?? 0).replaceAll(',', ' '),
    );
    final birthC = TextEditingController(
      text: userData!['birth']?.toString().split('T')[0],
    );
    String fullSeries = userData!['series'] ?? "";
    final psC = TextEditingController(
      text: fullSeries.length >= 2 ? fullSeries.substring(0, 2) : "",
    );
    final pnC = TextEditingController(
      text: fullSeries.length > 2 ? fullSeries.substring(2) : "",
    );
    final FocusNode passportNumberFocus = FocusNode();
    String rawPhone = userData!['phone']?.toString() ?? "";
    if (rawPhone.startsWith('998')) rawPhone = rawPhone.substring(3);
    final phoneFormatter = MaskTextInputFormatter(
      mask: '## ### ####',
      filter: {"#": RegExp(r'[0-9]')},
      initialText: rawPhone,
    );
    final phoneC = TextEditingController(
      text: phoneFormatter.maskText(rawPhone),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => _modalContainer(
          child: Form(
            key: editFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _modalHeader(
                  lang == 'uz'
                      ? "Ma'lumotlarni tahrirlash"
                      : "Редактирование данных",
                ),
                _label(lang == 'uz' ? "F.I.SH" : "Ф.И.О"),
                TextFormField(
                  controller: nameC,
                  decoration: _inputDeco(""),
                  validator: (v) => v!.isEmpty ? "!" : null,
                ),
                const SizedBox(height: 16),
                _label(lang == 'uz' ? "Telefon" : "Телефон"),
                TextFormField(
                  controller: phoneC,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [phoneFormatter],
                  decoration: _inputDeco("").copyWith(prefixText: "+998 "),
                ),
                const SizedBox(height: 16),
                _label(lang == 'uz' ? "Pasport" : "Паспорт"),
                Row(
                  children: [
                    SizedBox(
                      width: 75,
                      child: TextFormField(
                        controller: psC,
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(2),
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-Z]'),
                          ),
                          UpperCaseTextFormatter(),
                        ],
                        decoration: _inputDeco("AA"),
                        onChanged: (v) {
                          if (v.length == 2)
                            FocusScope.of(
                              context,
                            ).requestFocus(passportNumberFocus);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: pnC,
                        focusNode: passportNumberFocus,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(7),
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: _inputDeco("1234567"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label(lang == 'uz' ? "Ish haqi" : "Зарплата"),
                          TextFormField(
                            controller: salaryC,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              ThousandSeparatorFormatter(),
                            ],
                            decoration: _inputDeco("0"),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label(
                            lang == 'uz' ? "Tug'ilgan sana" : "Дата рождения",
                          ),
                          TextFormField(
                            controller: birthC,
                            readOnly: true,
                            decoration: _inputDeco("").copyWith(
                              suffixIcon: const Icon(
                                Icons.calendar_month_rounded,
                                color: Colors.blue,
                              ),
                            ),
                            onTap: () async {
                              DateTime? p = await showDatePicker(
                                context: context,
                                initialDate:
                                    DateTime.tryParse(birthC.text) ??
                                    DateTime(2000),
                                firstDate: DateTime(1950),
                                lastDate: DateTime.now(),
                              );
                              if (p != null)
                                setModalState(
                                  () => birthC.text = DateFormat(
                                    'yyyy-MM-dd',
                                  ).format(p),
                                );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _primaryBtn(
                  onPressed: () async {
                    if (editFormKey.currentState!.validate()) {
                      setModalState(() => isSaving = true);
                      String cleanS = salaryC.text.replaceAll(
                        RegExp(r'\D'),
                        '',
                      );
                      await _updateEmployee({
                        "name": nameC.text,
                        "phone": "998${phoneFormatter.getUnmaskedText()}",
                        "salary_amount": int.parse(cleanS),
                        "birth": birthC.text,
                        "series": "${psC.text}${pnC.text}".toUpperCase(),
                        "type": userData!['type'],
                      });
                      if (mounted) setModalState(() => isSaving = false);
                    }
                  },
                  isLoading: isSaving,
                  text: lang == 'uz' ? "SAQLASH" : "СОХРАНИТЬ",
                  color: Colors.indigo,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// FORMATTERLAR
class ThousandSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    String cleanText = newValue.text.replaceAll(RegExp(r'\D'), '');
    int? value = int.tryParse(cleanText);
    if (value == null) return oldValue;
    final f = NumberFormat("#,###", "uz_UZ");
    String newText = f.format(value).replaceAll(',', ' ');
    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
