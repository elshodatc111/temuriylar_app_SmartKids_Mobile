import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:smart_kids_app_end/const/api_const.dart';
import 'package:smart_kids_app_end/screen/kassa/kassa_pedding_payment.dart';
import 'package:smart_kids_app_end/screen/kassa/kassa_return_payment.dart';

// --- CONTROLLER ---
class KassaController extends GetxController {
  var isLoading = true.obs;
  var isSaving = false.obs;
  var processingIds = <int>[].obs; // Individual loading uchun
  var kassaData = {}.obs;

  final box = GetStorage();
  final lang = GetStorage().read('lang') ?? 'uz';

  // GetStorage'dan profile ma'lumotlarini Map ko'rinishida olish
  Map<String, dynamic> get profile => box.read('profile') ?? {};

  // Foydalanuvchi turini olish (admin/user)
  String get userType => profile['type']?.toString() ?? 'user';

  @override
  void onInit() {
    super.onInit();
    fetchKassa();
  }

  // Kassa ma'lumotlarini serverdan yuklash
  Future<void> fetchKassa() async {
    isLoading.value = true;
    String? token = box.read('token');
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConst.apiUrl}/kassa/get'),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        var decoded = jsonDecode(response.body);
        kassaData.value = decoded['data'] ?? {};
      }
    } catch (e) {
      debugPrint("Kassa API Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // Tasdiqlash yoki Bekor qilish amali
  Future<void> handleAction(int id, bool isConfirm) async {
    processingIds.add(id);
    String? token = box.read('token');
    String endpoint = isConfirm ? 'success' : 'cancel';

    try {
      final response = await http.post(
        Uri.parse('${ApiConst.apiUrl}/kassa/$endpoint/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchKassa(); // Ma'lumotlarni yangilash
        Get.snackbar(
          lang == 'uz' ? "Muvaffaqiyatli" : "Успешно",
          lang == 'uz' ? "Amal bajarildi" : "Действие выполнено",
          backgroundColor: Colors.white,
          borderColor: isConfirm ? Colors.green : Colors.red,
          borderWidth: 1,
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      Get.snackbar(lang == 'uz' ? "Xatolik" : "Ошибка", e.toString());
    } finally {
      processingIds.remove(id);
    }
  }

  // Yangi tranzaksiya qo'shish (Pending)
  Future<void> addPendingTransaction(Map<String, dynamic> data) async {
    isSaving.value = true;
    String? token = box.read('token');
    try {
      final response = await http.post(
        Uri.parse('${ApiConst.apiUrl}/kassa/pedding'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pop(Get.context!); // Modalni yopish
        fetchKassa(); // Sahifani yangilash
        Get.snackbar(
          lang == 'uz' ? "Muvaffaqiyatli" : "Успешно",
          lang == 'uz'
              ? "Amal tasdiqlash uchun yuborildi"
              : "Операция отправлена на подтверждение",
          backgroundColor: Colors.white,
          borderColor: Colors.green,
          borderWidth: 1,
        );
      }
    } catch (e) {
      Get.snackbar(
        lang == 'uz' ? "Xatolik" : "Ошибка",
        lang == 'uz' ? "Tizimda xatolik yuz berdi" : "Произошла ошибка",
      );
    } finally {
      isSaving.value = false;
    }
  }
}

class KassaPage extends StatelessWidget {
  const KassaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(KassaController());
    final f = NumberFormat("#,###", "uz_UZ");
    final lang = controller.lang;

    return Scaffold(
      appBar: AppBar(
        title: Text(lang == 'uz' ? "Kassa" : "Кассы"),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () =>
                _showAddTransactionModal(context, controller, lang),
            icon: const Icon(
              Icons.add_circle_rounded,
              color: Colors.blue,
              size: 28,
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.kassaData.isEmpty) {
          return const Center(
            child: SpinKitPulse(color: Colors.blue, size: 50),
          );
        }
        final data = controller.kassaData;
        final balance = data['balance'] ?? {"cash": 0, "card": 0, "bank": 0};
        final out =
            data['out'] ??
            {
              "total": {"cash": 0, "card": 0, "bank": 0},
              "items": {},
            };
        final cost =
            data['cost'] ??
            {
              "total": {"cash": 0, "card": 0, "bank": 0},
              "items": {},
            };
        return RefreshIndicator(
          onRefresh: () => controller.fetchKassa(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  _balanceCard(
                    "Naqd",
                    "Наличные",
                    balance['cash'],
                    Colors.green,
                    Icons.payments_outlined,
                    f,
                    lang,
                  ),
                  const SizedBox(width: 8),
                  _balanceCard(
                    "Plastik",
                    "Карта",
                    balance['card'],
                    Colors.blue,
                    Icons.credit_card_outlined,
                    f,
                    lang,
                  ),
                  const SizedBox(width: 8),
                  _balanceCard(
                    "Bank",
                    "Банк",
                    balance['bank'],
                    Colors.orange,
                    Icons.account_balance_outlined,
                    f,
                    lang,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _totalInfoCard(
                lang,
                out['total'],
                Colors.redAccent,
                f,
                lang == 'uz'
                    ? "Tasdiqlanmagan chiqimlar"
                    : "Неподтвержденный результат",
                () => _showDetails(
                  context,
                  controller,
                  'out',
                  lang == 'uz'
                      ? "Tasdiqlanmagan chiqimlar"
                      : "Неподтвержденный результат",
                ),
              ),
              const SizedBox(height: 12),
              _totalInfoCard(
                lang,
                cost['total'],
                Colors.purple,
                f,
                lang == 'uz'
                    ? "Tasdiqlanmagan xarajatlar"
                    : "Неутвержденные расходы",
                () => _showDetails(
                  context,
                  controller,
                  'cost',
                  lang == 'uz'
                      ? "Tasdiqlanmagan xarajatlar"
                      : "Неутвержденные расходы",
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: ()=>Get.to(() => KassaPendingPayment()),
                child: _clickButton(
                  lang == 'uz'
                      ? "Tasdiqlanmagan to\'lovlar"
                      : "Неподтвержденные платежи",
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: ()=>Get.to(() => KassaReturnPayment()),
                child: _clickButton(
                  lang == 'uz' ? "Qaytarilgan to\'lovlar" : "Возврат средств",
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _clickButton(String title) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF475569),
            ),
          ),
          Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
        ],
      ),
    );
  }

  void _showDetails(
    BuildContext context,
    KassaController controller,
    String key,
    String title,
  ) {
    final f = NumberFormat("#,###", "uz_UZ");
    final lang = controller.lang;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Container(
          height: Get.height * 0.5,
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: Obx(() {
                  final items = controller.kassaData[key]?['items'] ?? {};
                  if (_isItemsEmpty(items)) return _buildEmptyDetails(lang);

                  return ListView(
                    padding: const EdgeInsets.only(bottom: 30),
                    children: [
                      _buildItemSection(
                        controller,
                        lang == 'uz' ? "Naqd" : "Наличные",
                        items['cash'] ?? [],
                        Colors.green,
                        f,
                        lang,
                      ),
                      _buildItemSection(
                        controller,
                        lang == 'uz' ? "Plastik" : "Карта",
                        items['card'] ?? [],
                        Colors.blue,
                        f,
                        lang,
                      ),
                      _buildItemSection(
                        controller,
                        lang == 'uz' ? "Bank" : "Банк",
                        items['bank'] ?? [],
                        Colors.orange,
                        f,
                        lang,
                      ),
                    ],
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- YANGI TRANZAKSIYA MODALI (KEYBOARD FIX) ---
  void _showAddTransactionModal(
    BuildContext context,
    KassaController controller,
    String lang,
  ) {
    final formKey = GlobalKey<FormState>();
    final f = NumberFormat("#,###", "uz_UZ");
    String selectedType = 'cash';
    String selectedReason = 'xarajat';
    final amountC = TextEditingController();
    final descC = TextEditingController();

    double getMaxLimit() {
      final b =
          controller.kassaData['balance'] ?? {"cash": 0, "card": 0, "bank": 0};
      return double.tryParse(b[selectedType].toString()) ?? 0.0;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
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
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          lang == 'uz'
                              ? "Yangi tranzaksiya"
                              : "Новая транзакция",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _label(lang == 'uz' ? "Hisob turi" : "Тип счета"),
                        Row(
                          children: [
                            _choiceChip(
                              "cash",
                              lang == 'uz' ? "Naqd" : "Нал.",
                              selectedType,
                              (v) => setModalState(() => selectedType = v),
                            ),
                            const SizedBox(width: 8),
                            _choiceChip(
                              "card",
                              lang == 'uz' ? "Plastik" : "Карта",
                              selectedType,
                              (v) => setModalState(() => selectedType = v),
                            ),
                            const SizedBox(width: 8),
                            _choiceChip(
                              "bank",
                              lang == 'uz' ? "Bank" : "Банк",
                              selectedType,
                              (v) => setModalState(() => selectedType = v),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _label(lang == 'uz' ? "Amal turi" : "Тип операции"),
                        Row(
                          children: [
                            _choiceChip(
                              "xarajat",
                              lang == 'uz' ? "Xarajat" : "Расход",
                              selectedReason,
                              (v) => setModalState(() => selectedReason = v),
                            ),
                            const SizedBox(width: 8),
                            _choiceChip(
                              "kirim",
                              lang == 'uz' ? "Chiqim" : "Chiqim",
                              selectedReason,
                              (v) => setModalState(() => selectedReason = v),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _label(
                          "${lang == 'uz' ? 'Summa' : 'Сумма'} (Limit: ${f.format(getMaxLimit())})",
                        ),
                        TextFormField(
                          controller: amountC,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            prefixText: "UZS ",
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.all(12),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return "!";
                            final val = double.tryParse(v) ?? 0;
                            if (val > getMaxLimit())
                              return lang == 'uz'
                                  ? "Limitdan ko'p"
                                  : "Превышен лимит";
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _label(lang == 'uz' ? "Izoh" : "Описание"),
                        TextFormField(
                          controller: descC,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: lang == 'uz'
                                ? "Sababini yozing..."
                                : "Опишите причину...",
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                          validator: (v) => v!.isEmpty ? "!" : null,
                        ),
                        const SizedBox(height: 24),
                        Obx(
                          () => controller.isSaving.value
                              ? const Center(
                                  child: SpinKitThreeBounce(
                                    color: Colors.blue,
                                    size: 30,
                                  ),
                                )
                              : ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    minimumSize: const Size(
                                      double.infinity,
                                      52,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () {
                                    if (formKey.currentState!.validate())
                                      controller.addPendingTransaction({
                                        "type": selectedType,
                                        "reason": selectedReason,
                                        "amount": int.parse(amountC.text),
                                        "description": descC.text,
                                      });
                                  },
                                  child: Text(
                                    lang == 'uz' ? "SAQLASH" : "СОХРАНИТЬ",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- UI HELPERS ---
  Widget _buildItemSection(
    KassaController controller,
    String title,
    List<dynamic> list,
    Color color,
    NumberFormat f,
    String lang,
  ) {
    if (list.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 1.1,
            ),
          ),
        ),
        ...list.map((item) {
          final int id = item['id'];
          final bool isProcessing = controller.processingIds.contains(id);

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item['description'] ?? '-',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      "${f.format(item['amount'] ?? 0)} UZS",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: color,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 12,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${item['user']?['name'] ?? '-'}  •  ",
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                    const Icon(Icons.access_time, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      item['created_at']?.toString().split(' ')[0] ?? '',
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _actionBtn(
                      onTap: isProcessing
                          ? null
                          : () => controller.handleAction(id, false),
                      label: lang == 'uz' ? "Bekor qilish" : "Отмена",
                      btnColor: Colors.red.shade50,
                      textColor: Colors.red,
                      isLoading: isProcessing,
                    ),
                    const SizedBox(width: 10),
                    if (controller.userType == 'admin')
                      _actionBtn(
                        onTap: isProcessing
                            ? null
                            : () => controller.handleAction(id, true),
                        label: lang == 'uz' ? "Tasdiqlash" : "Подтвердить",
                        btnColor: Colors.green.shade50,
                        textColor: Colors.green,
                        isLoading: isProcessing,
                      ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _actionBtn({
    required VoidCallback? onTap,
    required String label,
    required Color btnColor,
    required Color textColor,
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: btnColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: isLoading
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(textColor),
                ),
              )
            : Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _balanceCard(
    String uz,
    String ru,
    dynamic v,
    Color c,
    IconData i,
    NumberFormat f,
    String l,
  ) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.withOpacity(0.12)),
        boxShadow: [BoxShadow(color: c.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Icon(i, color: c, size: 22),
          const SizedBox(height: 8),
          Text(
            l == 'uz' ? uz : ru,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            child: Text(
              f.format(v ?? 0),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _totalInfoCard(
    String l,
    dynamic t,
    Color c,
    NumberFormat f,
    String sectionTitle,
    VoidCallback onTap,
  ) {
    num total = (t['cash'] ?? 0) + (t['card'] ?? 0) + (t['bank'] ?? 0);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sectionTitle,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 16),
            _rowItem(l == 'uz' ? "Naqd" : "Наличные", t['cash'], c, f),
            _rowItem(l == 'uz' ? "Plastik" : "Карта", t['card'], c, f),
            _rowItem(l == 'uz' ? "Bank" : "Банк", t['bank'], c, f),
            const Divider(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l == 'uz' ? "Jami kutilmoqda:" : "Итого ожидается:",
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      "${f.format(total)} UZS",
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: c,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _rowItem(String l, dynamic v, Color c, NumberFormat f) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: c.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Text(l, style: const TextStyle(fontSize: 13, color: Color(0xFF334155))),
        const Spacer(),
        Text(
          f.format(v ?? 0),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    ),
  );

  Widget _choiceChip(String v, String l, String g, Function(String) s) =>
      Expanded(
        child: InkWell(
          onTap: () => s(v),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: v == g ? Colors.blue : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: v == g ? Colors.blue : Colors.grey.shade300,
              ),
            ),
            child: Text(
              l,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: v == g ? Colors.white : Colors.black87,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      t,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Color(0xFF64748B),
      ),
    ),
  );

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      t,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: Color(0xFF334155),
      ),
    ),
  );

  bool _isItemsEmpty(dynamic i) =>
      i == null ||
      ((i['cash'] as List).isEmpty &&
          (i['card'] as List).isEmpty &&
          (i['bank'] as List).isEmpty);

  Widget _buildEmptyDetails(String l) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.layers_clear_outlined,
          size: 55,
          color: Colors.grey.shade300,
        ),
        const SizedBox(height: 12),
        Text(
          l == 'uz' ? "Ma'lumotlar topilmadi" : "Данные не найдены",
          style: TextStyle(
            color: Colors.grey.shade400,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}
