import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smart_kids_app_end/const/api_const.dart';

// --- CONTROLLER ---
class MoliyaController extends GetxController {
  final box = GetStorage();
  var isLoading = true.obs;
  var isActionLoading = false.obs;
  var financeData = Rxn<Map<String, dynamic>>();

  var histories = <dynamic>[].obs;
  var isHistoryLoading = false.obs;

  String get lang => box.read('lang') ?? 'uz';

  @override
  void onInit() {
    super.onInit();
    fetchFinance();
  }

  Future<void> fetchFinance() async {
    isLoading.value = true;
    try {
      final res = await http
          .get(
            Uri.parse('${ApiConst.apiUrl}/finance'),
            headers: {
              'Authorization': 'Bearer ${box.read('token')}',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        var decoded = jsonDecode(res.body);
        financeData.value = decoded['data'];
      }
    } catch (e) {
      debugPrint("Moliya API Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchHistories() async {
    isHistoryLoading.value = true;
    try {
      final res = await http.get(
        Uri.parse('${ApiConst.apiUrl}/finance/histories'),
        headers: {
          'Authorization': 'Bearer ${box.read('token')}',
          'Accept': 'application/json',
        },
      );
      if (res.statusCode == 200) {
        var decoded = jsonDecode(res.body);
        histories.value = decoded['data'];
      }
    } catch (e) {
      debugPrint("History API Error: $e");
    } finally {
      isHistoryLoading.value = false;
    }
  }

  Future<void> updateDonationPercent(int percent) async {
    isActionLoading.value = true;
    try {
      final res = await http.post(
        Uri.parse('${ApiConst.apiUrl}/finance/donation-update'),
        headers: {
          'Authorization': 'Bearer ${box.read('token')}',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({"donation_percent": percent}),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        Get.back();
        fetchFinance();
        _showSuccess(
          lang == 'uz'
              ? "Ehson foizi yangilandi"
              : "Процент пожертвований обновлен",
        );
      }
    } finally {
      isActionLoading.value = false;
    }
  }

  Future<void> submitOutput(Map<String, dynamic> data) async {
    isActionLoading.value = true;
    try {
      final res = await http.post(
        Uri.parse('${ApiConst.apiUrl}/finance/output'),
        headers: {
          'Authorization': 'Bearer ${box.read('token')}',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        Get.back();
        fetchFinance();
        _showSuccess(
          lang == 'uz'
              ? "Chiqim muvaffaqiyatli bajarildi"
              : "Расход успешно выполнен",
        );
      }
    } finally {
      isActionLoading.value = false;
    }
  }

  void _showSuccess(String msg) {
    Get.snackbar(
      lang == 'uz' ? "Muvaffaqiyatli" : "Успешно",
      msg,
      backgroundColor: Colors.white,
      colorText: Colors.black87,
      borderColor: Colors.green,
      borderWidth: 0.5,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(15),
    );
  }
}

// --- VIEW (PAGE) ---
class MoliyaPage extends StatelessWidget {
  const MoliyaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(MoliyaController());
    final f = NumberFormat("#,###", "uz_UZ");

    return Scaffold(
      appBar: AppBar(
        title: Text(c.lang == 'uz' ? "Moliya" : "Финансы"),
        actions: [
          IconButton(
            onPressed: c.fetchFinance,
            icon: const Icon(Icons.sync_rounded, color: Colors.blue),
          ),
        ],
      ),
      body: Obx(
        () => c.isLoading.value
            ? _buildShimmerLoader()
            : _buildFinanceBody(context, c, f),
      ),
    );
  }

  Widget _buildFinanceBody(
    BuildContext context,
    MoliyaController c,
    NumberFormat f,
  ) {
    final data = c.financeData.value;
    if (data == null) return const Center(child: Text("Data not found"));

    return RefreshIndicator(
      onRefresh: c.fetchFinance,
      color: Colors.blue,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _infoCard(
              title: c.lang == 'uz'
                  ? "Mavjud mablag'lar"
                  : "Доступные средства",
              items: [
                _infoRow(
                  Icons.payments_rounded,
                  c.lang == 'uz' ? "Naqd pul" : "Наличные",
                  "${f.format(data['cash'])} UZS",
                  color: Colors.green,
                ),
                _infoRow(
                  Icons.credit_card_rounded,
                  c.lang == 'uz' ? "Plastik karta" : "Пластиковая карта",
                  "${f.format(data['card'])} UZS",
                  color: Colors.blue,
                ),
                _infoRow(
                  Icons.account_balance_rounded,
                  c.lang == 'uz' ? "Bank hisobi" : "Банковский счет",
                  "${f.format(data['bank'])} UZS",
                  color: Colors.indigo,
                ),
              ],
            ),

            _infoCard(
              title: c.lang == 'uz'
                  ? "Amallar va Ehson"
                  : "Операции и Пожертвования",
              footerButtons: [
                _smallActionBtn(
                  Icons.auto_graph_rounded,
                  c.lang == 'uz' ? "Ehson %" : "Процент %",
                  Colors.orange,
                  () => _showDonationModal(context, c),
                ),
                const SizedBox(width: 10),
                _smallActionBtn(
                  Icons.outbox_rounded,
                  c.lang == 'uz' ? "Chiqim" : "Расход",
                  Colors.redAccent,
                  () => _showOutputModal(context, c, f),
                ),
                const SizedBox(width: 10),
                _smallActionBtn(
                  Icons.history_rounded,
                  c.lang == 'uz' ? "Tarix" : "История",
                  Colors.blueGrey,
                  () {
                    c.fetchHistories();
                    _showHistoryModal(context, c, f);
                  },
                ),
              ],
              items: [_donationRow(data, f, c)],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showHistoryModal(
    BuildContext context,
    MoliyaController c,
    NumberFormat f,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                c.lang == 'uz' ? "Balans tarixi" : "История баланса",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Divider(),
            Expanded(
              child: Obx(() {
                if (c.isHistoryLoading.value)
                  return const Center(
                    child: SpinKitFadingFour(color: Colors.blueGrey, size: 40),
                  );
                if (c.histories.isEmpty)
                  return Center(
                    child: Text(
                      c.lang == 'uz' ? "Tarix mavjud emas" : "История пуста",
                    ),
                  );

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: c.histories.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final h = c.histories[index];
                    bool isIncome =
                        h['reason'] == 'kirim' || h['reason'] == 'daromad';
                    Color statusColor = isIncome
                        ? Colors.green
                        : Colors.redAccent;

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isIncome
                                      ? Icons.south_west_rounded
                                      : Icons.north_east_rounded,
                                  color: statusColor,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${h['reason'].toString().toUpperCase()} - ${h['type'].toString().toUpperCase()}",
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.blueGrey,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "${f.format(h['amount'])} UZS",
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w900,
                                        color: statusColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (h['donation'] > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "${c.lang == 'uz' ? 'Ehson' : 'Пожертвование'}: ${f.format(h['donation'])}",
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                          ),

                          Row(
                            children: [
                              Expanded(
                                child: _auditItem(
                                  context,
                                  c.lang == 'uz' ? "Menejer:" : "Менеджер:",
                                  "${h['user']['name']}",
                                  "${h['start_at']}",
                                  Icons.person_outline_rounded,
                                ),
                              ),
                              Container(
                                height: 30,
                                width: 1,
                                color: Colors.grey.shade200,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                              ),
                              Expanded(
                                child: _auditItem(
                                  context,
                                  c.lang == 'uz' ? "Tasdiqladi:" : "Одобрил:",
                                  "${h['admin']['name']}",
                                  "${h['end_at']}",
                                  Icons.verified_user_outlined,
                                ),
                              ),
                            ],
                          ),

                          if (h['description'] != null &&
                              h['description'].toString().isNotEmpty)
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(top: 12),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFFEDF2F7),
                                ),
                              ),
                              child: Text(
                                h['description'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blueGrey.shade700,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _auditItem(
    BuildContext context,
    String role,
    String name,
    String date,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          role,
          style: TextStyle(
            fontSize: 9,
            color: Colors.blueGrey.shade400,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(icon, size: 12, color: Colors.indigo.shade300),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF475569),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        Text(date, style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
      ],
    );
  }

  void _showOutputModal(
    BuildContext context,
    MoliyaController c,
    NumberFormat f,
  ) {
    final formKey = GlobalKey<FormState>();
    final amountC = TextEditingController();
    final descC = TextEditingController();
    String selectedType = 'cash';
    String selectedReason = 'xarajat';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
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
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  c.lang == 'uz'
                      ? "Balansdan chiqim qilish"
                      : "Расход из баланса",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 20),
                _label(c.lang == 'uz' ? "Chiqim turi" : "Тип расхода"),
                _customDropdown(
                  value: selectedType,
                  items: [
                    DropdownMenuItem(
                      value: 'cash',
                      child: Text(c.lang == 'uz' ? "Naqd pul" : "Наличные"),
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
                      value: 'donation',
                      child: Text(c.lang == 'uz' ? "Ehson" : "Пожертвование"),
                    ),
                  ],
                  onChanged: (v) {
                    setModalState(() {
                      selectedType = v!;
                      selectedReason = selectedType == 'donation'
                          ? 'exson'
                          : 'xarajat';
                    });
                  },
                ),
                const SizedBox(height: 16),
                _label(c.lang == 'uz' ? "Chiqim sababi" : "Причина расхода"),
                _customDropdown(
                  value: selectedReason,
                  items: selectedType == 'donation'
                      ? [
                          DropdownMenuItem(
                            value: 'exson',
                            child: Text(
                              c.lang == 'uz' ? "Ehson" : "Пожертвование",
                            ),
                          ),
                        ]
                      : [
                          DropdownMenuItem(
                            value: 'xarajat',
                            child: Text(c.lang == 'uz' ? "Xarajat" : "Расход"),
                          ),
                          DropdownMenuItem(
                            value: 'daromad',
                            child: Text(c.lang == 'uz' ? "Daromad" : "Доход"),
                          ),
                        ],
                  onChanged: (v) => setModalState(() => selectedReason = v!),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _label(c.lang == 'uz' ? "Summa" : "Сумма"),
                    Text(
                      "${c.lang == 'uz' ? 'Maksimal:' : 'Макс:'} ${f.format(c.financeData.value?[selectedType] ?? 0)}",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                      ),
                    ),
                  ],
                ),
                TextFormField(
                  controller: amountC,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    ThousandSeparatorFormatter(),
                  ],
                  decoration: _inputDeco("0").copyWith(suffixText: "UZS"),
                  validator: (v) {
                    if (v == null || v.isEmpty) return "!";
                    int amount = int.parse(v.replaceAll(RegExp(r'\D'), ''));
                    int max = c.financeData.value?[selectedType] ?? 0;
                    if (amount <= 0) return "!";
                    if (amount > max)
                      return c.lang == 'uz'
                          ? "Mablag' yetarli emas"
                          : "Недостаточно средств";
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _label(c.lang == 'uz' ? "Izoh" : "Комментарий"),
                TextFormField(
                  controller: descC,
                  maxLines: 2,
                  decoration: _inputDeco("..."),
                  validator: (v) => (v == null || v.isEmpty) ? "!" : null,
                ),
                const SizedBox(height: 24),
                Obx(
                  () => _primaryBtn(
                    onPressed: () {
                      if (formKey.currentState!.validate())
                        c.submitOutput({
                          "type": selectedType,
                          "reason": selectedReason,
                          "amount": int.parse(
                            amountC.text.replaceAll(RegExp(r'\D'), ''),
                          ),
                          "description": descC.text,
                        });
                    },
                    isLoading: c.isActionLoading.value,
                    text: c.lang == 'uz' ? "CHIQIM QILISH" : "ВЫПОЛНИТЬ РАСХОД",
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDonationModal(BuildContext context, MoliyaController c) {
    final formKey = GlobalKey<FormState>();
    final percentC = TextEditingController(
      text: c.financeData.value?['donation_foiz'].toString(),
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
        child: Form(
          key: formKey,
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
              const SizedBox(height: 25),
              Text(
                c.lang == 'uz'
                    ? "Ehson foizini tahrirlash"
                    : "Редактировать процент",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 25),
              TextFormField(
                controller: percentC,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                decoration: _inputDeco(
                  "0-100",
                ).copyWith(prefixIcon: const Icon(Icons.percent_rounded)),
                validator: (v) {
                  int? val = int.tryParse(v ?? '');
                  return (val == null || val < 0 || val > 100) ? "0-100" : null;
                },
              ),
              const SizedBox(height: 30),
              Obx(
                () => _primaryBtn(
                  onPressed: () {
                    if (formKey.currentState!.validate())
                      c.updateDonationPercent(int.parse(percentC.text));
                  },
                  isLoading: c.isActionLoading.value,
                  text: c.lang == 'uz' ? "SAQLASH" : "СОХРАНИТЬ",
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _donationRow(
    Map<String, dynamic> data,
    NumberFormat f,
    MoliyaController c,
  ) {
    return Row(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 55,
              width: 55,
              child: CircularProgressIndicator(
                value: (data['donation_foiz'] as num).toDouble() / 100,
                backgroundColor: Colors.teal.withOpacity(0.1),
                color: Colors.teal,
                strokeWidth: 6,
                strokeCap: StrokeCap.round,
              ),
            ),
            Text(
              "${data['donation_foiz']}%",
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Colors.teal,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                c.lang == 'uz' ? "Yig'ilgan ehson" : "Собрано пожертвований",
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "${f.format(data['donation'])} UZS",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- REUSABLE UI WIDGETS ---
  Widget _infoCard({
    required String title,
    required List<Widget> items,
    List<Widget>? footerButtons,
  }) {
    return Container(
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
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Colors.blueGrey,
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
  }

  Widget _infoRow(IconData icon, String label, String value, {Color? color}) {
    return Padding(
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
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.blueGrey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallActionBtn(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: Material(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 6),
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
  }

  Widget _primaryBtn({
    required VoidCallback onPressed,
    required bool isLoading,
    required String text,
    required Color color,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
  }

  Widget _customDropdown({
    required String value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
  }) {
    return Container(
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
  }

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
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ],
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
}

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
