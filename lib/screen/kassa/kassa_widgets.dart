import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:smart_kids_app_end/screen/kassa/kassa_page.dart';

class KassaWidgets {
  // 1. Sarlavha vidjeti
  static Widget sectionTitle(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(t, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF334155)))
  );

  // 2. Balans kartochkasi
  static Widget balanceCard(String uz, String ru, dynamic v, Color c, IconData i, NumberFormat f, String l) => Expanded(
      child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.withOpacity(0.12)),
              boxShadow: [BoxShadow(color: c.withOpacity(0.05), blurRadius: 10)]
          ),
          child: Column(
              children: [
                Icon(i, color: c, size: 22),
                const SizedBox(height: 8),
                Text(l == 'uz' ? uz : ru, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                FittedBox(child: Text(f.format(v ?? 0), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF1E293B))))
              ]
          )
      )
  );

  // 3. Jami ma'lumot kartasi
  static Widget totalInfoCard(String l, dynamic t, Color c, NumberFormat f, String sectionTitle, VoidCallback onTap) {
    num total = (t['cash'] ?? 0) + (t['card'] ?? 0) + (t['bank'] ?? 0);
    return InkWell(
        onTap: onTap, borderRadius: BorderRadius.circular(16),
        child: Container(
            padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10)]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(sectionTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
              const SizedBox(height: 16),
              _rowItem(l == 'uz' ? "Naqd" : "Наличные", t['cash'], c, f),
              _rowItem(l == 'uz' ? "Plastik" : "Карта", t['card'], c, f),
              _rowItem(l == 'uz' ? "Bank" : "Банк", t['bank'], c, f),
              const Divider(height: 28),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(l == 'uz' ? "Jami kutilmoqda:" : "Итого ожидается:", style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                Row(children: [Text("${f.format(total)} UZS", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: c)), const SizedBox(width: 4), const Icon(Icons.chevron_right, size: 18, color: Colors.grey)])
              ])
            ])
        )
    );
  }

  static Widget _rowItem(String l, dynamic v, Color c, NumberFormat f) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [Container(width: 6, height: 6, decoration: BoxDecoration(color: c.withOpacity(0.5), shape: BoxShape.circle)), const SizedBox(width: 10), Text(l, style: const TextStyle(fontSize: 13, color: Color(0xFF334155))), const Spacer(), Text(f.format(v ?? 0), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))])
  );

  // 4. Detallar modali
  static void showDetailsModal(BuildContext context, KassaController controller, String key, String title) {
    final f = NumberFormat("#,###", "uz_UZ");
    final lang = controller.lang;

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
        builder: (context) {
          return Container(
            height: Get.height * 0.8,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10))),
                Padding(padding: const EdgeInsets.all(20), child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                Expanded(
                  child: Obx(() {
                    final items = controller.kassaData[key]?['items'] ?? {};
                    if (items.isEmpty || (items['cash'] as List).isEmpty && (items['card'] as List).isEmpty && (items['bank'] as List).isEmpty) {
                      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.layers_clear_outlined, size: 55, color: Colors.grey.shade300), const SizedBox(height: 12), Text(lang == 'uz' ? "Ma'lumotlar topilmadi" : "Данные не найдены", style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w500))]));
                    }
                    return ListView(
                      padding: const EdgeInsets.only(bottom: 30),
                      children: [
                        _buildItemSection(controller, lang == 'uz' ? "Naqd" : "Наличные", items['cash'] ?? [], Colors.green, f, lang),
                        _buildItemSection(controller, lang == 'uz' ? "Plastik" : "Карта", items['card'] ?? [], Colors.blue, f, lang),
                        _buildItemSection(controller, lang == 'uz' ? "Bank" : "Банк", items['bank'] ?? [], Colors.orange, f, lang),
                      ],
                    );
                  }),
                ),
              ],
            ),
          );
        }
    );
  }

  static Widget _buildItemSection(KassaController controller, String title, List<dynamic> list, Color color, NumberFormat f, String lang) {
    if (list.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 8), child: Text(title.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.1))),
        ...list.map((item) {
          final int id = item['id'];
          final bool isProcessing = controller.processingIds.contains(id);
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade100), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Text(item['description'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))), Text("${f.format(item['amount'] ?? 0)} UZS", style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 14))]),
                const SizedBox(height: 6),
                Row(children: [const Icon(Icons.person_outline, size: 12, color: Colors.grey), const SizedBox(width: 4), Text("${item['user']?['name'] ?? '-'}  •  ", style: const TextStyle(color: Colors.grey, fontSize: 11)), const Icon(Icons.access_time, size: 12, color: Colors.grey), const SizedBox(width: 4), Text(item['created_at']?.toString().split(' ')[0] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 11))]),
                const Divider(height: 24),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  _actionBtn(onTap: isProcessing ? null : () => controller.handleAction(id, false), label: lang == 'uz' ? "Bekor qilish" : "Отмена", btnColor: Colors.red.shade50, textColor: Colors.red, isLoading: isProcessing),
                  const SizedBox(width: 10),
                  if (controller.userType == 'admin')
                    _actionBtn(onTap: isProcessing ? null : () => controller.handleAction(id, true), label: lang == 'uz' ? "Tasdiqlash" : "Подтвердить", btnColor: Colors.green.shade50, textColor: Colors.green, isLoading: isProcessing),
                ])
              ],
            ),
          );
        }),
      ],
    );
  }

  static Widget _actionBtn({required VoidCallback? onTap, required String label, required Color btnColor, required Color textColor, bool isLoading = false}) {
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: btnColor, borderRadius: BorderRadius.circular(8)),
        child: isLoading ? SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(textColor)))
            : Text(label, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // 5. Tranzaksiya qo'shish modali
  static void showAddTransactionModal(BuildContext context, KassaController controller, String lang) {
    final formKey = GlobalKey<FormState>();
    final f = NumberFormat("#,###", "uz_UZ");
    String selectedType = 'cash';
    String selectedReason = 'xarajat';
    final amountC = TextEditingController();
    final descC = TextEditingController();

    double getMaxLimit() {
      final b = controller.kassaData['balance'] ?? {"cash": 0, "card": 0, "bank": 0};
      return double.tryParse(b[selectedType].toString()) ?? 0.0;
    }

    showModalBottomSheet(
        context: context, isScrollControlled: true, backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
        builder: (context) => StatefulBuilder(builder: (context, setModalState) => Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: SingleChildScrollView(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), child: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 16), Text(lang == 'uz' ? "Yangi tranzaksiya" : "Новая транзакция", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _fieldLabel(lang == 'uz' ? "Hisob turi" : "Тип счета"),
              Row(children: [
                _choiceChip("cash", lang == 'uz' ? "Naqd" : "Нал.", selectedType, (v) => setModalState(() => selectedType = v)),
                const SizedBox(width: 8), _choiceChip("card", lang == 'uz' ? "Plastik" : "Карта", selectedType, (v) => setModalState(() => selectedType = v)),
                const SizedBox(width: 8), _choiceChip("bank", lang == 'uz' ? "Bank" : "Банк", selectedType, (v) => setModalState(() => selectedType = v))
              ]),
              const SizedBox(height: 16),
              _fieldLabel(lang == 'uz' ? "Amal turi" : "Тип операции"),
              Row(children: [
                _choiceChip("xarajat", lang == 'uz' ? "Xarajat" : "Расход", selectedReason, (v) => setModalState(() => selectedReason = v)),
                const SizedBox(width: 8), _choiceChip("kirim", lang == 'uz' ? "Kirim" : "Приход", selectedReason, (v) => setModalState(() => selectedReason = v))
              ]),
              const SizedBox(height: 16),
              _fieldLabel("${lang == 'uz' ? 'Summa' : 'Сумма'} (Max: ${f.format(getMaxLimit())})"),
              TextFormField(
                  controller: amountC, keyboardType: TextInputType.number,
                  decoration: const InputDecoration(prefixText: "UZS ", border: OutlineInputBorder(), contentPadding: EdgeInsets.all(12)),
                  validator: (v) => (v == null || v.isEmpty || (double.tryParse(v) ?? 0) > getMaxLimit()) ? "!" : null
              ),
              const SizedBox(height: 16),
              _fieldLabel(lang == 'uz' ? "Izoh" : "Описание"),
              TextFormField(
                  controller: descC, maxLines: 2,
                  decoration: InputDecoration(hintText: lang == 'uz' ? "Sababini yozing..." : "Опишите причину...", border: const OutlineInputBorder(), contentPadding: const EdgeInsets.all(12)),
                  validator: (v) => v!.isEmpty ? "!" : null
              ),
              const SizedBox(height: 24),
              Obx(() => controller.isSaving.value ? const Center(child: SpinKitThreeBounce(color: Colors.blue, size: 30))
                  : ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, minimumSize: const Size(double.infinity, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: () { if (formKey.currentState!.validate()) controller.addPendingTransaction({"type": selectedType, "reason": selectedReason, "amount": int.parse(amountC.text), "description": descC.text}); },
                  child: Text(lang == 'uz' ? "SAQLASH" : "СОХРАНИТЬ", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.1))
              )
              ),
              const SizedBox(height: 10),
            ]))))),
        )
    );
  }

  static Widget _fieldLabel(String t) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B))));
  static Widget _choiceChip(String v, String l, String g, Function(String) s) => Expanded(child: InkWell(onTap: () => s(v), child: Container(padding: const EdgeInsets.symmetric(vertical: 11), decoration: BoxDecoration(color: v == g ? Colors.blue : Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: v == g ? Colors.blue : Colors.grey.shade300)), child: Text(l, textAlign: TextAlign.center, style: TextStyle(color: v == g ? Colors.white : Colors.black87, fontSize: 12, fontWeight: FontWeight.bold)))));
}