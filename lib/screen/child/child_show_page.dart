import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smart_kids_app_end/screen/child/child_davomad_history_page.dart';
import 'package:smart_kids_app_end/screen/child/child_history_page.dart';
import 'package:smart_kids_app_end/screen/child/child_update_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:smart_kids_app_end/const/api_const.dart';

// --- CONTROLLER ---
class ChildShowController extends GetxController {
  final int id;

  ChildShowController({required this.id});

  final box = GetStorage();
  var isLoading = true.obs;
  var isUploading = false.obs;
  var isPaymentLoading = false.obs;
  var kidData = Rxn<Map<String, dynamic>>();

  var kassaBalance = Rxn<Map<String, dynamic>>();
  var isKassaLoading = false.obs;

  String get lang => box.read('lang') ?? 'uz';

  @override
  void onInit() {
    super.onInit();
    fetchKidInfo();
  }

  Future<void> onRefresh() async => await fetchKidInfo();

  Future<void> fetchKidInfo() async {
    isLoading.value = true;
    try {
      final res = await http
          .get(
            Uri.parse('${ApiConst.apiUrl}/kids/show/$id'),
            headers: {
              'Authorization': 'Bearer ${box.read('token')}',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        var decoded = jsonDecode(res.body);
        kidData.value = decoded['kid'];
      }
    } catch (e) {
      debugPrint("Kid Show Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchKassaBalance() async {
    isKassaLoading.value = true;
    try {
      final res = await http.get(
        Uri.parse('${ApiConst.apiUrl}/kassa/get'),
        headers: {
          'Authorization': 'Bearer ${box.read('token')}',
          'Accept': 'application/json',
        },
      );
      if (res.statusCode == 200) {
        var decoded = jsonDecode(res.body);
        kassaBalance.value = decoded['data']['balance'];
      }
    } catch (e) {
      debugPrint("Kassa API Error: $e");
    } finally {
      isKassaLoading.value = false;
    }
  }

  Future<void> submitPayment(Map<String, dynamic> data) async {
    isPaymentLoading.value = true;
    try {
      final res = await http.post(
        Uri.parse('${ApiConst.apiUrl}/kids/create/paymart/$id'),
        headers: {
          'Authorization': 'Bearer ${box.read('token')}',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        FocusScope.of(Get.context!).unfocus();
        Navigator.of(Get.context!, rootNavigator: true).pop();
        await Future.delayed(const Duration(milliseconds: 300));
        await fetchKidInfo();
        _showSnack(
          lang == 'uz' ? "Muvaffaqiyatli" : "Успешно",
          lang == 'uz' ? "To'lov qabul qilindi" : "Платеж принят",
          Colors.green,
        );
      }
    } catch (e) {
      Get.snackbar("Xato", "Tizim xatosi: $e");
    } finally {
      isPaymentLoading.value = false;
    }
  }

  Future<void> uploadPhoto(File imageFile, String uploadType) async {
    isUploading.value = true;
    String path = (uploadType == 'profile')
        ? '/kids/create/photo/$id'
        : (uploadType == 'document')
        ? '/kids/create/document/$id'
        : (uploadType == 'passport')
        ? '/kids/create/passport/$id'
        : '/kids/create/certificate/$id';

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConst.apiUrl}$path'),
      );
      request.headers.addAll({
        'Authorization': 'Bearer ${box.read('token')}',
        'Accept': 'application/json',
      });
      request.files.add(
        await http.MultipartFile.fromPath('photo', imageFile.path),
      );
      var response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.of(Get.context!, rootNavigator: true).pop();
        await Future.delayed(const Duration(milliseconds: 300));
        await fetchKidInfo();
        _showSnack(
          lang == 'uz' ? "Muvaffaqiyatli" : "Успешно",
          lang == 'uz' ? "Ma'lumot yangilandi" : "Данные обновлены",
          Colors.green,
        );
      }
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isUploading.value = false;
    }
  }

  void _showSnack(String title, String msg, Color color) {
    Get.snackbar(
      title,
      msg,
      backgroundColor: color,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
    );
  }

  Future<void> makeCall(String phone) async {
    final Uri uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}

// --- VIEW ---
class ChildShowPage extends StatelessWidget {
  final int id;

  const ChildShowPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(ChildShowController(id: id));
    final f = NumberFormat("#,###", "uz_UZ");

    return Scaffold(
      appBar: AppBar(
        title: Text("  "),
        actions: [
          IconButton(
            onPressed: () async {
              var result = await Get.to(() => ChildUpdatePage(id: id));
              if (result == true) {
                await c.fetchKidInfo();
              }
            },
            icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
          ),
        ],
      ),
      body: Obx(
        () => c.isLoading.value
            ? _buildShimmerLoader()
            : RefreshIndicator(
                onRefresh: c.onRefresh,
                color: Colors.blue,
                child: _buildBody(context, c, f),
              ),
      ),
    );
  }

