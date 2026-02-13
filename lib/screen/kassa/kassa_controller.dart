import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:smart_kids_app_end/screen/kassa/kassa_page.dart';
import 'package:smart_kids_app_end/screen/kassa/kassa_widgets.dart';

class KassaPage extends StatelessWidget {
  const KassaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(KassaController());
    final f = NumberFormat("#,###", "uz_UZ");
    final lang = controller.lang;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
            lang == 'uz' ? "Kassa hisobi" : "Учет кассы",
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            onPressed: () => KassaWidgets.showAddTransactionModal(context, controller, lang),
            icon: const Icon(Icons.add_circle_rounded, color: Colors.blue, size: 28),
          )
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.kassaData.isEmpty) {
          return const Center(child: SpinKitPulse(color: Colors.blue, size: 50));
        }

        final data = controller.kassaData;
        final balance = data['balance'] ?? {"cash": 0, "card": 0, "bank": 0};
        final out = data['out'] ?? {"total": {"cash": 0, "card": 0, "bank": 0}, "items": {}};
        final cost = data['cost'] ?? {"total": {"cash": 0, "card": 0, "bank": 0}, "items": {}};

        return RefreshIndicator(
          onRefresh: () => controller.fetchKassa(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              KassaWidgets.sectionTitle(lang == 'uz' ? "Mavjud qoldiqlar" : "Текущие остатки"),
              const SizedBox(height: 12),
              Row(
                children: [
                  KassaWidgets.balanceCard("Naqd", "Наличные", balance['cash'], Colors.green, Icons.payments_outlined, f, lang),
                  const SizedBox(width: 8),
                  KassaWidgets.balanceCard("Plastik", "Карта", balance['card'], Colors.blue, Icons.credit_card_outlined, f, lang),
                  const SizedBox(width: 8),
                  KassaWidgets.balanceCard("Bank", "Банк", balance['bank'], Colors.orange, Icons.account_balance_outlined, f, lang),
                ],
              ),
              const SizedBox(height: 24),
              KassaWidgets.totalInfoCard(lang, out['total'], Colors.redAccent, f, lang == 'uz' ? "Kutilayotgan chiqimlar" : "Ожидаемые выплаты", () => KassaWidgets.showDetailsModal(context, controller, 'out', lang == 'uz' ? "Chiqimlar ro'yxati" : "Список выплат")),
              const SizedBox(height: 20),
              KassaWidgets.totalInfoCard(lang, cost['total'], Colors.purple, f, lang == 'uz' ? "Kutilayotgan xarajatlar" : "Ожидаемые расходы", () => KassaWidgets.showDetailsModal(context, controller, 'cost', lang == 'uz' ? "Xarajatlar ro'yxati" : "Список расходов")),
              const SizedBox(height: 50),
            ],
          ),
        );
      }),
    );
  }
}