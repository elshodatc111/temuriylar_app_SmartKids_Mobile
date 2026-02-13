import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:smart_kids_app_end/screen/group/group_show_controller.dart';
import 'package:smart_kids_app_end/screen/my_groups/my_group_davomad_history_page.dart';

class GroupShowPage extends StatelessWidget {
  final int id;

  const GroupShowPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(GroupShowController(id: id));
    final currencyFormat = NumberFormat("#,###", "uz_UZ");
    final lang = controller.lang;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(
          lang == 'uz' ? "Guruh tafsilotlari" : "Детали группы",
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.groupData.isEmpty) {
          return const Center(child: SpinKitPulse(color: Colors.blue, size: 50));
        }
        final d = controller.groupData;
        return RefreshIndicator(
          onRefresh: () => controller.fetchGroupDetails(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildHeaderCard(d, currencyFormat, lang),
                const SizedBox(height: 20),
                _actionMenu(controller, context, lang),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildHeaderCard(dynamic d, NumberFormat f, String lang) {
    double debit = double.tryParse(d['group_kids_debit']?.toString() ?? "0") ?? 0;
    double amount = double.tryParse(d['amount']?.toString() ?? "0") ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(15)),
              child: const Icon(Icons.hub_rounded, color: Colors.blue),
            ),
            title: Text(d['group_name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            subtitle: Text(d['description'] ?? '', style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ),
          const Divider(height: 24),
          _infoRow(Icons.payments_outlined, lang == 'uz' ? "Guruh narxi" : "Стоимость группы", "${f.format(amount)} UZS", Colors.green),
          _infoRow(Icons.account_balance_wallet_outlined, lang == 'uz' ? "Umumiy qarzdorlik" : "Общая задолженность", "${f.format(debit)} UZS", Colors.red),
          _infoRow(Icons.child_care_rounded, lang == 'uz' ? "Bolalar soni" : "Количество детей", "${d['group_kids_count'] ?? 0}", Colors.blue),
        ],
      ),
    );
  }

  Widget _infoRow(IconData i, String l, String v, Color c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(i, size: 20, color: c),
          const SizedBox(width: 10),
          Text(l, style: const TextStyle(color: Color(0xFF64748B), fontSize: 14)),
          const Spacer(),
          Text(v, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }

  Widget _actionMenu(GroupShowController controller, BuildContext context, String lang) {
    return Column(
      children: [
        _menuBtn(Icons.edit_note_rounded, lang == 'uz' ? "Guruhni tahrirlash" : "Редактировать группу", Colors.blue, () => _showEditModal(context, controller, lang)),
        _menuBtn(Icons.child_friendly_rounded, lang == 'uz' ? "Bolalar tarixi" : "История детей", Colors.indigo, () {
          controller.fetchGroupKids();
          _showHistoryModal(context, controller, true, lang);
        }),
        _menuBtn(Icons.assignment_ind_rounded, lang == 'uz' ? "Tarbiyachilar tarixi" : "История воспитателей", Colors.teal, () {
          controller.fetchGroupUsers();
          _showHistoryModal(context, controller, false, lang);
        }),
        _menuBtn(Icons.assignment_turned_in_rounded, lang == 'uz' ? "Guruh davomadi" : "Посещаемость группы", Colors.orange, () {
          Get.to(() => MyGroupDavomadHistoryPage(id: id,));
        }),
      ],
    );
  }

  Widget _menuBtn(IconData i, String t, Color c, VoidCallback onTap) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade100)),
      child: ListTile(
        onTap: onTap,
        leading: Icon(i, color: c),
        title: Text(t, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
      ),
    );
  }

  // --- TARIX MODALI ---
  void _showHistoryModal(BuildContext context, GroupShowController controller, bool isKids, String lang) {
    final f = NumberFormat("#,###", "uz_UZ");
    Get.bottomSheet(
      isScrollControlled: true,
      Container(
        height: Get.height * 0.75,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isKids ? (lang == 'uz' ? "Bolalar tarixi" : "История детей") : (lang == 'uz' ? "Tarbiyachilar tarixi" : "История воспитателей"),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () {
                      if (isKids) {
                        controller.fetchNoactiveKids();
                        _showAddModal(context, controller, true, lang);
                      } else {
                        controller.fetchAvailableTeachers();
                        _showAddModal(context, controller, false, lang);
                      }
                    },
                    icon: const Icon(Icons.add_circle, color: Colors.blue, size: 30),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                final list = isKids ? controller.groupKids : controller.groupUsers;

                if (isKids ? controller.isKidsLoading.value : controller.isUsersLoading.value) {
                  return const Center(child: SpinKitThreeBounce(color: Colors.blue, size: 30));
                }

                // Agar ro'yxat bo'sh bo'lsa xabar chiqarish
                if (list.isEmpty) {
                  return _buildEmptyState(
                      lang == 'uz' ? "Foydalanuvchilar topilmadi" : "Пользователи не найдены",
                      isKids ? Icons.child_care_outlined : Icons.person_off_outlined
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final item = list[index];
                    final bool isActive = item['status'] == 'active';
                    final int id = item['id'];

                    final String name = isKids ? (item['kid']?['name'] ?? '-') : (item['user']?['name'] ?? '-');
                    final double balance = double.tryParse(isKids ? (item['kid']?['balance']?.toString() ?? "0") : "0") ?? 0;
                    final String qoshganAdmin = item['add_admin'] is Map ? (item['add_admin']['name'] ?? '-') : (item['add_admin']?.toString() ?? '-');
                    final String ochirganAdmin = item['delete_admin'] != null && item['delete_admin'] is Map
                        ? (item['delete_admin']['name'] ?? '-')
                        : (lang == 'uz' ? "Noma'lum" : "Неизвестно");

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: isActive ? Colors.green.shade50 : Colors.red.shade50,
                                  child: Icon(isKids ? Icons.person : Icons.school, color: isActive ? Colors.green : Colors.red, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                      if (isKids) Text("${f.format(balance)} UZS", style: TextStyle(fontSize: 12, color: balance < 0 ? Colors.red : Colors.green, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                                if (isActive)
                                  Obx(() => controller.deletingIds.contains(id)
                                      ? const SpinKitRing(color: Colors.red, size: 20, lineWidth: 2)
                                      : IconButton(
                                      onPressed: () => _confirmAction(context, controller, id, isKids, name, lang),
                                      icon: const Icon(Icons.logout, color: Colors.red, size: 20))),
                              ],
                            ),
                            const Divider(height: 20),
                            _hDetail(
                                Icons.login,
                                (lang == 'uz' ? "Qo'shildi: " : "Добавлен: ") + (item['add_data'] ?? '-') + " ($qoshganAdmin)",
                                Colors.green
                            ),
                            if (!isActive)
                              _hDetail(
                                  Icons.logout,
                                  (lang == 'uz' ? "O'chirildi: " : "Удален: ") + (item['delete_data'] ?? '-') + " ($ochirganAdmin)",
                                  Colors.red
                              ),
                          ],
                        ),
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

  // --- QO'SHISH MODALI ---
  void _showAddModal(BuildContext context, GroupShowController controller, bool isKids, String lang) {
    Get.bottomSheet(
      isScrollControlled: true,
      Container(
        height: Get.height * 0.65,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                isKids ? (lang == 'uz' ? "Bola qo'shish" : "Добавить ребенка") : (lang == 'uz' ? "Tarbiyachi qo'shish" : "Добавить воспитателя"),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Obx(() {
                final list = isKids ? controller.filteredNoactiveKids : controller.filteredTeachers;

                if (isKids ? controller.isNoactiveLoading.value : controller.isTeachersLoading.value) {
                  return const Center(child: SpinKitThreeBounce(color: Colors.blue, size: 30));
                }

                if (list.isEmpty) {
                  return _buildEmptyState(
                      lang == 'uz' ? "Topilmadi" : "Не найдено",
                      Icons.search_off_outlined
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final item = list[index];
                    final int itemId = item['id'];
                    final String title = isKids ? (item['full_name'] ?? '-') : (item['name'] ?? '-');

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
                        trailing: Obx(() {
                          bool isAdding = isKids ? controller.addingKidIds.contains(itemId) : controller.addingTeacherIds.contains(itemId);
                          return isAdding
                              ? const SpinKitRing(color: Colors.green, size: 24, lineWidth: 2)
                              : IconButton(
                              icon: const Icon(Icons.add_circle, color: Colors.green, size: 28),
                              onPressed: () => isKids ? controller.addKidToGroup(itemId) : controller.addTeacherToGroup(itemId));
                        }),
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

  // --- BO'SH HOLAT UCHUN WIDGET (EMPTY STATE) ---
  Widget _buildEmptyState(String text, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          Text(text, style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // --- YORDAMCHILAR ---
  void _confirmAction(BuildContext context, GroupShowController controller, int id, bool isKid, String name, String lang) {
    Get.defaultDialog(
      title: lang == 'uz' ? "Tasdiqlash" : "Подтверждение",
      middleText: name + (lang == 'uz' ? " guruhdan o'chirilsinmi?" : " будет удален из группы?"),
      textConfirm: lang == 'uz' ? "O'CHIRISH" : "УДАЛИТЬ",
      textCancel: lang == 'uz' ? "BEKOR QILISH" : "ОТМЕНА",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      cancelTextColor: Colors.black87,
      onConfirm: () {
        Get.back();
        controller.removeFromGroup(id, isKid);
      },
    );
  }

  void _showEditModal(BuildContext context, GroupShowController controller, String lang) {
    final nameC = TextEditingController(text: controller.groupData['group_name']);
    final descC = TextEditingController(text: controller.groupData['description']);
    final amountC = TextEditingController(text: controller.groupData['amount'].toString());
    Get.bottomSheet(
      isScrollControlled: true,
      Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(lang == 'uz' ? "Guruhni tahrirlash" : "Редактировать группу", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _field(nameC, lang == 'uz' ? "Nomi" : "Название", Icons.edit),
            _field(descC, lang == 'uz' ? "Tavsif" : "Описание", Icons.description, lines: 2),
            _field(amountC, lang == 'uz' ? "Narxi" : "Цена", Icons.payments, type: TextInputType.number),
            const SizedBox(height: 20),
            Obx(() => controller.isUpdating.value
                ? const SpinKitThreeBounce(color: Colors.blue, size: 30)
                : ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () => controller.updateGroup(nameC.text, descC.text, amountC.text),
                child: Text(lang == 'uz' ? "SAQLASH" : "СОХРАНИТЬ", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String l, IconData i, {TextInputType type = TextInputType.text, int lines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: type,
        maxLines: lines,
        decoration: InputDecoration(
          labelText: l,
          prefixIcon: Icon(i, size: 20, color: Colors.blue),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _hDetail(IconData i, String t, Color c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(i, size: 16, color: c),
          const SizedBox(width: 8),
          Expanded(child: Text(t, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
        ],
      ),
    );
  }
}