  // --- KESHNI ALDASH UCHUN FUNKSIYA (CACHE BUSTING) ---
  String _getFreshUrl(String? url) {
    if (url == null || url.isEmpty) return "";
    return "$url?v=${DateTime.now().millisecondsSinceEpoch}";
  }

  Widget _buildBody(
    BuildContext context,
    ChildShowController c,
    NumberFormat f,
  ) {
    final kid = c.kidData.value;
    if (kid == null) return const Center(child: Text("Ma'lumot topilmadi"));

    bool isActive = kid['is_active'] == true;
    double balance = (kid['balance'] as num).toDouble();

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          _buildHeader(context, c, kid, isActive),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _infoCard(
                  title: c.lang == 'uz'
                      ? "Umumiy ma'lumotlar"
                      : "Общая информация",
                  items: [
                    _infoRow(
                      Icons.account_balance_wallet_rounded,
                      c.lang == 'uz' ? "Joriy balans" : "Текущий баланс",
                      "${f.format(balance)} UZS",
                      color: balance < 0 ? Colors.redAccent : Colors.teal,
                    ),
                    const Divider(
                      height: 1,
                      indent: 45,
                      color: Color(0xFFF1F5F9),
                    ),
                    _infoRow(
                      Icons.cake_rounded,
                      c.lang == 'uz' ? "Tug'ilgan sana" : "Дата рождения",
                      _formatDate(kid['birth_date']),
                    ),
                    _infoRow(
                      Icons.fingerprint_rounded,
                      c.lang == 'uz' ? "Hujjat seriyasi" : "Серия документа",
                      kid['document_series'] ?? '-',
                    ),
                    _infoRow(
                      Icons.location_on_rounded,
                      c.lang == 'uz' ? "Manzil" : "Адрес",
                      kid['address'] ?? '-',
                    ),
                    const Divider(
                      height: 1,
                      indent: 45,
                      color: Color(0xFFF1F5F9),
                    ),
                    _infoRow(
                      Icons.person_pin_rounded,
                      c.lang == 'uz' ? "Vasiy (F.I.SH)" : "Опекун (Ф.И.О)",
                      kid['guardian_name'] ?? '-',
                    ),
                    _infoRow(
                      Icons.phone_iphone_rounded,
                      c.lang == 'uz' ? "Telefon" : "Телефон",
                      kid['guardian_phone'] ?? '-',
                      isPhone: true,
                      onPhoneTap: () => c.makeCall(kid['guardian_phone']),
                    ),
                    if (kid['biography'] != null &&
                        kid['biography'].toString().isNotEmpty) ...[
                      const Divider(
                        height: 1,
                        indent: 45,
                        color: Color(0xFFF1F5F9),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 12, left: 45),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.lang == 'uz'
                                  ? "Qo'shimcha izoh:"
                                  : "Дополнительный комментарий:",
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.blueGrey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              kid['biography'],
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF475569),
                                height: 1.4,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _quickActionBtn(
                      Icons.payments_rounded,
                      c.lang == 'uz' ? "To'lov" : "Оплата",
                      Colors.teal,
                      () => _showPaymentModal(context, c, f),
                    ),
                    const SizedBox(width: 10),
                    _quickActionBtn(
                      Icons.event_note_rounded,
                      c.lang == 'uz' ? "Davomat" : "Посещаемость",
                      Colors.orange,
                      () => Get.to(() => ChildDavomadHistoryPage(id: id)),
                    ),
                    const SizedBox(width: 10),
                    _quickActionBtn(
                      Icons.history_rounded,
                      c.lang == 'uz' ? "Tarix" : "История",
                      Colors.blueGrey,
                      () => Get.to(() => ChildHistoryPage(id: id)),
                    ),
                  ],
                ),
                _infoCard(
                  title: c.lang == 'uz'
                      ? "Hujjatlar va Rasmlar"
                      : "Документы и Фото",
                  items: [
                    _buildDocumentGallery(context, kid, c),
                    const SizedBox(height: 16),
                    _actionButton(
                      Icons.assignment_ind_rounded,
                      c.lang == 'uz'
                          ? "Guvohnomani yangilash"
                          : "Обновить свидетельство",
                      Colors.indigo,
                      () => _showPickerModal(context, c, 'document'),
                    ),
                    _actionButton(
                      Icons.badge_rounded,
                      c.lang == 'uz'
                          ? "Vasiy pasportini yangilash"
                          : "Обновить паспорт опекуна",
                      Colors.blue,
                      () => _showPickerModal(context, c, 'passport'),
                    ),
                    _actionButton(
                      Icons.medical_services_rounded,
                      c.lang == 'uz'
                          ? "Tibbiy varaqni yangilash"
                          : "Обновить мед. карту",
                      Colors.teal,
                      () => _showPickerModal(context, c, 'certificate'),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentModal(
    BuildContext context,
    ChildShowController c,
    NumberFormat f,
  ) {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final descController = TextEditingController();
    String selectedType = 'cash';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        c.lang == 'uz' ? "To'lov qilish" : "Произвести оплату",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _label(c.lang == 'uz' ? "To'lov turi" : "Тип оплаты"),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedType,
                            isExpanded: true,
                            items: [
                              DropdownMenuItem(
                                value: 'cash',
                                child: Text(
                                  c.lang == 'uz' ? "Naqd pul" : "Наличные",
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'card',
                                child: Text(c.lang == 'uz' ? "Karta" : "Карта"),
                              ),
                              DropdownMenuItem(
                                value: 'bank',
                                child: Text(c.lang == 'uz' ? "Bank" : "Банк"),
                              ),
                              DropdownMenuItem(
                                value: 'discount',
                                child: Text(
                                  c.lang == 'uz' ? "Chegirma" : "Скидка",
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'return_cash',
                                child: Text(
                                  c.lang == 'uz'
                                      ? "Qaytarish (Naqd)"
                                      : "Возврат (Наличные)",
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'return_card',
                                child: Text(
                                  c.lang == 'uz'
                                      ? "Qaytarish (Karta)"
                                      : "Возврат (Карта)",
                                ),
                              ),
                            ],
                            onChanged: (v) {
                              setState(() => selectedType = v!);
                              if (v!.startsWith('return'))
                                c.fetchKassaBalance();
                            },
                          ),
                        ),
                      ),
                      if (selectedType.startsWith('return'))
                        Obx(
                          () => Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: c.isKassaLoading.value
                                ? const LinearProgressIndicator()
                                : Text(
                                    "${c.lang == 'uz' ? 'Kassada mavjud:' : 'В кассе:'} ${f.format(c.kassaBalance.value?[selectedType == 'return_cash' ? 'cash' : 'card'] ?? 0)} UZS",
                                    style: const TextStyle(
                                      color: Colors.blueGrey,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      _label(c.lang == 'uz' ? "Summa" : "Сумма"),
                      TextFormField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: _inputDecoration("0 UZS"),
                        validator: (v) {
                          if (v == null || v.isEmpty)
                            return c.lang == 'uz'
                                ? "Summani kiriting"
                                : "Введите сумму";
                          int val = int.parse(v);
                          if (val < 500)
                            return c.lang == 'uz'
                                ? "Minimal 500"
                                : "Минимум 500";
                          if (selectedType.startsWith('return')) {
                            int available =
                                c.kassaBalance.value?[selectedType ==
                                        'return_cash'
                                    ? 'cash'
                                    : 'card'] ??
                                0;
                            if (val > available)
                              return c.lang == 'uz'
                                  ? "Kassada mablag' yetarli emas"
                                  : "Недостаточно средств";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _label(c.lang == 'uz' ? "Izoh" : "Комментарий"),
                      TextFormField(
                        controller: descController,
                        maxLines: 2,
                        decoration: _inputDecoration(
                          c.lang == 'uz'
                              ? "Izoh yozing..."
                              : "Напишите комментарий...",
                        ),
                      ),
                      const SizedBox(height: 24),
                      Obx(
                        () => SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            onPressed: c.isPaymentLoading.value
                                ? null
                                : () {
                                    if (formKey.currentState!.validate()) {
                                      c.submitPayment({
                                        "payment_type": selectedType,
                                        "amount": int.parse(
                                          amountController.text,
                                        ),
                                        "description": descController.text,
                                      });
                                    }
                                  },
                            child: c.isPaymentLoading.value
                                ? const SpinKitThreeBounce(
                                    color: Colors.white,
                                    size: 20,
                                  )
                                : Text(
                                    c.lang == 'uz'
                                        ? "TO'LOV QILISH"
                                        : "ОПЛАТИТЬ",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ChildShowController c,
    Map kid,
    bool isActive,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: const Color(0xFFF1F5F9),
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: _getFreshUrl(kid['photo_path']),
                    placeholder: (context, url) =>
                        const SpinKitPulse(color: Colors.blue, size: 25),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.child_care_rounded,
                      size: 40,
                      color: Colors.blueGrey,
                    ),
                    fit: BoxFit.cover,
                    width: 96,
                    height: 96,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _showPickerModal(context, c, 'profile'),
                child: Container(
                  height: 30,
                  width: 30,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            kid['full_name'] ?? "-",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.teal.withOpacity(0.08)
                  : Colors.red.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isActive
                  ? (c.lang == 'uz' ? "FAOL" : "АКТИВЕН")
                  : (c.lang == 'uz' ? "NOFAOL" : "НЕАКТИВЕН"),
              style: TextStyle(
                color: isActive ? Colors.teal : Colors.red,
                fontWeight: FontWeight.w900,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPickerModal(
    BuildContext context,
    ChildShowController c,
    String type,
  ) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 35,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              c.lang == 'uz' ? "Manbani tanlang" : "Выберите источник",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _pickerItem(
                  Icons.camera_alt,
                  c.lang == 'uz' ? "Kamera" : "Камера",
                  () => _handleImageAction(c, ImageSource.camera, type),
                ),
                _pickerItem(
                  Icons.image,
                  c.lang == 'uz' ? "Galereya" : "Галерея",
                  () => _handleImageAction(c, ImageSource.gallery, type),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _handleImageAction(
    ChildShowController c,
    ImageSource source,
    String type,
  ) async {
    if (Get.isBottomSheetOpen ?? false) Get.back();
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: type == 'profile'
            ? const CropAspectRatio(ratioX: 1, ratioY: 1)
            : const CropAspectRatio(ratioX: 16, ratioY: 9),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: c.lang == 'uz' ? 'Rasmni kesish' : 'Обрезка фото',
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: c.lang == 'uz' ? 'Rasmni kesish' : 'Обрезка фото',
          ),
        ],
      );
      if (croppedFile != null)
        _showConfirmModal(c, File(croppedFile.path), type);
    }
  }

  void _showConfirmModal(ChildShowController c, File file, String type) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              c.lang == 'uz' ? "Rasmni saqlaymizmi?" : "Сохранить фото?",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                file,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    child: Text(c.lang == 'uz' ? "Bekor qilish" : "Отмена"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Obx(
                    () => ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                      onPressed: c.isUploading.value
                          ? null
                          : () => c.uploadPhoto(file, type),
                      child: c.isUploading.value
                          ? const SpinKitThreeBounce(
                              color: Colors.white,
                              size: 18,
                            )
                          : Text(
                              c.lang == 'uz' ? "SAQLASH" : "СОХРАНИТЬ",
                              style: const TextStyle(color: Colors.white),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      isDismissible: false,
    );
  }

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      t,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Color(0xFF475569),
      ),
    ),
  );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
  );

  Widget _quickActionBtn(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) => Expanded(
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _infoCard({required String title, required List<Widget> items}) =>
      Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: Colors.blueGrey,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 12),
            ...items,
          ],
        ),
      );

  Widget _infoRow(
    IconData icon,
    String label,
    String value, {
    Color? color,
    bool isPhone = false,
    VoidCallback? onPhoneTap,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (color ?? Colors.indigo).withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: color ?? Colors.indigo.shade400),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.blueGrey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
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
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.teal,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.call, color: Colors.white, size: 14),
            ),
          ),
      ],
    ),
  );

  Widget _actionButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Material(
      color: color.withOpacity(0.06),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.grey,
                size: 12,
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _buildDocumentGallery(
    BuildContext context,
    Map kid,
    ChildShowController c,
  ) {
    final docs = [
      {
        'title': c.lang == 'uz' ? 'Guvohnoma' : 'Свидетельство',
        'path': kid['document_photo_path'],
      },
      {
        'title': c.lang == 'uz' ? 'Pasport' : 'Паспорт',
        'path': kid['guardian_passport_path'],
      },
      {
        'title': c.lang == 'uz' ? 'Tibbiy' : 'Мед. карта',
        'path': kid['health_certificate_path'],
      },
    ];
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: docs.length,
        itemBuilder: (context, index) => GestureDetector(
          onTap: () => _showImageDialog(
            context,
            docs[index]['path'] ?? "",
            docs[index]['title'] ?? "",
          ),
          child: Container(
            width: 140,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: _getFreshUrl(docs[index]['path']),
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.image_not_supported_rounded),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Colors.black45],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 6,
                    left: 8,
                    child: Text(
                      docs[index]['title'] ?? "",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showImageDialog(BuildContext context, String url, String title) =>
      Get.dialog(
        Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                leading: IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: _getFreshUrl(url),
                  placeholder: (context, url) =>
                      const SpinKitFadingCircle(color: Colors.white),
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      );

  String _formatDate(String? s) {
    if (s == null) return "-";
    try {
      return DateFormat("dd.MM.yyyy").format(DateTime.parse(s));
    } catch (e) {
      return s.split("T")[0];
    }
  }

  Widget _pickerItem(IconData icon, String label, VoidCallback onTap) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.blue, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      );

  Widget _buildShimmerLoader() => Shimmer.fromColors(
    baseColor: Colors.grey.shade200,
    highlightColor: Colors.white,
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const CircleAvatar(radius: 48),
          const SizedBox(height: 20),
          ...List.generate(
            3,
            (i) => Container(
              margin: const EdgeInsets.only(bottom: 16),
              height: 100,
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
}
